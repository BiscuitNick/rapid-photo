/**
 * K6 Load Test - Upload Flow
 * Tests the complete upload flow: initiate -> presigned PUT -> confirm
 *
 * Usage:
 *   k6 run --vus 100 --duration 90s upload-flow.js
 *   k6 run --vus 100 --iterations 100 upload-flow.js
 *
 * Environment Variables:
 *   - API_BASE_URL: Backend API endpoint (default: http://localhost:8080)
 *   - AUTH_TOKEN: JWT token for authentication (required)
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Custom metrics
const uploadInitiateSuccess = new Rate('upload_initiate_success');
const uploadConfirmSuccess = new Rate('upload_confirm_success');
const s3UploadSuccess = new Rate('s3_upload_success');
const endToEndDuration = new Trend('end_to_end_duration');
const uploadErrors = new Counter('upload_errors');

// Configuration
const API_BASE_URL = __ENV.API_BASE_URL || 'http://localhost:8080';
const AUTH_TOKEN = __ENV.AUTH_TOKEN || '';

// Test thresholds - aligned with PRD requirements
export const options = {
  thresholds: {
    'http_req_duration': ['p(95)<2000', 'p(99)<5000'], // 95% under 2s, 99% under 5s
    'http_req_failed': ['rate<0.01'], // Less than 1% failures
    'upload_initiate_success': ['rate>0.99'], // 99% success rate
    'upload_confirm_success': ['rate>0.99'],
    's3_upload_success': ['rate>0.99'],
    'end_to_end_duration': ['p(95)<90000'], // 95% complete under 90s (PRD requirement)
  },
  stages: [
    { duration: '10s', target: 20 },  // Ramp up
    { duration: '30s', target: 100 }, // Ramp to 100 concurrent
    { duration: '40s', target: 100 }, // Stay at 100
    { duration: '10s', target: 0 },   // Ramp down
  ],
};

/**
 * Generate a mock image file (1MB JPEG)
 */
function generateMockImage() {
  const size = 1024 * 1024; // 1 MB
  const buffer = new Uint8Array(size);

  // Fill with random data
  for (let i = 0; i < size; i++) {
    buffer[i] = Math.floor(Math.random() * 256);
  }

  return buffer;
}

/**
 * Main test scenario
 */
export default function () {
  const startTime = Date.now();

  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${AUTH_TOKEN}`,
  };

  group('Upload Flow', () => {
    // Step 1: Initiate upload and get presigned URL
    const initiatePayload = JSON.stringify({
      fileName: `test-image-${randomString(8)}.jpg`,
      fileSize: 1024 * 1024, // 1 MB
      mimeType: 'image/jpeg',
      metadata: {
        source: 'k6-load-test',
      },
    });

    const initiateResponse = http.post(
      `${API_BASE_URL}/api/v1/uploads/initiate`,
      initiatePayload,
      { headers }
    );

    const initiateOk = check(initiateResponse, {
      'initiate status is 200': (r) => r.status === 200,
      'initiate has uploadId': (r) => r.json('uploadId') !== undefined,
      'initiate has presignedUrl': (r) => r.json('presignedUrl') !== undefined,
      'initiate has s3Key': (r) => r.json('s3Key') !== undefined,
    });

    uploadInitiateSuccess.add(initiateOk);

    if (!initiateOk) {
      uploadErrors.add(1);
      console.error(`Initiate failed: ${initiateResponse.status} - ${initiateResponse.body}`);
      return;
    }

    const { uploadId, presignedUrl, s3Key } = initiateResponse.json();

    // Step 2: Upload to S3 using presigned URL
    const imageData = generateMockImage();

    const s3Response = http.put(presignedUrl, imageData, {
      headers: {
        'Content-Type': 'image/jpeg',
      },
    });

    const s3Ok = check(s3Response, {
      's3 upload status is 200': (r) => r.status === 200,
      's3 upload has ETag': (r) => r.headers['Etag'] !== undefined,
    });

    s3UploadSuccess.add(s3Ok);

    if (!s3Ok) {
      uploadErrors.add(1);
      console.error(`S3 upload failed: ${s3Response.status}`);
      return;
    }

    const etag = s3Response.headers['Etag'].replace(/"/g, '');

    // Step 3: Confirm upload completion
    const confirmPayload = JSON.stringify({
      uploadId,
      etag,
      s3Key,
    });

    const confirmResponse = http.post(
      `${API_BASE_URL}/api/v1/uploads/${uploadId}/confirm`,
      confirmPayload,
      { headers }
    );

    const confirmOk = check(confirmResponse, {
      'confirm status is 200': (r) => r.status === 200,
      'confirm has photoId': (r) => r.json('photoId') !== undefined,
      'confirm status is PENDING_PROCESSING': (r) => r.json('status') === 'PENDING_PROCESSING',
    });

    uploadConfirmSuccess.add(confirmOk);

    if (!confirmOk) {
      uploadErrors.add(1);
      console.error(`Confirm failed: ${confirmResponse.status} - ${confirmResponse.body}`);
      return;
    }

    // Record end-to-end duration
    const duration = Date.now() - startTime;
    endToEndDuration.add(duration);

    // Step 4: Check batch status
    const statusResponse = http.get(
      `${API_BASE_URL}/api/v1/uploads/batch/status`,
      { headers }
    );

    check(statusResponse, {
      'batch status is 200': (r) => r.status === 200,
      'batch status has uploads': (r) => {
        const body = r.json();
        return Array.isArray(body) && body.length > 0;
      },
    });
  });

  // Think time between iterations
  sleep(Math.random() * 2);
}

/**
 * Teardown function - print summary
 */
export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'load-test-results.json': JSON.stringify(data, null, 2),
  };
}

function textSummary(data, options) {
  const indent = options.indent || '';
  const enableColors = options.enableColors || false;

  let summary = '\n' + indent + '=== Upload Flow Load Test Summary ===\n\n';

  // Test configuration
  summary += indent + 'Configuration:\n';
  summary += indent + `  VUs: ${data.metrics.vus.values.max}\n`;
  summary += indent + `  Duration: ${data.state.testRunDurationMs / 1000}s\n`;
  summary += indent + `  Iterations: ${data.metrics.iterations.values.count}\n\n`;

  // Success rates
  summary += indent + 'Success Rates:\n';
  summary += indent + `  Initiate: ${(data.metrics.upload_initiate_success.values.rate * 100).toFixed(2)}%\n`;
  summary += indent + `  S3 Upload: ${(data.metrics.s3_upload_success.values.rate * 100).toFixed(2)}%\n`;
  summary += indent + `  Confirm: ${(data.metrics.upload_confirm_success.values.rate * 100).toFixed(2)}%\n\n`;

  // Performance metrics
  summary += indent + 'Performance:\n';
  summary += indent + `  End-to-End p50: ${data.metrics.end_to_end_duration.values.p50.toFixed(2)}ms\n`;
  summary += indent + `  End-to-End p95: ${data.metrics.end_to_end_duration.values.p95.toFixed(2)}ms\n`;
  summary += indent + `  End-to-End p99: ${data.metrics.end_to_end_duration.values.p99.toFixed(2)}ms\n`;
  summary += indent + `  HTTP p95: ${data.metrics.http_req_duration.values.p95.toFixed(2)}ms\n`;
  summary += indent + `  HTTP p99: ${data.metrics.http_req_duration.values.p99.toFixed(2)}ms\n\n`;

  // Errors
  summary += indent + 'Errors:\n';
  summary += indent + `  Total Errors: ${data.metrics.upload_errors.values.count}\n`;
  summary += indent + `  HTTP Failures: ${(data.metrics.http_req_failed.values.rate * 100).toFixed(2)}%\n\n`;

  // Threshold results
  summary += indent + 'Thresholds:\n';
  Object.entries(data.metrics).forEach(([name, metric]) => {
    if (metric.thresholds) {
      Object.entries(metric.thresholds).forEach(([threshold, result]) => {
        const status = result.ok ? '✓' : '✗';
        summary += indent + `  ${status} ${name}: ${threshold}\n`;
      });
    }
  });

  return summary;
}

# Load Tests - RapidPhotoUpload

This directory contains k6 load test scripts for validating system performance under load.

## Prerequisites

Install k6:
```bash
# macOS
brew install k6

# Linux
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Windows
choco install k6
```

## Available Tests

### upload-flow.js

Tests the complete photo upload flow including:
1. Initiate upload (get presigned URL)
2. Upload to S3
3. Confirm upload
4. Check batch status

**Usage:**
```bash
# Set environment variables
export API_BASE_URL="http://your-alb-endpoint.us-east-1.elb.amazonaws.com"
export AUTH_TOKEN="your-jwt-token"

# Run with 100 concurrent users for 90 seconds (PRD requirement)
k6 run --vus 100 --duration 90s upload-flow.js

# Run with specific number of iterations
k6 run --vus 100 --iterations 100 upload-flow.js

# Run with custom thresholds
k6 run --vus 100 --duration 90s \
  --threshold 'http_req_duration{p(95)}<2000' \
  --threshold 'end_to_end_duration{p(95)}<90000' \
  upload-flow.js
```

## Test Scenarios

### Baseline Load Test
Validates system can handle normal traffic patterns.
```bash
k6 run --vus 20 --duration 60s upload-flow.js
```

### Peak Load Test (PRD Requirement)
100 concurrent uploads completing within 90 seconds.
```bash
k6 run --vus 100 --duration 90s upload-flow.js
```

### Stress Test
Push system beyond normal capacity to find breaking points.
```bash
k6 run --vus 200 --duration 120s upload-flow.js
```

### Soak Test
Validate system stability over extended periods.
```bash
k6 run --vus 50 --duration 3600s upload-flow.js
```

## Performance Thresholds (PRD Requirements)

- **End-to-End Latency:** p95 < 90s for 100 concurrent uploads
- **API Response Time:** p95 < 2s, p99 < 5s
- **Error Rate:** < 1%
- **Success Rate:** > 99%

## CI/CD Integration

The load tests can be integrated into GitHub Actions:

```yaml
- name: Run Load Tests
  run: |
    export API_BASE_URL="${{ secrets.DEV_API_URL }}"
    export AUTH_TOKEN="${{ secrets.DEV_AUTH_TOKEN }}"
    k6 run --vus 100 --duration 90s tests/load/upload-flow.js
```

## Interpreting Results

### Key Metrics

- **http_req_duration:** Time for HTTP requests to complete
- **end_to_end_duration:** Full upload flow duration (initiate → S3 → confirm)
- **upload_initiate_success:** Success rate for initiate endpoint
- **s3_upload_success:** Success rate for S3 uploads
- **upload_confirm_success:** Success rate for confirm endpoint
- **upload_errors:** Total number of errors encountered

### Success Criteria

✅ **Pass:** All thresholds met
- p95 end-to-end < 90s
- p95 API response < 2s
- Error rate < 1%

❌ **Fail:** Any threshold violated
- Investigate bottlenecks in CloudWatch
- Check X-Ray traces for slow operations
- Review ECS/Lambda scaling behavior

## Troubleshooting

### High Latency
- Check ECS task CPU/memory utilization
- Review RDS Performance Insights
- Check S3 request patterns
- Verify Lambda concurrent executions

### High Error Rate
- Check CloudWatch Logs for exceptions
- Verify database connection pool settings
- Check SQS queue depth and DLQ
- Review API Gateway/ALB logs

### S3 Upload Failures
- Verify presigned URL expiration time
- Check S3 bucket CORS configuration
- Verify IAM permissions
- Check network connectivity

## Additional Resources

- [k6 Documentation](https://k6.io/docs/)
- [Deployment Guide](../../docs/deployment.md)
- [CloudWatch Dashboard](https://console.aws.amazon.com/cloudwatch/)

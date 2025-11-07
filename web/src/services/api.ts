/**
 * API service layer for backend communication
 */

import axios, { AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import { useAuthStore } from '../stores/authStore';
import type {
  GeneratePresignedUrlRequest,
  GeneratePresignedUrlResponse,
  ConfirmUploadRequest,
  ConfirmUploadResponse,
  BatchUploadStatusResponse,
} from '../types/api';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';

class ApiService {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor to add auth token
    this.client.interceptors.request.use(
      async (config: InternalAxiosRequestConfig) => {
        const token = useAuthStore.getState().accessToken;
        if (token && config.headers) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor for token refresh
    this.client.interceptors.response.use(
      (response) => response,
      async (error) => {
        const originalRequest = error.config;

        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true;

          try {
            await useAuthStore.getState().refreshTokens();
            const token = useAuthStore.getState().accessToken;
            if (token) {
              originalRequest.headers.Authorization = `Bearer ${token}`;
            }
            return this.client(originalRequest);
          } catch (refreshError) {
            return Promise.reject(refreshError);
          }
        }

        return Promise.reject(error);
      }
    );
  }

  /**
   * Initiate upload and get presigned URL
   */
  async initiateUpload(
    request: GeneratePresignedUrlRequest
  ): Promise<GeneratePresignedUrlResponse> {
    const response = await this.client.post<GeneratePresignedUrlResponse>(
      '/api/v1/uploads/initiate',
      request
    );
    return response.data;
  }

  /**
   * Confirm upload completion
   */
  async confirmUpload(
    uploadId: string,
    request: ConfirmUploadRequest
  ): Promise<ConfirmUploadResponse> {
    const response = await this.client.post<ConfirmUploadResponse>(
      `/api/v1/uploads/${uploadId}/confirm`,
      request
    );
    return response.data;
  }

  /**
   * Get batch upload status
   */
  async getBatchStatus(): Promise<BatchUploadStatusResponse> {
    const response = await this.client.get<BatchUploadStatusResponse>(
      '/api/v1/uploads/batch/status'
    );
    return response.data;
  }

  /**
   * Upload file to S3 using presigned URL
   */
  async uploadToS3(
    presignedUrl: string,
    file: File,
    onProgress?: (progressEvent: { loaded: number; total: number }) => void
  ): Promise<string> {
    const response = await axios.put(presignedUrl, file, {
      headers: {
        'Content-Type': file.type,
      },
      onUploadProgress: (progressEvent) => {
        if (onProgress && progressEvent.total) {
          onProgress({
            loaded: progressEvent.loaded,
            total: progressEvent.total,
          });
        }
      },
    });

    // Extract ETag from response headers
    const etag = response.headers['etag'];
    if (!etag) {
      throw new Error('No ETag returned from S3 upload');
    }

    // Remove quotes from ETag if present
    return etag.replace(/"/g, '');
  }
}

export const apiService = new ApiService();

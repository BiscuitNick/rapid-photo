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
  Photo,
  PhotoDetail,
  PagedResponse,
  GetPhotosParams,
  SearchPhotosParams,
  DownloadUrlResponse,
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
        const { idToken, accessToken } = useAuthStore.getState();
        const token = idToken ?? accessToken;
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
            const { idToken, accessToken } = useAuthStore.getState();
            const token = idToken ?? accessToken;
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

  private appendCacheBuster(params: URLSearchParams) {
    params.append('_', Date.now().toString());
  }

  private withCacheBuster(path: string): string {
    const separator = path.includes('?') ? '&' : '?';
    return `${path}${separator}_=${Date.now()}`;
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
      this.withCacheBuster('/api/v1/uploads/batch/status')
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

  /**
   * Get paginated photos
   */
  async getPhotos(params: GetPhotosParams = {}): Promise<PagedResponse<Photo>> {
    const queryParams = new URLSearchParams();
    if (params.page !== undefined) queryParams.append('page', params.page.toString());
    if (params.size !== undefined) queryParams.append('size', params.size.toString());
    if (params.sort) queryParams.append('sort', params.sort);
    this.appendCacheBuster(queryParams);

    const url = `/api/v1/photos?${queryParams.toString()}`;
    const response = await this.client.get<PagedResponse<Photo>>(url);

    console.log(`[API] Fetched ${response.data.content?.length || 0} photos (page ${params.page || 0})`);

    return response.data;
  }

  /**
   * Search photos by tags
   */
  async searchPhotos(params: SearchPhotosParams = {}): Promise<PagedResponse<Photo>> {
    const queryParams = new URLSearchParams();
    if (params.page !== undefined) queryParams.append('page', params.page.toString());
    if (params.size !== undefined) queryParams.append('size', params.size.toString());
    if (params.sort) queryParams.append('sort', params.sort);
    if (params.tags && params.tags.length > 0) {
      params.tags.forEach(tag => queryParams.append('tags', tag));
    }
    this.appendCacheBuster(queryParams);

    const response = await this.client.get<PagedResponse<Photo>>(
      `/api/v1/photos/search?${queryParams.toString()}`
    );
    return response.data;
  }

  /**
   * Get single photo by ID with full details
   */
  async getPhoto(photoId: string): Promise<PhotoDetail> {
    const response = await this.client.get<PhotoDetail>(
      this.withCacheBuster(`/api/v1/photos/${photoId}`)
    );
    return response.data;
  }

  /**
   * Delete photo by ID
   */
  async deletePhoto(photoId: string): Promise<void> {
    await this.client.delete(`/api/v1/photos/${photoId}`);
  }

  /**
   * Get download URL for original photo
   */
  async getDownloadUrl(photoId: string, version: string = 'original'): Promise<DownloadUrlResponse> {
    const response = await this.client.get<DownloadUrlResponse>(
      this.withCacheBuster(`/api/v1/photos/${photoId}/download/${version}`)
    );
    return response.data;
  }
}

export const apiService = new ApiService();

/**
 * API types matching backend DTOs
 */

export interface GeneratePresignedUrlRequest {
  fileName: string;
  fileSize: number;
  mimeType: string;
}

export interface GeneratePresignedUrlResponse {
  uploadId: string;
  presignedUrl: string;
  s3Key: string;
  expiresAt: string;
  fileName: string;
  fileSize: number;
  mimeType: string;
}

export interface ConfirmUploadRequest {
  etag: string;
}

export interface ConfirmUploadResponse {
  photoId: string;
  uploadId: string;
  status: string;
  message: string;
}

export interface BatchUploadStatusResponse {
  statuses: UploadStatus[];
}

export interface UploadStatus {
  uploadId: string;
  fileName: string;
  status: string;
  photoId?: string;
}

/**
 * Upload queue item status
 */
export type UploadItemStatus =
  | 'queued'
  | 'uploading'
  | 'confirming'
  | 'processing'
  | 'complete'
  | 'failed'
  | 'paused';

/**
 * Single upload item in the queue
 */
export interface UploadItem {
  id: string;
  file: File;
  status: UploadItemStatus;
  progress: number;
  uploadId?: string;
  presignedUrl?: string;
  s3Key?: string;
  etag?: string;
  photoId?: string;
  error?: string;
  retryCount: number;
}

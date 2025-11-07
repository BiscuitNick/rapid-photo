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

/**
 * Gallery and photo types
 */

export interface PhotoVersion {
  type: string; // 'THUMBNAIL', 'WEBP_800', 'WEBP_1200', 'WEBP_1920'
  url: string;
  width?: number;
  height?: number;
}

export interface PhotoMetadata {
  width?: number;
  height?: number;
  format?: string;
  size?: number;
  takenAt?: string;
  location?: string;
  cameraModel?: string;
  exposureTime?: string;
  fNumber?: string;
  iso?: number;
}

export interface Photo {
  id: string;
  userId: string;
  fileName: string;
  originalUrl: string;
  thumbnailUrl?: string;
  versions: PhotoVersion[];
  tags: string[];
  metadata: PhotoMetadata;
  status: string; // 'PENDING_PROCESSING', 'PROCESSING', 'READY', 'FAILED'
  createdAt: string;
  updatedAt: string;
}

export interface PageInfo {
  pageNumber: number;
  pageSize: number;
  totalElements: number;
  totalPages: number;
  isFirst: boolean;
  isLast: boolean;
  hasNext: boolean;
  hasPrevious: boolean;
}

export interface PagedResponse<T> {
  content: T[];
  page: PageInfo;
}

export interface GetPhotosParams {
  page?: number;
  size?: number;
  sort?: string; // e.g., 'createdAt,desc'
}

export interface SearchPhotosParams extends GetPhotosParams {
  tags?: string[];
}

export interface DownloadUrlResponse {
  url: string;
  expiresAt: string;
}

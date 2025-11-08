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

export type PhotoStatus = 'PENDING_PROCESSING' | 'PROCESSING' | 'READY' | 'FAILED';

export type PhotoVersionType =
  | 'THUMBNAIL'
  | 'WEBP_640'
  | 'WEBP_1280'
  | 'WEBP_1920'
  | 'WEBP_2560';

export interface PhotoVersion {
  versionType: PhotoVersionType;
  url: string;
  width?: number;
  height?: number;
  fileSize?: number;
  mimeType?: string;
}

export interface PhotoLabel {
  labelName: string;
  confidence: number;
  confidenceLevel: string;
}

/**
 * Lightweight photo item for gallery list view
 * Matches backend PhotoListItemDto
 */
export interface Photo {
  id: string;
  fileName: string;
  status: PhotoStatus;
  thumbnailUrl: string | null;
  originalUrl: string | null;
  width: number | null;
  height: number | null;
  labels: string[];
  createdAt: string;
  takenAt: string | null;
}

/**
 * Detailed photo with all metadata and versions
 * Matches backend PhotoResponse
 */
export interface PhotoDetail {
  id: string;
  fileName: string;
  status: PhotoStatus;
  fileSize: number;
  mimeType: string;
  width: number | null;
  height: number | null;
  originalUrl: string;
  thumbnailUrl: string | null;
  versions: PhotoVersion[];
  labels: PhotoLabel[];
  createdAt: string;
  processedAt: string | null;
  takenAt: string | null;
  cameraMake: string | null;
  cameraModel: string | null;
  gpsLatitude: number | null;
  gpsLongitude: number | null;
}

/**
 * Pagination response structure
 * Matches backend PagedPhotosResponse
 */
export interface PagedResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  hasNext: boolean;
  hasPrevious: boolean;
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
  downloadUrl: string;
  expiresAt: string;
  fileName: string;
  fileSize: number;
}

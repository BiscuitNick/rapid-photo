/**
 * Upload queue hook with concurrency control and retry logic
 */

import { useCallback, useRef, useEffect } from 'react';
import { apiService } from '../services/api';
import { useInvalidatePhotos } from './usePhotos';
import { useAddPhotoToCache } from './usePhotoMutations';
import { useUploadStore } from '../stores/uploadStore';
import type { UploadItem, Photo } from '../types/api';

const MAX_CONCURRENT_UPLOADS = 10;
const MAX_RETRY_ATTEMPTS = 3;
const RETRY_DELAY_MS = 1000;

interface UseUploadQueueReturn {
  queue: UploadItem[];
  addFiles: (files: File[]) => void;
  removeFile: (id: string) => void;
  retryFile: (id: string) => void;
  retryAll: () => void;
  pauseAll: () => void;
  resumeAll: () => void;
  clearCompleted: () => void;
  clearAll: () => void;
  stats: {
    total: number;
    queued: number;
    uploading: number;
    complete: number;
    failed: number;
    paused: number;
  };
}

export const useUploadQueue = (): UseUploadQueueReturn => {
  // Use global store for queue persistence
  const { queue, updateItem: storeUpdateItem, addToQueue, removeItem: storeRemoveItem, setQueue, clearCompleted: storeClearCompleted, clearAll: storeClearAll } = useUploadStore();
  const activeUploadsRef = useRef(0);
  const processingRef = useRef(false);
  const queueRef = useRef<UploadItem[]>([]);
  const processingItemsRef = useRef<Set<string>>(new Set());
  const invalidatePhotos = useInvalidatePhotos();
  const addPhotoToCache = useAddPhotoToCache();
  const isPausedRef = useRef(false);

  // Keep queueRef in sync with queue state
  useEffect(() => {
    queueRef.current = queue;
  }, [queue]);

  // Update a single item in the queue
  const updateItem = useCallback(
    (id: string, updates: Partial<UploadItem>) => {
      storeUpdateItem(id, updates);
    },
    [storeUpdateItem]
  );

  // Upload a single file
  const uploadFile = useCallback(
    async (item: UploadItem): Promise<void> => {
      const file = item.file;
      if (!file) {
        throw new Error('File data is unavailable for this upload item');
      }

      try {
        // Step 1: Initiate upload and get presigned URL
        // Status is already set to 'uploading' in processQueue, just update progress
        updateItem(item.id, { progress: 0 });

        const initiateResponse = await apiService.initiateUpload({
          fileName: item.fileName,
          fileSize: item.fileSize,
          mimeType: item.mimeType,
        });

        updateItem(item.id, {
          uploadId: initiateResponse.uploadId,
          presignedUrl: initiateResponse.presignedUrl,
          s3Key: initiateResponse.s3Key,
        });

        // Step 2: Upload to S3 with progress tracking
        const etag = await apiService.uploadToS3(
          initiateResponse.presignedUrl,
          file,
          ({ loaded, total }) => {
            const progress = Math.round((loaded / total) * 100);
            updateItem(item.id, { progress });
          }
        );

        updateItem(item.id, { status: 'confirming', progress: 100, etag });

        // Step 3: Confirm upload with backend
        const confirmResponse = await apiService.confirmUpload(
          initiateResponse.uploadId,
          { etag }
        );

        updateItem(item.id, {
          status: 'complete',
          photoId: confirmResponse.photoId,
        });

        // Fetch the new photo data and add to cache for immediate visibility
        try {
          const photoDetail = await apiService.getPhoto(confirmResponse.photoId);
          // Convert PhotoDetail to Photo for cache
          const photo: Photo = {
            id: photoDetail.id,
            fileName: photoDetail.fileName,
            status: photoDetail.status,
            thumbnailUrl: photoDetail.thumbnailUrl,
            originalUrl: photoDetail.originalUrl,
            width: photoDetail.width,
            height: photoDetail.height,
            labels: photoDetail.labels.map(l => l.labelName),
            createdAt: photoDetail.createdAt,
            takenAt: photoDetail.takenAt,
          };
          addPhotoToCache(photo);
        } catch (error) {
          console.error('Failed to fetch new photo data:', error);
        }

        // Also invalidate to ensure consistency
        invalidatePhotos();
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : 'Upload failed';

        // Retry logic
        if (item.retryCount < MAX_RETRY_ATTEMPTS) {
          await new Promise((resolve) =>
            setTimeout(resolve, RETRY_DELAY_MS * (item.retryCount + 1))
          );

          updateItem(item.id, {
            retryCount: item.retryCount + 1,
            status: 'queued',
          });
        } else {
          updateItem(item.id, {
            status: 'failed',
            error: errorMessage,
          });
        }

        throw error;
      }
    },
    [updateItem, invalidatePhotos, addPhotoToCache]
  );

  // Process queue with concurrency control
  const processQueue = useCallback(async () => {
    console.log('[Upload] processQueue called, isPaused:', isPausedRef.current, 'processing:', processingRef.current);
    if (processingRef.current || isPausedRef.current) return;

    processingRef.current = true;

    while (true) {
      // Get current queue state from ref (always up to date)
      const currentQueue = queueRef.current;
      // Defense-in-depth: Only select items that are queued AND not already being processed
      const nextItem = currentQueue.find(
        (item) => item.status === 'queued' && !processingItemsRef.current.has(item.id)
      );

      console.log('[Upload] Current queue size:', currentQueue.length, 'Queued items:', currentQueue.filter(i => i.status === 'queued').length);

      // No more queued items
      if (!nextItem) {
        console.log('[Upload] No more queued items');
        break;
      }

      console.log('[Upload] Processing item:', nextItem.file?.name ?? nextItem.fileName);

      // Wait if at max concurrency
      if (activeUploadsRef.current >= MAX_CONCURRENT_UPLOADS) {
        await new Promise((resolve) => setTimeout(resolve, 100));
        continue;
      }

      // FIX: Immediately mark item as uploading to prevent re-processing
      // Update the ref synchronously to prevent race condition
      queueRef.current = queueRef.current.map((item) =>
        item.id === nextItem.id ? { ...item, status: 'uploading' as const } : item
      );

      // Defense-in-depth: Add to processing set
      processingItemsRef.current.add(nextItem.id);

      // Also update React state for UI consistency
      updateItem(nextItem.id, { status: 'uploading' });

      // Upload file
      activeUploadsRef.current++;

      uploadFile(nextItem)
        .catch((error) => {
          console.error(`Upload failed for ${nextItem.file?.name ?? nextItem.fileName}:`, error);
        })
        .finally(() => {
          // Clean up: remove from processing set and decrement counter
          processingItemsRef.current.delete(nextItem.id);
          activeUploadsRef.current--;
        });
    }

    processingRef.current = false;
  }, [uploadFile]);

  // Automatically process queue when items are added or status changes
  useEffect(() => {
    const hasQueuedItems = queue.some((item) => item.status === 'queued');
    if (hasQueuedItems && !processingRef.current && !isPausedRef.current) {
      console.log('[Upload] useEffect detected queued items, triggering processQueue');
      processQueue();
    }
  }, [queue, processQueue]);

  // Add files to queue
  const addFiles = useCallback(
    (files: File[]) => {
      console.log('[Upload] Adding files:', files.length);
      const newItems: UploadItem[] = files.map((file) => ({
        id: `${Date.now()}-${Math.random()}`,
        file,
        fileName: file.name,
        fileSize: file.size,
        mimeType: file.type,
        status: 'queued',
        progress: 0,
        retryCount: 0,
      }));

      addToQueue(newItems);
    },
    [addToQueue]
  );

  // Remove file from queue
  const removeFile = useCallback((id: string) => {
    storeRemoveItem(id);
  }, [storeRemoveItem]);

  // Retry a specific file
  const retryFile = useCallback(
    (id: string) => {
      storeUpdateItem(id, {
        status: 'queued',
        retryCount: 0,
        progress: 0,
      });
    },
    [storeUpdateItem]
  );

  // Retry all failed uploads
  const retryAll = useCallback(() => {
    const updatedQueue = queue.map((item) =>
      item.status === 'failed'
        ? {
            ...item,
            status: 'queued' as const,
            retryCount: 0,
            progress: 0,
          }
        : item
    );
    setQueue(updatedQueue);
  }, [queue, setQueue]);

  // Pause all uploads
  const pauseAll = useCallback(() => {
    isPausedRef.current = true;
    const updatedQueue = queue.map((item) =>
      item.status === 'queued' || item.status === 'uploading'
        ? { ...item, status: 'paused' as const }
        : item
    );
    setQueue(updatedQueue);
  }, [queue, setQueue]);

  // Resume all uploads
  const resumeAll = useCallback(() => {
    isPausedRef.current = false;
    const updatedQueue = queue.map((item) =>
      item.status === 'paused' ? { ...item, status: 'queued' as const } : item
    );
    setQueue(updatedQueue);
  }, [queue, setQueue]);

  // Clear completed uploads
  const clearCompleted = useCallback(() => {
    storeClearCompleted();
  }, [storeClearCompleted]);

  // Clear entire queue
  const clearAll = useCallback(() => {
    storeClearAll();
  }, [storeClearAll]);

  // Calculate stats
  const stats = {
    total: queue.length,
    queued: queue.filter((item) => item.status === 'queued').length,
    uploading: queue.filter((item) => item.status === 'uploading').length,
    complete: queue.filter((item) => item.status === 'complete').length,
    failed: queue.filter((item) => item.status === 'failed').length,
    paused: queue.filter((item) => item.status === 'paused').length,
  };

  return {
    queue,
    addFiles,
    removeFile,
    retryFile,
    retryAll,
    pauseAll,
    resumeAll,
    clearCompleted,
    clearAll,
    stats,
  };
};

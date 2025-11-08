/**
 * Upload queue hook with concurrency control and retry logic
 */

import { useState, useCallback, useRef, useEffect } from 'react';
import { apiService } from '../services/api';
import type { UploadItem } from '../types/api';

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
  const [queue, setQueue] = useState<UploadItem[]>([]);
  const [isPaused, setIsPaused] = useState(false);
  const activeUploadsRef = useRef(0);
  const processingRef = useRef(false);
  const queueRef = useRef<UploadItem[]>([]);

  // Keep queueRef in sync with queue state
  useEffect(() => {
    queueRef.current = queue;
  }, [queue]);

  // Update a single item in the queue
  const updateItem = useCallback(
    (id: string, updates: Partial<UploadItem>) => {
      setQueue((prev) =>
        prev.map((item) => (item.id === id ? { ...item, ...updates } : item))
      );
    },
    []
  );

  // Upload a single file
  const uploadFile = useCallback(
    async (item: UploadItem): Promise<void> => {
      try {
        // Step 1: Initiate upload and get presigned URL
        updateItem(item.id, { status: 'uploading', progress: 0 });

        const initiateResponse = await apiService.initiateUpload({
          fileName: item.file.name,
          fileSize: item.file.size,
          mimeType: item.file.type,
        });

        updateItem(item.id, {
          uploadId: initiateResponse.uploadId,
          presignedUrl: initiateResponse.presignedUrl,
          s3Key: initiateResponse.s3Key,
        });

        // Step 2: Upload to S3 with progress tracking
        const etag = await apiService.uploadToS3(
          initiateResponse.presignedUrl,
          item.file,
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
    [updateItem]
  );

  // Process queue with concurrency control
  const processQueue = useCallback(async () => {
    console.log('[Upload] processQueue called, isPaused:', isPaused, 'processing:', processingRef.current);
    if (processingRef.current || isPaused) return;

    processingRef.current = true;

    while (true) {
      // Get current queue state from ref (always up to date)
      const currentQueue = queueRef.current;
      const nextItem = currentQueue.find((item) => item.status === 'queued');

      console.log('[Upload] Current queue size:', currentQueue.length, 'Queued items:', currentQueue.filter(i => i.status === 'queued').length);

      // No more queued items
      if (!nextItem) {
        console.log('[Upload] No more queued items');
        break;
      }

      console.log('[Upload] Processing item:', nextItem.file.name);

      // Wait if at max concurrency
      if (activeUploadsRef.current >= MAX_CONCURRENT_UPLOADS) {
        await new Promise((resolve) => setTimeout(resolve, 100));
        continue;
      }

      // Upload file
      activeUploadsRef.current++;

      uploadFile(nextItem)
        .catch((error) => {
          console.error(`Upload failed for ${nextItem.file.name}:`, error);
        })
        .finally(() => {
          activeUploadsRef.current--;
        });
    }

    processingRef.current = false;
  }, [isPaused, uploadFile]);

  // Automatically process queue when items are added or status changes
  useEffect(() => {
    const hasQueuedItems = queue.some((item) => item.status === 'queued');
    if (hasQueuedItems && !processingRef.current && !isPaused) {
      console.log('[Upload] useEffect detected queued items, triggering processQueue');
      processQueue();
    }
  }, [queue, isPaused, processQueue]);

  // Add files to queue
  const addFiles = useCallback(
    (files: File[]) => {
      console.log('[Upload] Adding files:', files.length);
      const newItems: UploadItem[] = files.map((file) => ({
        id: `${Date.now()}-${Math.random()}`,
        file,
        status: 'queued',
        progress: 0,
        retryCount: 0,
      }));

      setQueue((prev) => {
        console.log('[Upload] Queue before:', prev.length, 'Queue after:', prev.length + newItems.length);
        return [...prev, ...newItems];
      });
    },
    []
  );

  // Remove file from queue
  const removeFile = useCallback((id: string) => {
    setQueue((prev) => prev.filter((item) => item.id !== id));
  }, []);

  // Retry a specific file
  const retryFile = useCallback(
    (id: string) => {
      setQueue((prev) =>
        prev.map((item) =>
          item.id === id
            ? {
                ...item,
                status: 'queued' as const,
                retryCount: 0,
                progress: 0,
              }
            : item
        )
      );
    },
    []
  );

  // Retry all failed uploads
  const retryAll = useCallback(() => {
    setQueue((prev) =>
      prev.map((item) =>
        item.status === 'failed'
          ? {
              ...item,
              status: 'queued' as const,
              retryCount: 0,
              progress: 0,
            }
          : item
      )
    );
  }, []);

  // Pause all uploads
  const pauseAll = useCallback(() => {
    setIsPaused(true);
    setQueue((prev) =>
      prev.map((item) =>
        item.status === 'queued' || item.status === 'uploading'
          ? { ...item, status: 'paused' }
          : item
      )
    );
  }, []);

  // Resume all uploads
  const resumeAll = useCallback(() => {
    setIsPaused(false);
    setQueue((prev) =>
      prev.map((item) =>
        item.status === 'paused' ? { ...item, status: 'queued' } : item
      )
    );
  }, []);

  // Clear completed uploads
  const clearCompleted = useCallback(() => {
    setQueue((prev) => prev.filter((item) => item.status !== 'complete'));
  }, []);

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
    stats,
  };
};

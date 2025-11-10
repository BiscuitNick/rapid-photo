/**
 * Gallery page with photo grid, search, and batch download
 */

import { useState, useCallback, useTransition, useEffect } from 'react';
import { usePhotos, useInvalidatePhotos } from '../hooks/usePhotos';
import { GalleryGrid } from '../components/gallery/GalleryGrid';
import { PhotoLightbox } from '../components/gallery/PhotoLightbox';
import { SearchBar } from '../components/gallery/SearchBar';
import { downloadPhotosAsZip, DownloadProgress } from '../lib/batchDownload';
import { apiService } from '../services/api';
import { useToast } from '../hooks/useToast';
import type { Photo } from '../types/api';

export function GalleryPage() {
  const { toast } = useToast();
  const [, startTransition] = useTransition();

  // Search and filter state
  const [tags, setTags] = useState<string[]>([]);
  const [sort, setSort] = useState('createdAt,desc');

  // Selection state
  const [selectedPhotoIds, setSelectedPhotoIds] = useState<Set<string>>(new Set());

  // Lightbox state
  const [lightboxPhoto, setLightboxPhoto] = useState<Photo | null>(null);

  // Download progress state
  const [downloadProgress, setDownloadProgress] = useState<DownloadProgress | null>(null);

  // Fetch photos
  const {
    photos,
    isLoading,
    isError,
    error,
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
    refetch,
  } = usePhotos({ tags, sort, pageSize: 20 });

  const invalidatePhotos = useInvalidatePhotos();

  // Debug log for photos payload
  useEffect(() => {
    console.log('[Gallery] Photos payload:', {
      totalPhotos: photos.length,
      photos: photos,
      hasNextPage,
      isLoading,
      isFetchingNextPage,
      tags,
      sort
    });

    // Log first photo details if available
    if (photos.length > 0) {
      console.log('[Gallery] First photo details:', photos[0]);
    }
  }, [photos, hasNextPage, isLoading, isFetchingNextPage, tags, sort]);

  const handleSearchChange = useCallback((newTags: string[]) => {
    startTransition(() => {
      setTags(newTags);
    });
  }, []);

  const handleSortChange = useCallback((newSort: string) => {
    startTransition(() => {
      setSort(newSort);
    });
  }, []);

  const handlePhotoSelect = useCallback((photoId: string) => {
    setSelectedPhotoIds((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(photoId)) {
        newSet.delete(photoId);
      } else {
        newSet.add(photoId);
      }
      return newSet;
    });
  }, []);

  const handleSelectAll = useCallback(() => {
    setSelectedPhotoIds(new Set(photos.map((p) => p.id)));
  }, [photos]);

  const handleDeselectAll = useCallback(() => {
    setSelectedPhotoIds(new Set());
  }, []);

  const handleBatchDownload = useCallback(async () => {
    const selectedPhotos = photos.filter((p) => selectedPhotoIds.has(p.id));

    if (selectedPhotos.length === 0) {
      toast({
        title: 'No photos selected',
        description: 'Please select photos to download',
        variant: 'destructive',
      });
      return;
    }

    try {
      await downloadPhotosAsZip(selectedPhotos, (progress) => {
        setDownloadProgress(progress);
      });

      toast({
        title: 'Download complete',
        description: `Downloaded ${selectedPhotos.length} photo${selectedPhotos.length > 1 ? 's' : ''}`,
      });

      setDownloadProgress(null);
      setSelectedPhotoIds(new Set());
    } catch (error) {
      console.error('Batch download failed:', error);
      toast({
        title: 'Download failed',
        description: error instanceof Error ? error.message : 'Failed to download photos',
        variant: 'destructive',
      });
      setDownloadProgress(null);
    }
  }, [photos, selectedPhotoIds, toast]);

  const handleBatchDelete = useCallback(async () => {
    const selectedPhotos = photos.filter((p) => selectedPhotoIds.has(p.id));

    if (selectedPhotos.length === 0) {
      toast({
        title: 'No photos selected',
        description: 'Please select photos to delete',
        variant: 'destructive',
      });
      return;
    }

    // Confirmation dialog
    const confirmed = window.confirm(
      `Are you sure you want to delete ${selectedPhotos.length} photo${selectedPhotos.length > 1 ? 's' : ''}? This action cannot be undone.`
    );

    if (!confirmed) {
      return;
    }

    try {
      // Delete each photo
      const deletePromises = selectedPhotos.map((photo) =>
        apiService.deletePhoto(photo.id)
      );

      await Promise.all(deletePromises);

      toast({
        title: 'Photos deleted',
        description: `Successfully deleted ${selectedPhotos.length} photo${selectedPhotos.length > 1 ? 's' : ''}`,
      });

      // Clear selection and refresh
      setSelectedPhotoIds(new Set());
      invalidatePhotos();
    } catch (error) {
      console.error('Batch delete failed:', error);
      toast({
        title: 'Delete failed',
        description: error instanceof Error ? error.message : 'Failed to delete photos',
        variant: 'destructive',
      });
    }
  }, [photos, selectedPhotoIds, toast, invalidatePhotos]);

  const handlePhotoDelete = useCallback(
    (photoId: string) => {
      // Remove from selection if selected
      setSelectedPhotoIds((prev) => {
        const newSet = new Set(prev);
        newSet.delete(photoId);
        return newSet;
      });

      // Refetch photos
      invalidatePhotos();
    },
    [invalidatePhotos]
  );

  if (isError) {
    return (
      <div className="max-w-7xl mx-auto py-8 px-4 flex items-center justify-center h-[calc(100vh-200px)]">
        <div className="text-center">
          <div className="text-red-600 mb-4">
            <svg className="w-16 h-16 mx-auto" fill="currentColor" viewBox="0 0 20 20">
              <path
                fillRule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                clipRule="evenodd"
              />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Error loading photos</h2>
          <p className="text-gray-600 mb-4">
            {error?.message || 'An unexpected error occurred'}
          </p>
          <button
            onClick={() => refetch()}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Try again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto py-8 px-4">
      {/* Header */}
      <div className="mb-8">
        <h2 className="text-3xl font-bold text-gray-900 mb-2">Photo Gallery</h2>
        <p className="text-gray-600">
          {photos.length > 0
            ? `${photos.length} photo${photos.length !== 1 ? 's' : ''}`
            : 'No photos yet'}
        </p>
      </div>

      {/* Search and filters */}
      <div className="mb-6">
        <SearchBar
          onSearchChange={handleSearchChange}
          onSortChange={handleSortChange}
          currentSort={sort}
        />
      </div>

      {/* Selection controls */}
      {photos.length > 0 && (
        <div className="bg-white rounded-lg border border-gray-200 p-4 mb-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <span className="text-sm text-gray-600">
                {selectedPhotoIds.size} selected
              </span>
              {selectedPhotoIds.size < photos.length && (
                <button
                  onClick={handleSelectAll}
                  className="text-sm text-blue-600 hover:text-blue-700 font-medium"
                >
                  Select all
                </button>
              )}
              {selectedPhotoIds.size > 0 && (
                <button
                  onClick={handleDeselectAll}
                  className="text-sm text-gray-600 hover:text-gray-700 font-medium"
                >
                  Deselect all
                </button>
              )}
            </div>

            {selectedPhotoIds.size > 0 && (
              <div className="flex items-center gap-2">
                <button
                  onClick={handleBatchDelete}
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium flex items-center gap-2"
                >
                  <svg
                    className="w-5 h-5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                    />
                  </svg>
                  Delete {selectedPhotoIds.size} photo
                  {selectedPhotoIds.size !== 1 ? 's' : ''}
                </button>
                <button
                  onClick={handleBatchDownload}
                  disabled={!!downloadProgress}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium flex items-center gap-2"
                >
                  {downloadProgress ? (
                    <>
                      <svg
                        className="animate-spin h-5 w-5"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <circle
                          className="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          strokeWidth="4"
                        />
                        <path
                          className="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        />
                      </svg>
                      Downloading {downloadProgress.current}/{downloadProgress.total}
                    </>
                  ) : (
                    <>
                      <svg
                        className="w-5 h-5"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                        />
                      </svg>
                      Download {selectedPhotoIds.size} photo
                      {selectedPhotoIds.size !== 1 ? 's' : ''}
                    </>
                  )}
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Gallery grid */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        {isLoading && photos.length === 0 ? (
          <div className="flex items-center justify-center h-64">
            <div className="text-center">
              <svg
                className="animate-spin h-12 w-12 mx-auto mb-4 text-blue-600"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
              <p className="text-gray-600">Loading photos...</p>
            </div>
          </div>
        ) : (
          <>
            <GalleryGrid
              photos={photos}
              selectedPhotoIds={selectedPhotoIds}
              onPhotoSelect={handlePhotoSelect}
              onPhotoClick={setLightboxPhoto}
              onLoadMore={fetchNextPage}
              hasMore={hasNextPage}
            />
            {isFetchingNextPage && (
              <div className="text-center py-4">
                <span className="text-sm text-gray-600">Loading more...</span>
              </div>
            )}
          </>
        )}
      </div>

      {/* Lightbox */}
      {lightboxPhoto && (
        <PhotoLightbox
          photo={lightboxPhoto}
          onClose={() => setLightboxPhoto(null)}
          onDelete={handlePhotoDelete}
        />
      )}
    </div>
  );
}

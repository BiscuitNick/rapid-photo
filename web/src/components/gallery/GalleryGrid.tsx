/**
 * Responsive gallery grid component with intersection-based infinite scroll
 */

import { useRef, useEffect } from 'react';
import { Photo } from '../../types/api';
import { PhotoCard } from './PhotoCard';
import { GallerySkeletonCard } from './GallerySkeletonCard';

export interface PendingGridItem {
  key: string;
  photo: Photo | null;
}

interface GalleryGridProps {
  photos: Photo[];
  selectedPhotoIds: Set<string>;
  onPhotoSelect: (photoId: string) => void;
  onPhotoClick: (photo: Photo) => void;
  onLoadMore?: () => void;
  hasMore?: boolean;
  pendingItems?: PendingGridItem[];
}

export function GalleryGrid({
  photos,
  selectedPhotoIds,
  onPhotoSelect,
  onPhotoClick,
  onLoadMore,
  hasMore = false,
  pendingItems = [],
}: GalleryGridProps) {
  const loadMoreRef = useRef<HTMLDivElement | null>(null);

  // Load additional photos when the sentinel enters the viewport
  useEffect(() => {
    if (!hasMore || !onLoadMore) {
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        const firstEntry = entries[0];
        if (firstEntry?.isIntersecting) {
          onLoadMore();
        }
      },
      {
        root: null,
        rootMargin: '200px',
        threshold: 0.1,
      }
    );

    const current = loadMoreRef.current;

    if (current) {
      observer.observe(current);
    }

    return () => {
      if (current) {
        observer.unobserve(current);
      }
      observer.disconnect();
    };
  }, [hasMore, onLoadMore]);

  if (photos.length === 0) {
    return (
      <div className="flex items-center justify-center h-64 text-gray-500">
        <div className="text-center">
          <svg
            className="w-16 h-16 mx-auto mb-4 text-gray-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
            />
          </svg>
          <p className="text-lg font-medium">No photos found</p>
          <p className="text-sm">Upload some photos to get started</p>
        </div>
      </div>
    );
  }

  return (
    <div
      className="flex flex-col gap-6"
    >
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5">
        {pendingItems.map((item) =>
          item.photo ? (
            <PhotoCard
              key={item.key}
              photo={item.photo}
              isSelected={selectedPhotoIds.has(item.photo.id)}
              onSelect={onPhotoSelect}
              onClick={onPhotoClick}
            />
          ) : (
            <GallerySkeletonCard key={item.key} />
          )
        )}
        {photos.map((photo) => (
          <PhotoCard
            key={photo.id}
            photo={photo}
            isSelected={selectedPhotoIds.has(photo.id)}
            onSelect={onPhotoSelect}
            onClick={onPhotoClick}
          />
        ))}
      </div>

      {hasMore && (
        <div
          ref={loadMoreRef}
          className="h-1 w-full"
          aria-hidden="true"
        />
      )}
    </div>
  );
}

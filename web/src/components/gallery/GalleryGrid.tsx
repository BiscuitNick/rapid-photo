/**
 * Virtualized gallery grid component
 */

import { useRef, useEffect } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';
import { Photo } from '../../types/api';
import { PhotoCard } from './PhotoCard';

interface GalleryGridProps {
  photos: Photo[];
  selectedPhotoIds: Set<string>;
  onPhotoSelect: (photoId: string) => void;
  onPhotoClick: (photo: Photo) => void;
  onLoadMore?: () => void;
  hasMore?: boolean;
}

const COLUMN_COUNT = 4;

export function GalleryGrid({
  photos,
  selectedPhotoIds,
  onPhotoSelect,
  onPhotoClick,
  onLoadMore,
  hasMore = false,
}: GalleryGridProps) {
  const parentRef = useRef<HTMLDivElement>(null);

  // Calculate how many rows we need
  const rowCount = Math.ceil(photos.length / COLUMN_COUNT);

  const rowVirtualizer = useVirtualizer({
    count: rowCount,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 300, // Estimated row height
    overscan: 5,
  });

  const virtualRows = rowVirtualizer.getVirtualItems();

  // Load more when near the end
  useEffect(() => {
    const [lastItem] = [...virtualRows].reverse();

    if (!lastItem) {
      return;
    }

    if (
      lastItem.index >= rowCount - 1 &&
      hasMore &&
      onLoadMore
    ) {
      onLoadMore();
    }
  }, [virtualRows, rowCount, hasMore, onLoadMore]);

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
      ref={parentRef}
      className="h-full overflow-auto"
    >
      <div
        style={{
          height: `${rowVirtualizer.getTotalSize()}px`,
          position: 'relative',
        }}
      >
        {virtualRows.map((virtualRow) => {
          const startIndex = virtualRow.index * COLUMN_COUNT;
          const rowPhotos = photos.slice(startIndex, startIndex + COLUMN_COUNT);

          return (
            <div
              key={virtualRow.key}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: `${virtualRow.size}px`,
                transform: `translateY(${virtualRow.start}px)`,
              }}
            >
              <div
                className="grid gap-4"
                style={{
                  gridTemplateColumns: `repeat(${COLUMN_COUNT}, 1fr)`,
                }}
              >
                {rowPhotos.map((photo) => (
                  <PhotoCard
                    key={photo.id}
                    photo={photo}
                    isSelected={selectedPhotoIds.has(photo.id)}
                    onSelect={onPhotoSelect}
                    onClick={onPhotoClick}
                  />
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

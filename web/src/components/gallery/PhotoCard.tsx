/**
 * Photo card component for gallery grid
 */

import { Photo } from '../../types/api';
import { cn } from '../../lib/utils';

interface PhotoCardProps {
  photo: Photo;
  isSelected: boolean;
  onSelect: (photoId: string) => void;
  onClick: (photo: Photo) => void;
}

export function PhotoCard({ photo, isSelected, onSelect, onClick }: PhotoCardProps) {
  const versions = photo?.versions ?? [];
  const tags = photo?.tags ?? [];
  const thumbnailUrl =
    photo?.thumbnailUrl ||
    versions.find((v) => v?.type === 'THUMBNAIL')?.url ||
    photo?.originalUrl ||
    '';

  const handleCheckboxClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    onSelect(photo.id);
  };

  return (
    <div
      className={cn(
        'relative group cursor-pointer overflow-hidden rounded-lg border-2 transition-all',
        isSelected ? 'border-blue-500 ring-2 ring-blue-500' : 'border-transparent hover:border-gray-300'
      )}
      onClick={() => onClick(photo)}
    >
      {/* Selection checkbox */}
      <div
        className="absolute top-2 left-2 z-10"
        onClick={handleCheckboxClick}
      >
        <input
          type="checkbox"
          checked={isSelected}
          onChange={() => {}}
          className="w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500 cursor-pointer"
        />
      </div>

      {/* Photo image */}
      <div className="aspect-square bg-gray-100">
        <img
          src={thumbnailUrl}
          alt={photo.fileName}
          className="w-full h-full object-cover"
          loading="lazy"
        />
      </div>

      {/* Overlay with info */}
      <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/70 to-transparent p-3 opacity-0 group-hover:opacity-100 transition-opacity">
        <p className="text-white text-sm font-medium truncate">{photo.fileName}</p>

        {/* Tags */}
        {tags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-1">
            {tags.slice(0, 3).map((tag, index) => (
              <span
                key={index}
                className="px-2 py-0.5 bg-white/20 text-white text-xs rounded-full backdrop-blur-sm"
              >
                {tag}
              </span>
            ))}
            {tags.length > 3 && (
              <span className="px-2 py-0.5 text-white text-xs">
                +{tags.length - 3}
              </span>
            )}
          </div>
        )}
      </div>

      {/* Status indicator */}
      {photo?.status && photo.status !== 'READY' && (
        <div className="absolute top-2 right-2">
          <span
            className={cn(
              'px-2 py-1 text-xs font-medium rounded',
              photo.status === 'PENDING_PROCESSING' && 'bg-yellow-500 text-white',
              photo.status === 'PROCESSING' && 'bg-blue-500 text-white',
              photo.status === 'FAILED' && 'bg-red-500 text-white'
            )}
          >
            {photo.status === 'PENDING_PROCESSING' && 'Pending'}
            {photo.status === 'PROCESSING' && 'Processing'}
            {photo.status === 'FAILED' && 'Failed'}
          </span>
        </div>
      )}
    </div>
  );
}

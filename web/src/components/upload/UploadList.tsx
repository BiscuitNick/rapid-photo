/**
 * Upload list component displaying all uploads with filtering
 */

import { useState } from 'react';
import { UploadProgressCard } from './UploadProgressCard';
import type { UploadItem, UploadItemStatus } from '../../types/api';

interface UploadListProps {
  items: UploadItem[];
  onRetry?: (id: string) => void;
  onRemove?: (id: string) => void;
}

const filterOptions: { label: string; value: UploadItemStatus | 'all' }[] = [
  { label: 'All', value: 'all' },
  { label: 'Queued', value: 'queued' },
  { label: 'Uploading', value: 'uploading' },
  { label: 'Complete', value: 'complete' },
  { label: 'Failed', value: 'failed' },
  { label: 'Paused', value: 'paused' },
];

export function UploadList({ items, onRetry, onRemove }: UploadListProps) {
  const [filter, setFilter] = useState<UploadItemStatus | 'all'>('all');

  const filteredItems =
    filter === 'all' ? items : items.filter((item) => item.status === filter);

  if (items.length === 0) {
    return (
      <div className="text-center py-12">
        <svg
          className="mx-auto h-12 w-12 text-gray-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
          />
        </svg>
        <h3 className="mt-2 text-sm font-medium text-gray-900">No uploads</h3>
        <p className="mt-1 text-sm text-gray-500">
          Drag and drop images to start uploading
        </p>
      </div>
    );
  }

  return (
    <div>
      {/* Filter Segmented Button */}
      <div className="mb-4 flex flex-wrap gap-2">
        {filterOptions.map((option) => {
          const count =
            option.value === 'all'
              ? items.length
              : items.filter((item) => item.status === option.value).length;

          return (
            <button
              key={option.value}
              onClick={() => setFilter(option.value)}
              className={`
                px-4 py-2 text-sm font-medium rounded-lg transition-colors
                ${
                  filter === option.value
                    ? 'bg-blue-600 text-white'
                    : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
                }
              `}
            >
              {option.label}
              {count > 0 && (
                <span
                  className={`
                  ml-2 px-2 py-0.5 rounded-full text-xs
                  ${
                    filter === option.value
                      ? 'bg-blue-500 text-white'
                      : 'bg-gray-200 text-gray-700'
                  }
                `}
                >
                  {count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* Upload List */}
      <div className="space-y-3">
        {filteredItems.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            No {filter} uploads
          </div>
        ) : (
          filteredItems.map((item) => (
            <UploadProgressCard
              key={item.id}
              item={item}
              onRetry={onRetry}
              onRemove={onRemove}
            />
          ))
        )}
      </div>
    </div>
  );
}

/**
 * Upload progress card component
 */

import { Progress } from '../ui/Progress';
import { formatFileSize } from '../../lib/utils';
import type { UploadItem } from '../../types/api';

interface UploadProgressCardProps {
  item: UploadItem;
  onRetry?: ((id: string) => void) | undefined;
  onRemove?: ((id: string) => void) | undefined;
}

export function UploadProgressCard({
  item,
  onRetry,
  onRemove,
}: UploadProgressCardProps) {
  const fileName = item.file?.name ?? item.fileName ?? 'Unknown file';
  const fileSize = item.file?.size ?? item.fileSize;

  const getStatusColor = () => {
    switch (item.status) {
      case 'complete':
        return 'text-green-600';
      case 'failed':
        return 'text-red-600';
      case 'uploading':
      case 'confirming':
        return 'text-blue-600';
      case 'paused':
        return 'text-yellow-600';
      default:
        return 'text-gray-600';
    }
  };

  const getStatusText = () => {
    switch (item.status) {
      case 'queued':
        return 'Queued';
      case 'uploading':
        return 'Uploading';
      case 'confirming':
        return 'Confirming';
      case 'processing':
        return 'Processing';
      case 'complete':
        return 'Complete';
      case 'failed':
        return item.error || 'Failed';
      case 'paused':
        return 'Paused';
      default:
        return 'Unknown';
    }
  };

  const getStatusIcon = () => {
    switch (item.status) {
      case 'complete':
        return (
          <svg
            className="w-5 h-5 text-green-600"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fillRule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
              clipRule="evenodd"
            />
          </svg>
        );
      case 'failed':
        return (
          <svg
            className="w-5 h-5 text-red-600"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fillRule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clipRule="evenodd"
            />
          </svg>
        );
      case 'uploading':
      case 'confirming':
        return (
          <svg
            className="animate-spin w-5 h-5 text-blue-600"
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
        );
      default:
        return (
          <svg
            className="w-5 h-5 text-gray-400"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fillRule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z"
              clipRule="evenodd"
            />
          </svg>
        );
    }
  };

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-4 hover:shadow-md transition-shadow">
      <div className="flex items-start gap-3">
        <div className="flex-shrink-0 mt-0.5">{getStatusIcon()}</div>

        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2 mb-2">
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 truncate">
                {fileName}
              </p>
              <p className="text-xs text-gray-500">
                {fileSize !== undefined ? formatFileSize(fileSize) : 'Size unavailable'}
              </p>
            </div>

            <div className="flex items-center gap-2">
              {item.status === 'failed' && onRetry && (
                <button
                  onClick={() => onRetry(item.id)}
                  className="text-xs text-blue-600 hover:text-blue-700 font-medium"
                >
                  Retry
                </button>
              )}
              {(item.status === 'queued' ||
                item.status === 'failed' ||
                item.status === 'complete') &&
                onRemove && (
                  <button
                    onClick={() => onRemove(item.id)}
                    className="text-gray-400 hover:text-gray-600"
                  >
                    <svg
                      className="w-4 h-4"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M6 18L18 6M6 6l12 12"
                      />
                    </svg>
                  </button>
                )}
            </div>
          </div>

          <div className="space-y-1">
            <div className="flex items-center justify-between text-xs">
              <span className={getStatusColor()}>{getStatusText()}</span>
              {(item.status === 'uploading' || item.status === 'confirming') && (
                <span className="text-gray-500">{item.progress}%</span>
              )}
            </div>

            {(item.status === 'uploading' ||
              item.status === 'confirming' ||
              item.status === 'queued') && (
              <Progress value={item.progress} className="h-1.5" />
            )}
          </div>

          {item.retryCount > 0 && (
            <p className="text-xs text-gray-500 mt-1">
              Retry attempt {item.retryCount}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

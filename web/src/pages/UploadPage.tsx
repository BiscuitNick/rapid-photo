/**
 * Main upload page with dashboard and controls
 */

import { useUploadQueue } from '../hooks/useUploadQueue';
import { UploadDropzone } from '../components/upload/UploadDropzone';
import { UploadList } from '../components/upload/UploadList';

export function UploadPage() {
  const {
    queue,
    addFiles,
    removeFile,
    retryFile,
    retryAll,
    pauseAll,
    resumeAll,
    clearCompleted,
    stats,
  } = useUploadQueue();

  const hasActiveUploads = stats.uploading > 0 || stats.queued > 0;
  const hasPausedUploads = stats.paused > 0;
  const hasFailedUploads = stats.failed > 0;
  const hasCompletedUploads = stats.complete > 0;

  return (
    <div className="max-w-6xl mx-auto py-8 px-4">
      {/* Header */}
      <div className="mb-8">
        <h2 className="text-3xl font-bold text-gray-900 mb-2">
          Upload Photos
        </h2>
        <p className="text-gray-600">
          Upload up to 100 images at once with automatic processing
        </p>
      </div>

        {/* Stats Cards */}
        {queue.length > 0 && (
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
            <div className="bg-white rounded-lg border border-gray-200 p-4">
              <p className="text-sm text-gray-600 mb-1">Total</p>
              <p className="text-2xl font-bold text-gray-900">{stats.total}</p>
            </div>
            <div className="bg-white rounded-lg border border-gray-200 p-4">
              <p className="text-sm text-gray-600 mb-1">Queued</p>
              <p className="text-2xl font-bold text-yellow-600">
                {stats.queued}
              </p>
            </div>
            <div className="bg-white rounded-lg border border-gray-200 p-4">
              <p className="text-sm text-gray-600 mb-1">Uploading</p>
              <p className="text-2xl font-bold text-blue-600">
                {stats.uploading}
              </p>
            </div>
            <div className="bg-white rounded-lg border border-gray-200 p-4">
              <p className="text-sm text-gray-600 mb-1">Complete</p>
              <p className="text-2xl font-bold text-green-600">
                {stats.complete}
              </p>
            </div>
            <div className="bg-white rounded-lg border border-gray-200 p-4">
              <p className="text-sm text-gray-600 mb-1">Failed</p>
              <p className="text-2xl font-bold text-red-600">{stats.failed}</p>
            </div>
          </div>
        )}

        {/* Batch Controls */}
        {queue.length > 0 && (
          <div className="bg-white rounded-lg border border-gray-200 p-4 mb-6">
            <div className="flex flex-wrap gap-3">
              {hasActiveUploads && (
                <button
                  onClick={pauseAll}
                  className="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition-colors font-medium"
                >
                  Pause All
                </button>
              )}

              {hasPausedUploads && (
                <button
                  onClick={resumeAll}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
                >
                  Resume All
                </button>
              )}

              {hasFailedUploads && (
                <button
                  onClick={retryAll}
                  className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors font-medium"
                >
                  Retry Failed ({stats.failed})
                </button>
              )}

              {hasCompletedUploads && (
                <button
                  onClick={clearCompleted}
                  className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors font-medium"
                >
                  Clear Completed ({stats.complete})
                </button>
              )}

              <div className="ml-auto text-sm text-gray-600 flex items-center">
                Processing up to 10 concurrent uploads
              </div>
            </div>
          </div>
        )}

        {/* Dropzone */}
        <div className="mb-6">
          <UploadDropzone
            onFilesAdded={addFiles}
            disabled={hasActiveUploads}
            maxFiles={100}
          />
        </div>

        {/* Upload List */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            Upload Queue
          </h2>
          <UploadList
            items={queue}
            onRetry={retryFile}
            onRemove={removeFile}
          />
        </div>
      </div>
  );
}

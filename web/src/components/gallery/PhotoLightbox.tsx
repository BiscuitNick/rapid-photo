/**
 * Photo lightbox modal for viewing full photo details
 */

import { useState } from 'react';
import { Photo } from '../../types/api';
import { apiService } from '../../services/api';
import { useToast } from '../../hooks/useToast';

interface PhotoLightboxProps {
  photo: Photo;
  onClose: () => void;
  onDelete?: (photoId: string) => void;
}

export function PhotoLightbox({ photo, onClose, onDelete }: PhotoLightboxProps) {
  const { toast } = useToast();
  const [selectedVersion, setSelectedVersion] = useState<string>('original');
  const [isDownloading, setIsDownloading] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  // Get the appropriate image URL based on selected version
  const getImageUrl = () => {
    if (selectedVersion === 'original') {
      return photo.originalUrl;
    }
    const version = photo.versions.find(v => v.type === selectedVersion);
    return version?.url || photo.originalUrl;
  };

  const handleDownload = async () => {
    setIsDownloading(true);
    try {
      const { url } = await apiService.getDownloadUrl(photo.id, selectedVersion);

      // Trigger download
      const link = document.createElement('a');
      link.href = url;
      link.download = photo.fileName;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      toast({
        title: 'Download started',
        description: `Downloading ${photo.fileName}`,
      });
    } catch (error) {
      console.error('Download failed:', error);
      toast({
        title: 'Download failed',
        description: 'Failed to download photo. Please try again.',
        variant: 'destructive',
      });
    } finally {
      setIsDownloading(false);
    }
  };

  const handleDelete = async () => {
    if (!confirm(`Are you sure you want to delete ${photo.fileName}?`)) {
      return;
    }

    setIsDeleting(true);
    try {
      await apiService.deletePhoto(photo.id);
      toast({
        title: 'Photo deleted',
        description: `${photo.fileName} has been deleted`,
      });
      onDelete?.(photo.id);
      onClose();
    } catch (error) {
      console.error('Delete failed:', error);
      toast({
        title: 'Delete failed',
        description: 'Failed to delete photo. Please try again.',
        variant: 'destructive',
      });
    } finally {
      setIsDeleting(false);
    }
  };

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center p-4"
      onClick={handleBackdropClick}
    >
      <div className="max-w-7xl w-full h-full flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold text-white truncate">
            {photo.fileName}
          </h2>
          <button
            onClick={onClose}
            className="text-white hover:text-gray-300 transition-colors p-2"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Main content */}
        <div className="flex-1 flex gap-4 overflow-hidden">
          {/* Image preview */}
          <div className="flex-1 flex items-center justify-center bg-black rounded-lg">
            <img
              src={getImageUrl()}
              alt={photo.fileName}
              className="max-w-full max-h-full object-contain"
            />
          </div>

          {/* Sidebar */}
          <div className="w-80 bg-white rounded-lg p-6 overflow-y-auto">
            {/* Version selector */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Version
              </label>
              <select
                value={selectedVersion}
                onChange={(e) => setSelectedVersion(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="original">Original</option>
                {photo.versions.map((version) => (
                  <option key={version.type} value={version.type}>
                    {version.type.replace(/_/g, ' ')} {version.width && `(${version.width}px)`}
                  </option>
                ))}
              </select>
            </div>

            {/* Actions */}
            <div className="mb-6 space-y-2">
              <button
                onClick={handleDownload}
                disabled={isDownloading}
                className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
              >
                {isDownloading ? 'Downloading...' : 'Download'}
              </button>
              {onDelete && (
                <button
                  onClick={handleDelete}
                  disabled={isDeleting}
                  className="w-full px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                >
                  {isDeleting ? 'Deleting...' : 'Delete'}
                </button>
              )}
            </div>

            {/* Tags */}
            {photo.tags.length > 0 && (
              <div className="mb-6">
                <h3 className="text-sm font-medium text-gray-700 mb-2">Tags</h3>
                <div className="flex flex-wrap gap-2">
                  {photo.tags.map((tag, index) => (
                    <span
                      key={index}
                      className="px-3 py-1 bg-blue-100 text-blue-800 text-sm rounded-full"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Metadata */}
            <div className="space-y-4">
              <h3 className="text-sm font-medium text-gray-700">Details</h3>

              {photo.metadata.width && photo.metadata.height && (
                <div>
                  <p className="text-xs text-gray-500">Dimensions</p>
                  <p className="text-sm text-gray-900">
                    {photo.metadata.width} × {photo.metadata.height}
                  </p>
                </div>
              )}

              {photo.metadata.format && (
                <div>
                  <p className="text-xs text-gray-500">Format</p>
                  <p className="text-sm text-gray-900">{photo.metadata.format}</p>
                </div>
              )}

              {photo.metadata.size && (
                <div>
                  <p className="text-xs text-gray-500">Size</p>
                  <p className="text-sm text-gray-900">
                    {(photo.metadata.size / 1024 / 1024).toFixed(2)} MB
                  </p>
                </div>
              )}

              {photo.metadata.cameraModel && (
                <div>
                  <p className="text-xs text-gray-500">Camera</p>
                  <p className="text-sm text-gray-900">{photo.metadata.cameraModel}</p>
                </div>
              )}

              {photo.metadata.takenAt && (
                <div>
                  <p className="text-xs text-gray-500">Taken</p>
                  <p className="text-sm text-gray-900">
                    {new Date(photo.metadata.takenAt).toLocaleString()}
                  </p>
                </div>
              )}

              <div>
                <p className="text-xs text-gray-500">Uploaded</p>
                <p className="text-sm text-gray-900">
                  {new Date(photo.createdAt).toLocaleString()}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

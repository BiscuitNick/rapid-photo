/**
 * Photo lightbox modal for viewing full photo details
 */

import { useState, useEffect } from 'react';
import { Photo, PhotoDetail } from '../../types/api';
import { apiService } from '../../services/api';
import { useToast } from '../../hooks/useToast';

interface PhotoLightboxProps {
  photo: Photo;
  onClose: () => void;
  onDelete?: (photoId: string) => void;
}

export function PhotoLightbox({ photo, onClose, onDelete }: PhotoLightboxProps) {
  const { toast } = useToast();
  const [photoDetail, setPhotoDetail] = useState<PhotoDetail | null>(null);
  const [isLoadingDetail, setIsLoadingDetail] = useState(true);
  const [isDownloading, setIsDownloading] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  // Fetch photo details when component mounts
  useEffect(() => {
    const fetchPhotoDetail = async () => {
      try {
        setIsLoadingDetail(true);
        const detail = await apiService.getPhoto(photo.id);
        setPhotoDetail(detail);
      } catch (error) {
        console.error('Failed to fetch photo details:', error);
        toast({
          title: 'Failed to load photo details',
          description: 'Could not load full photo information',
          variant: 'destructive',
        });
      } finally {
        setIsLoadingDetail(false);
      }
    };

    fetchPhotoDetail();
  }, [photo.id, toast]);

  // Get the best available image URL for preview
  const getImageUrl = () => {
    if (!photoDetail) return photo.thumbnailUrl || photo.originalUrl || '';

    // Try to find a large webp version for preview, fallback to original
    const largeVersion = photoDetail.versions.find(v =>
      v.versionType === 'WEBP_1920' || v.versionType === 'WEBP_2560'
    );
    return largeVersion?.url || photoDetail.originalUrl;
  };

  const handleDownload = async () => {
    setIsDownloading(true);
    try {
      const response = await apiService.getDownloadUrl(photo.id, 'original');

      // Trigger download
      const link = document.createElement('a');
      link.href = response.downloadUrl;
      link.download = response.fileName;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      toast({
        title: 'Download started',
        description: `Downloading ${response.fileName}`,
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

  if (isLoadingDetail) {
    return (
      <div className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center p-4">
        <div className="text-white text-center">
          <svg
            className="animate-spin h-12 w-12 mx-auto mb-4"
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
          <p>Loading photo details...</p>
        </div>
      </div>
    );
  }

  if (!photoDetail) {
    return null;
  }

  return (
    <div
      className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center p-4"
      onClick={handleBackdropClick}
    >
      <div className="max-w-7xl w-full h-full flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold text-white truncate">
            {photoDetail.fileName}
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
              alt={photoDetail.fileName}
              className="max-w-full max-h-full object-contain"
            />
          </div>

          {/* Sidebar */}
          <div className="w-80 bg-white rounded-lg p-6 overflow-y-auto">
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

            {/* Labels */}
            {photoDetail.labels.length > 0 && (
              <div className="mb-6">
                <h3 className="text-sm font-medium text-gray-700 mb-2">Labels</h3>
                <div className="flex flex-wrap gap-2">
                  {photoDetail.labels.map((label, index) => (
                    <span
                      key={index}
                      className="px-3 py-1 bg-blue-100 text-blue-800 text-sm rounded-full"
                      title={`Confidence: ${label.confidence.toFixed(2)}%`}
                    >
                      {label.labelName}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Image Versions */}
            <div className="mb-6">
              <h3 className="text-sm font-medium text-gray-700 mb-3">Image Versions</h3>
              <div className="space-y-1.5">
                {/* Original */}
                {photoDetail.width && photoDetail.height && (
                  <a
                    href={photoDetail.originalUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block text-sm text-blue-600 hover:text-blue-800 hover:underline"
                  >
                    {photoDetail.width}x{photoDetail.height}-{photoDetail.mimeType?.split('/')[1]?.toLowerCase() || 'original'}
                  </a>
                )}

                {/* Other versions sorted by size */}
                {photoDetail.versions
                  .filter(v => v.width && v.height)
                  .sort((a, b) => (a.width || 0) - (b.width || 0))
                  .map((version) => {
                    const format = version.mimeType?.split('/')[1]?.toLowerCase() ||
                                  (version.versionType.includes('WEBP') ? 'webp' :
                                   version.versionType === 'THUMBNAIL' ? 'jpeg' : 'unknown');

                    return (
                      <a
                        key={version.versionType}
                        href={version.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="block text-sm text-blue-600 hover:text-blue-800 hover:underline"
                      >
                        {version.width}x{version.height}-{format}
                      </a>
                    );
                  })}
              </div>
            </div>

            {/* Metadata */}
            <div className="space-y-4">
              <h3 className="text-sm font-medium text-gray-700">Details</h3>

              {photoDetail.width && photoDetail.height && (
                <div>
                  <p className="text-xs text-gray-500">Dimensions</p>
                  <p className="text-sm text-gray-900">
                    {photoDetail.width} × {photoDetail.height}
                  </p>
                </div>
              )}

              {photoDetail.mimeType && (
                <div>
                  <p className="text-xs text-gray-500">Format</p>
                  <p className="text-sm text-gray-900">{photoDetail.mimeType}</p>
                </div>
              )}

              {photoDetail.fileSize && (
                <div>
                  <p className="text-xs text-gray-500">Size</p>
                  <p className="text-sm text-gray-900">
                    {(photoDetail.fileSize / 1024 / 1024).toFixed(2)} MB
                  </p>
                </div>
              )}

              {photoDetail.cameraMake && photoDetail.cameraModel && (
                <div>
                  <p className="text-xs text-gray-500">Camera</p>
                  <p className="text-sm text-gray-900">
                    {photoDetail.cameraMake} {photoDetail.cameraModel}
                  </p>
                </div>
              )}

              {photoDetail.takenAt && (
                <div>
                  <p className="text-xs text-gray-500">Taken</p>
                  <p className="text-sm text-gray-900">
                    {new Date(photoDetail.takenAt).toLocaleString()}
                  </p>
                </div>
              )}

              <div>
                <p className="text-xs text-gray-500">Uploaded</p>
                <p className="text-sm text-gray-900">
                  {new Date(photoDetail.createdAt).toLocaleString()}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

/**
 * Batch download utility for creating and downloading ZIP archives
 */

import { zipSync, strToU8 } from 'fflate';
import { apiService } from '../services/api';
import type { Photo } from '../types/api';

export interface DownloadProgress {
  current: number;
  total: number;
  fileName: string;
}

export async function downloadPhotosAsZip(
  photos: Photo[],
  onProgress?: (progress: DownloadProgress) => void
): Promise<void> {
  if (photos.length === 0) {
    throw new Error('No photos to download');
  }

  const files: Record<string, Uint8Array> = {};
  const total = photos.length;

  // Fetch all photos
  for (let i = 0; i < photos.length; i++) {
    const photo = photos[i];
    if (!photo) continue;

    try {
      onProgress?.({
        current: i + 1,
        total,
        fileName: photo.fileName,
      });

      // Get download URL
      const { url } = await apiService.getDownloadUrl(photo.id, 'original');

      // Fetch the file
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Failed to fetch ${photo.fileName}`);
      }

      const blob = await response.blob();
      const arrayBuffer = await blob.arrayBuffer();
      const uint8Array = new Uint8Array(arrayBuffer);

      // Use filename, ensure uniqueness by adding index if needed
      let fileName = photo.fileName;
      let counter = 1;
      while (files[fileName]) {
        const lastDot = photo.fileName.lastIndexOf('.');
        if (lastDot > 0) {
          const name = photo.fileName.substring(0, lastDot);
          const ext = photo.fileName.substring(lastDot);
          fileName = `${name}_${counter}${ext}`;
        } else {
          fileName = `${photo.fileName}_${counter}`;
        }
        counter++;
      }

      files[fileName] = uint8Array;
    } catch (error) {
      console.error(`Failed to download ${photo.fileName}:`, error);
      // Add error file
      files[`ERROR_${photo.fileName}.txt`] = strToU8(
        `Failed to download this file: ${error instanceof Error ? error.message : 'Unknown error'}`
      );
    }
  }

  // Create ZIP
  const zipped = zipSync(files, {
    level: 0, // No compression for faster processing
  });

  // Trigger download
  const blob = new Blob([zipped], { type: 'application/zip' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `photos_${new Date().toISOString().split('T')[0]}_${photos.length}.zip`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/**
 * Utility functions for the application
 */

import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Merge Tailwind CSS classes with clsx
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * Format file size in human-readable format
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

/**
 * Validate file is an image and within size limits
 */
export function validateFile(
  file: File
): { valid: boolean; error?: string } {
  const maxSize = 100 * 1024 * 1024; // 100MB
  const allowedTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/heic',
    'image/heif',
  ];

  if (!allowedTypes.includes(file.type)) {
    return {
      valid: false,
      error: 'Only image files are allowed (JPEG, PNG, GIF, WebP, HEIC, HEIF)',
    };
  }

  if (file.size > maxSize) {
    return {
      valid: false,
      error: 'File size must not exceed 100MB',
    };
  }

  return { valid: true };
}

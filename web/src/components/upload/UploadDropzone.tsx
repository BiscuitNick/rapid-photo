/**
 * Drag-and-drop upload zone component
 */

import { useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { cn, validateFile } from '../../lib/utils';
import { useToast } from '../../hooks/useToast';

interface UploadDropzoneProps {
  onFilesAdded: (files: File[]) => void;
  disabled?: boolean;
  maxFiles?: number;
}

export function UploadDropzone({
  onFilesAdded,
  disabled = false,
  maxFiles = 100,
}: UploadDropzoneProps) {
  const { toast } = useToast();

  const onDrop = useCallback(
    (acceptedFiles: File[], rejectedFiles: any[]) => {
      // Validate accepted files
      const validFiles: File[] = [];
      const errors: string[] = [];

      acceptedFiles.forEach((file) => {
        const validation = validateFile(file);
        if (validation.valid) {
          validFiles.push(file);
        } else {
          errors.push(`${file.name}: ${validation.error}`);
        }
      });

      // Handle rejected files
      rejectedFiles.forEach((rejection) => {
        errors.push(`${rejection.file.name}: File type not supported`);
      });

      // Show errors if any
      if (errors.length > 0) {
        toast({
          title: 'Some files were rejected',
          description: errors.slice(0, 3).join(', '),
          variant: 'destructive',
        });
      }

      // Add valid files
      if (validFiles.length > 0) {
        onFilesAdded(validFiles);
        toast({
          title: 'Files added to queue',
          description: `${validFiles.length} file(s) added successfully`,
          variant: 'success',
        });
      }
    },
    [onFilesAdded, toast]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/jpeg': ['.jpg', '.jpeg'],
      'image/png': ['.png'],
      'image/gif': ['.gif'],
      'image/webp': ['.webp'],
      'image/heic': ['.heic'],
      'image/heif': ['.heif'],
    },
    maxFiles,
    disabled,
    multiple: true,
  });

  return (
    <div
      {...getRootProps()}
      className={cn(
        'border-2 border-dashed rounded-lg p-12 text-center cursor-pointer transition-colors',
        'hover:border-blue-400 hover:bg-blue-50',
        isDragActive && 'border-blue-500 bg-blue-50',
        disabled && 'opacity-50 cursor-not-allowed hover:border-gray-300 hover:bg-transparent'
      )}
    >
      <input {...getInputProps()} />

      <div className="flex flex-col items-center">
        <svg
          className="w-16 h-16 mb-4 text-gray-400"
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

        {isDragActive ? (
          <p className="text-lg font-medium text-blue-600">
            Drop your images here...
          </p>
        ) : (
          <>
            <p className="text-lg font-medium text-gray-900 mb-2">
              Drag & drop images here
            </p>
            <p className="text-sm text-gray-600 mb-4">
              or click to browse files
            </p>
            <p className="text-xs text-gray-500">
              Supports JPEG, PNG, GIF, WebP, HEIC, HEIF (max 100MB per file)
            </p>
            <p className="text-xs text-gray-500 mt-1">
              Upload up to {maxFiles} files at once
            </p>
          </>
        )}
      </div>
    </div>
  );
}

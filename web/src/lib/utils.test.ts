/**
 * Tests for utility functions
 */

import { describe, it, expect } from 'vitest';
import { formatFileSize, validateFile, cn } from './utils';

describe('formatFileSize', () => {
  it('should format bytes correctly', () => {
    expect(formatFileSize(0)).toBe('0 Bytes');
    expect(formatFileSize(1024)).toBe('1 KB');
    expect(formatFileSize(1024 * 1024)).toBe('1 MB');
    expect(formatFileSize(1024 * 1024 * 1024)).toBe('1 GB');
  });

  it('should handle decimal places', () => {
    expect(formatFileSize(1536)).toBe('1.5 KB');
    expect(formatFileSize(1024 * 1024 * 1.5)).toBe('1.5 MB');
  });
});

describe('validateFile', () => {
  it('should accept valid image files', () => {
    const file = new File(['content'], 'test.jpg', { type: 'image/jpeg' });
    const result = validateFile(file);
    expect(result.valid).toBe(true);
    expect(result.error).toBeUndefined();
  });

  it('should reject files that are too large', () => {
    const largeFile = new File(['x'.repeat(101 * 1024 * 1024)], 'large.jpg', {
      type: 'image/jpeg',
    });
    Object.defineProperty(largeFile, 'size', {
      value: 101 * 1024 * 1024,
    });
    const result = validateFile(largeFile);
    expect(result.valid).toBe(false);
    expect(result.error).toContain('100MB');
  });

  it('should reject non-image files', () => {
    const file = new File(['content'], 'test.pdf', {
      type: 'application/pdf',
    });
    const result = validateFile(file);
    expect(result.valid).toBe(false);
    expect(result.error).toContain('image files');
  });
});

describe('cn', () => {
  it('should merge class names', () => {
    const result = cn('foo', 'bar');
    expect(result).toBe('foo bar');
  });

  it('should handle conditional classes', () => {
    const result = cn('foo', false && 'bar', 'baz');
    expect(result).toBe('foo baz');
  });
});

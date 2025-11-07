/**
 * Tests for UploadProgressCard component
 */

import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { UploadProgressCard } from './UploadProgressCard';
import type { UploadItem } from '../../types/api';

describe('UploadProgressCard', () => {
  const createMockItem = (
    overrides: Partial<UploadItem> = {}
  ): UploadItem => ({
    id: '1',
    file: new File(['content'], 'test.jpg', { type: 'image/jpeg' }),
    status: 'queued',
    progress: 0,
    retryCount: 0,
    ...overrides,
  });

  it('should render file name and size', () => {
    const item = createMockItem();
    render(<UploadProgressCard item={item} />);

    expect(screen.getByText('test.jpg')).toBeInTheDocument();
    expect(screen.getByText(/Bytes/)).toBeInTheDocument();
  });

  it('should show progress for uploading files', () => {
    const item = createMockItem({
      status: 'uploading',
      progress: 50,
    });
    render(<UploadProgressCard item={item} />);

    expect(screen.getByText('Uploading')).toBeInTheDocument();
    expect(screen.getByText('50%')).toBeInTheDocument();
  });

  it('should show complete status', () => {
    const item = createMockItem({
      status: 'complete',
      progress: 100,
    });
    render(<UploadProgressCard item={item} />);

    expect(screen.getByText('Complete')).toBeInTheDocument();
  });

  it('should show error message for failed uploads', () => {
    const item = createMockItem({
      status: 'failed',
      error: 'Upload failed',
    });
    render(<UploadProgressCard item={item} />);

    expect(screen.getByText('Upload failed')).toBeInTheDocument();
  });

  it('should show retry count when greater than 0', () => {
    const item = createMockItem({
      retryCount: 2,
    });
    render(<UploadProgressCard item={item} />);

    expect(screen.getByText('Retry attempt 2')).toBeInTheDocument();
  });
});

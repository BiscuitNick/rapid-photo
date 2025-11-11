/**
 * React Query hook for fetching and managing photos
 */

import { useInfiniteQuery, useQueryClient } from '@tanstack/react-query';
import { apiService } from '../services/api';
import type { Photo, SearchPhotosParams } from '../types/api';

export interface UsePhotosParams {
  tags?: string[];
  sort?: string;
  pageSize?: number;
}

export interface UsePhotosResult {
  photos: Photo[];
  isLoading: boolean;
  isError: boolean;
  error: Error | null;
  hasNextPage: boolean;
  isFetchingNextPage: boolean;
  fetchNextPage: () => void;
  refetch: () => void;
}

const QUERY_KEY = 'photos';
const DEFAULT_PAGE_SIZE = 20;

export function usePhotos(params: UsePhotosParams = {}): UsePhotosResult {
  const { tags = [], sort = 'createdAt,desc', pageSize = DEFAULT_PAGE_SIZE } = params;

  const isSearch = tags.length > 0;

  const {
    data,
    isLoading,
    isError,
    error,
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
    refetch,
  } = useInfiniteQuery({
    queryKey: [QUERY_KEY, { tags, sort, pageSize }],
    queryFn: async ({ pageParam = 0 }) => {
      const searchParams: SearchPhotosParams = {
        page: pageParam,
        size: pageSize,
        sort,
        ...(tags.length > 0 && { tags }),
      };

      console.log('[usePhotos] Fetching page:', pageParam, 'size:', pageSize);

      // Use search endpoint if tags are provided, otherwise use regular getPhotos
      const result = isSearch
        ? await apiService.searchPhotos(searchParams)
        : await apiService.getPhotos(searchParams);

      console.log('[usePhotos] Got', result.content?.length || 0, 'photos for page', pageParam);
      return result;
    },
    getNextPageParam: (lastPage) => {
      return lastPage.hasNext ? lastPage.page + 1 : undefined;
    },
    initialPageParam: 0,
    staleTime: 0, // Always consider data stale for real-time updates
    gcTime: 5 * 60 * 1000, // Keep cache for 5 minutes
    refetchOnMount: true, // Refetch when component mounts
    refetchOnWindowFocus: false, // Disable to prevent excessive requests
    refetchInterval: 5000 // Poll every 5 seconds for real-time updates
  });

  // Flatten all pages into a single array of photos
  const photos = data?.pages.flatMap((page) => page.content) ?? [];

  return {
    photos,
    isLoading,
    isError,
    error: error as Error | null,
    hasNextPage: hasNextPage ?? false,
    isFetchingNextPage,
    fetchNextPage: () => {
      if (hasNextPage && !isFetchingNextPage) {
        fetchNextPage();
      }
    },
    refetch: () => {
      refetch();
    },
  };
}

/**
 * Hook to invalidate photos query (useful after uploads)
 */
export function useInvalidatePhotos() {
  const queryClient = useQueryClient();

  return () => {
    // Invalidate ALL photos queries regardless of sort/filter parameters
    // This ensures all cached versions are refreshed
    queryClient.invalidateQueries({
      queryKey: [QUERY_KEY],
      exact: false // Match all queries that start with QUERY_KEY
    });
  };
}

/**
 * Hook to manually refresh all photo queries
 * Forces immediate refetch of all photo data
 */
export function useRefreshPhotos() {
  const queryClient = useQueryClient();

  return async () => {
    // Cancel any in-flight queries
    await queryClient.cancelQueries({ queryKey: [QUERY_KEY] });

    // Invalidate and refetch all photo queries
    await queryClient.invalidateQueries({
      queryKey: [QUERY_KEY],
      exact: false
    });

    // Refetch all photo queries immediately
    await queryClient.refetchQueries({
      queryKey: [QUERY_KEY],
      exact: false
    });
  };
}

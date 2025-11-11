/**
 * React Query mutations for photo operations with optimistic updates
 */

import { useMutation, useQueryClient } from '@tanstack/react-query';
import { apiService } from '../services/api';
import type { Photo } from '../types/api';

const QUERY_KEY = 'photos';

type InfinitePhotosData = {
  pages: Array<{
    content?: Photo[];
    [key: string]: unknown;
  }>;
};

function isInfinitePhotosData(data: unknown): data is InfinitePhotosData {
  if (typeof data !== 'object' || data === null) {
    return false;
  }
  return Array.isArray((data as { pages?: unknown }).pages);
}

/**
 * Hook for deleting a photo with optimistic updates
 */
export function useDeletePhoto() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (photoId: string) => apiService.deletePhoto(photoId),

    onMutate: async (photoId) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: [QUERY_KEY] });

      // Get all photo queries
      const queries = queryClient.getQueriesData({ queryKey: [QUERY_KEY] });

      // Optimistically remove the photo from ALL cached queries
      queries.forEach(([queryKey, oldData]) => {
        if (!isInfinitePhotosData(oldData)) return;

        const newData = {
          ...oldData,
          pages: oldData.pages.map((page) => ({
            ...page,
            content: page.content?.filter((photo) => photo.id !== photoId) ?? []
          }))
        };
        queryClient.setQueryData(queryKey, newData);
      });

      // Return context for rollback
      return { queries };
    },

    onError: (_err, _photoId, context) => {
      // Rollback on error
      if (context?.queries) {
        context.queries.forEach(([queryKey, oldData]) => {
          queryClient.setQueryData(queryKey, oldData);
        });
      }
    },

    onSettled: () => {
      // Invalidate and refetch after mutation
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    }
  });
}

/**
 * Hook for batch deleting photos with optimistic updates
 */
export function useBatchDeletePhotos() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (photoIds: string[]) => {
      const deletePromises = photoIds.map(id => apiService.deletePhoto(id));
      return Promise.all(deletePromises);
    },

    onMutate: async (photoIds) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: [QUERY_KEY] });

      // Get all photo queries
      const queries = queryClient.getQueriesData({ queryKey: [QUERY_KEY] });

      // Optimistically remove the photos from ALL cached queries
      queries.forEach(([queryKey, oldData]) => {
        if (!isInfinitePhotosData(oldData)) return;

        const newData = {
          ...oldData,
          pages: oldData.pages.map((page) => ({
            ...page,
            content: page.content?.filter((photo) => !photoIds.includes(photo.id)) ?? []
          }))
        };
        queryClient.setQueryData(queryKey, newData);
      });

      // Return context for rollback
      return { queries };
    },

    onError: (_err, _photoIds, context) => {
      // Rollback on error
      if (context?.queries) {
        context.queries.forEach(([queryKey, oldData]) => {
          queryClient.setQueryData(queryKey, oldData);
        });
      }
    },

    onSettled: () => {
      // Invalidate and refetch after mutation
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    }
  });
}

/**
 * Hook to add a new photo to all cached queries
 */
export function useAddPhotoToCache() {
  const queryClient = useQueryClient();

  return (newPhoto: Photo) => {
    // Get all photo queries
    const queries = queryClient.getQueriesData({ queryKey: [QUERY_KEY] });

    queries.forEach(([queryKey, oldData]) => {
      if (!isInfinitePhotosData(oldData)) return;

      const newData = {
        ...oldData,
        pages: oldData.pages.map((page, index) => {
          if (index === 0) {
            return {
              ...page,
              content: [newPhoto, ...(page.content ?? [])]
            };
          }
          return page;
        })
      };
      queryClient.setQueryData(queryKey, newData);
    });
  };
}

/**
 * Hook to update a photo in all cached queries
 */
export function useUpdatePhotoInCache() {
  const queryClient = useQueryClient();

  return (photoId: string, updates: Partial<Photo>) => {
    // Get all photo queries
    const queries = queryClient.getQueriesData({ queryKey: [QUERY_KEY] });

    queries.forEach(([queryKey, oldData]) => {
      if (!isInfinitePhotosData(oldData)) return;

      const newData = {
        ...oldData,
        pages: oldData.pages.map((page) => ({
          ...page,
          content: page.content?.map((photo) =>
            photo.id === photoId ? { ...photo, ...updates } : photo
          ) ?? []
        }))
      };
      queryClient.setQueryData(queryKey, newData);
    });
  };
}

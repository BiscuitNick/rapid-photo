/**
 * Global upload queue store using Zustand
 * Persists upload queue across navigation
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { UploadItem } from '../types/api';

interface UploadStore {
  queue: UploadItem[];
  setQueue: (queue: UploadItem[]) => void;
  addToQueue: (items: UploadItem[]) => void;
  updateItem: (id: string, updates: Partial<UploadItem>) => void;
  removeItem: (id: string) => void;
  clearCompleted: () => void;
  clearAll: () => void;
}

export const useUploadStore = create<UploadStore>()(
  persist(
    (set) => ({
      queue: [],

      setQueue: (queue) => set({ queue }),

      addToQueue: (items) => set((state) => ({
        queue: [...state.queue, ...items]
      })),

      updateItem: (id, updates) => set((state) => ({
        queue: state.queue.map((item) =>
          item.id === id ? { ...item, ...updates } : item
        )
      })),

      removeItem: (id) => set((state) => ({
        queue: state.queue.filter((item) => item.id !== id)
      })),

      clearCompleted: () => set((state) => ({
        queue: state.queue.filter((item) => item.status !== 'complete')
      })),

      clearAll: () => set({ queue: [] }),
    }),
    {
      name: 'upload-queue-storage',
      // Persist all items to maintain queue across navigation
      partialize: (state) => ({
        queue: state.queue.map((item) => ({
          ...item,
          file: undefined,
        }))
      }),
      // When rehydrating, keep only entries that no longer need the original File object
      onRehydrateStorage: () => (state) => {
        if (state) {
          state.queue = state.queue.filter(
            (item: UploadItem) => item.status === 'complete' || item.status === 'failed'
          );
        }
      },
    }
  )
);

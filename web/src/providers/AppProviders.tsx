/**
 * Application providers wrapper
 */

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ToastContextProvider } from '../hooks/useToast';
import { Toaster } from '../components/ui/Toaster';
import { useEffect } from 'react';
import { configureAmplify } from '../config/amplify';
import { useAuthStore } from '../stores/authStore';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

export function AppProviders({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    // Configure Amplify on mount
    configureAmplify().catch((error) => {
      console.error('Failed to configure Amplify:', error);
    });

    // Check authentication status only once on initial mount
    // Trust persisted auth state from localStorage for subsequent renders
    const checkAuth = useAuthStore.getState().checkAuth;
    checkAuth();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <QueryClientProvider client={queryClient}>
      <ToastContextProvider>
        {children}
        <Toaster />
      </ToastContextProvider>
    </QueryClientProvider>
  );
}

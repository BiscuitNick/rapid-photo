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
  const checkAuth = useAuthStore((state) => state.checkAuth);

  useEffect(() => {
    // Configure Amplify on mount
    configureAmplify();

    // Check authentication status
    checkAuth();
  }, [checkAuth]);

  return (
    <QueryClientProvider client={queryClient}>
      <ToastContextProvider>
        {children}
        <Toaster />
      </ToastContextProvider>
    </QueryClientProvider>
  );
}

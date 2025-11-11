/**
 * Zustand store for authentication state management
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { fetchAuthSession, signIn, signOut, getCurrentUser } from 'aws-amplify/auth';

interface User {
  id: string;
  email: string;
  username: string;
}

interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  accessToken: string | null;
  idToken: string | null;
  lastAuthCheck: number | null;
}

interface AuthActions {
  setUser: (user: User | null) => void;
  setTokens: (accessToken: string | null, idToken: string | null) => void;
  setLoading: (isLoading: boolean) => void;
  setError: (error: string | null) => void;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
  refreshTokens: () => Promise<void>;
}

type AuthStore = AuthState & AuthActions;

const USER_ALREADY_AUTHENTICATED_EXCEPTION = 'UserAlreadyAuthenticatedException';

function isAlreadySignedInError(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'name' in error &&
    (error as { name?: string }).name === USER_ALREADY_AUTHENTICATED_EXCEPTION
  );
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set, get) => ({
      // State
      user: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,
      accessToken: null,
      idToken: null,
      lastAuthCheck: null,

      // Actions
      setUser: (user) =>
        set({ user, isAuthenticated: !!user }),

      setTokens: (accessToken, idToken) =>
        set({ accessToken, idToken }),

      setLoading: (isLoading) =>
        set({ isLoading }),

      setError: (error) =>
        set({ error }),

      login: async (email, password) => {
        set({ isLoading: true, error: null });
        try {
          await signIn({
            username: email,
            password,
          });

          await get().checkAuth();
        } catch (error) {
          if (isAlreadySignedInError(error)) {
            await get().checkAuth();
            return;
          }
          const message = error instanceof Error ? error.message : 'Login failed';
          set({ error: message, isLoading: false });
          throw error;
        }
      },

      logout: async () => {
        try {
          set({ isLoading: true, error: null });

          await signOut();

          set({
            user: null,
            isAuthenticated: false,
            accessToken: null,
            idToken: null,
            lastAuthCheck: null,
            isLoading: false,
          });
        } catch (error) {
          const message = error instanceof Error ? error.message : 'Logout failed';
          set({ error: message, isLoading: false });
          throw error;
        }
      },

      checkAuth: async () => {
        try {
          const state = get();
          const now = Date.now();
          const TWENTY_FOUR_HOURS = 24 * 60 * 60 * 1000;

          // If auth was checked within last 24 hours and user is authenticated, skip check
          if (
            state.lastAuthCheck &&
            state.isAuthenticated &&
            now - state.lastAuthCheck < TWENTY_FOUR_HOURS
          ) {
            console.log('[Auth] Skipping auth check - last checked within 24 hours');
            return;
          }

          set({ isLoading: true });

          const [currentUser, session] = await Promise.all([
            getCurrentUser(),
            fetchAuthSession(),
          ]);

          const tokens = session.tokens;

          if (tokens?.accessToken && tokens?.idToken) {
            set({
              user: {
                id: currentUser.userId,
                email: currentUser.signInDetails?.loginId || '',
                username: currentUser.username,
              },
              isAuthenticated: true,
              accessToken: tokens.accessToken.toString(),
              idToken: tokens.idToken.toString(),
              lastAuthCheck: now,
              isLoading: false,
              error: null,
            });
          } else {
            set({
              user: null,
              isAuthenticated: false,
              accessToken: null,
              idToken: null,
              lastAuthCheck: null,
              isLoading: false,
            });
          }
        } catch (error) {
          set({
            user: null,
            isAuthenticated: false,
            accessToken: null,
            idToken: null,
            lastAuthCheck: null,
            isLoading: false,
            error: null, // Don't set error for unauthenticated state
          });
        }
      },

      refreshTokens: async () => {
        try {
          const session = await fetchAuthSession({ forceRefresh: true });
          const tokens = session.tokens;

          if (tokens?.accessToken && tokens?.idToken) {
            set({
              accessToken: tokens.accessToken.toString(),
              idToken: tokens.idToken.toString(),
            });
          } else {
            throw new Error('Failed to refresh tokens');
          }
        } catch (error) {
          console.error('Token refresh failed:', error);
          await get().logout();
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        isAuthenticated: state.isAuthenticated,
        accessToken: state.accessToken,
        idToken: state.idToken,
        lastAuthCheck: state.lastAuthCheck,
      }),
    }
  )
);

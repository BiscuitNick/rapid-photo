import { BrowserRouter, Routes, Route, Navigate, NavLink, useLocation } from 'react-router-dom';
import { UploadPage } from './pages/UploadPage';
import { GalleryPage } from './pages/GalleryPage';
import { AuthPage } from './pages/AuthPage';
import { useAuthStore } from './stores/authStore';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/auth" state={{ from: location }} replace />;
  }

  return <>{children}</>;
}

function AppLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, user, logout } = useAuthStore();
  const location = useLocation();

  if (location.pathname === '/auth') {
    return <>{children}</>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation */}
      <nav className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex h-16 items-center justify-between">
            <div className="flex items-center gap-8">
              <h1 className="text-xl font-bold text-gray-900">RapidPhoto</h1>
              {isAuthenticated && (
                <div className="flex gap-4">
                  <NavLink
                    to="/upload"
                    className={({ isActive }) =>
                      `px-4 py-2 rounded-lg font-medium transition-colors ${
                        isActive
                          ? 'bg-blue-600 text-white'
                          : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
                      }`
                    }
                  >
                    Upload
                  </NavLink>
                  <NavLink
                    to="/gallery"
                    className={({ isActive }) =>
                      `px-4 py-2 rounded-lg font-medium transition-colors ${
                        isActive
                          ? 'bg-blue-600 text-white'
                          : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
                      }`
                    }
                  >
                    Gallery
                  </NavLink>
                </div>
              )}
            </div>
            {isAuthenticated && (
              <div className="flex items-center gap-4">
                <span className="text-sm text-gray-600">{user?.email}</span>
                <button
                  onClick={() => logout()}
                  className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-900"
                >
                  Logout
                </button>
              </div>
            )}
          </div>
        </div>
      </nav>

      {/* Content */}
      {children}
    </div>
  );
}

function App() {
  return (
    <BrowserRouter>
      <AppLayout>
        <Routes>
          <Route path="/auth" element={<AuthPage />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Navigate to="/upload" replace />
              </ProtectedRoute>
            }
          />
          <Route
            path="/upload"
            element={
              <ProtectedRoute>
                <UploadPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/gallery"
            element={
              <ProtectedRoute>
                <GalleryPage />
              </ProtectedRoute>
            }
          />
        </Routes>
      </AppLayout>
    </BrowserRouter>
  );
}

export default App;

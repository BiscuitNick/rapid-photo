import { useState } from 'react';

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col items-center justify-center p-4">
      <div className="max-w-2xl w-full bg-white rounded-lg shadow-lg p-8">
        <div className="flex flex-col items-center text-center">
          <div className="text-6xl mb-6">📸</div>
          <h1 className="text-4xl font-bold text-gray-900 mb-2">
            RapidPhoto Upload
          </h1>
          <p className="text-gray-600 mb-8">React 19 + Vite + TypeScript 5.7</p>

          <div className="w-full bg-blue-50 rounded-lg p-6 mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Features</h2>
            <ul className="text-left space-y-2 text-gray-700">
              <li>✓ Drag-and-drop upload (100 files)</li>
              <li>✓ Concurrent presigned uploads</li>
              <li>✓ Gallery with virtualized grid</li>
              <li>✓ Tag-based search</li>
              <li>✓ Batch download with in-browser ZIP</li>
            </ul>
          </div>

          <div className="flex gap-4">
            <button
              onClick={() => setCount(count => count + 1)}
              className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
            >
              Count: {count}
            </button>
            <button
              onClick={() => setCount(0)}
              className="px-6 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors font-medium"
            >
              Reset
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;

/**
 * Search and filter controls for gallery
 */

import { useState, useCallback } from 'react';

interface SearchBarProps {
  onSearchChange: (tags: string[]) => void;
  onSortChange: (sort: string) => void;
  currentSort: string;
}

export function SearchBar({ onSearchChange, onSortChange, currentSort }: SearchBarProps) {
  const [tagInput, setTagInput] = useState('');
  const [activeTags, setActiveTags] = useState<string[]>([]);

  const handleTagInputKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLInputElement>) => {
      if (e.key === 'Enter' && tagInput.trim()) {
        e.preventDefault();
        const newTag = tagInput.trim().toLowerCase();
        if (!activeTags.includes(newTag)) {
          const newTags = [...activeTags, newTag];
          setActiveTags(newTags);
          onSearchChange(newTags);
        }
        setTagInput('');
      }
    },
    [tagInput, activeTags, onSearchChange]
  );

  const handleRemoveTag = useCallback(
    (tagToRemove: string) => {
      const newTags = activeTags.filter((tag) => tag !== tagToRemove);
      setActiveTags(newTags);
      onSearchChange(newTags);
    },
    [activeTags, onSearchChange]
  );

  const handleClearAll = useCallback(() => {
    setActiveTags([]);
    setTagInput('');
    onSearchChange([]);
  }, [onSearchChange]);

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-4">
      <div className="flex gap-4 items-start">
        {/* Search input */}
        <div className="flex-1">
          <label htmlFor="tag-search" className="block text-sm font-medium text-gray-700 mb-2">
            Search by tags
          </label>
          <div className="relative">
            <input
              id="tag-search"
              type="text"
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              onKeyDown={handleTagInputKeyDown}
              placeholder="Type a tag and press Enter..."
              className="w-full px-4 py-2 pl-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <svg
              className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
          </div>

          {/* Active tags */}
          {activeTags.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-3">
              {activeTags.map((tag) => (
                <span
                  key={tag}
                  className="inline-flex items-center gap-1 px-3 py-1 bg-blue-100 text-blue-800 text-sm rounded-full"
                >
                  {tag}
                  <button
                    onClick={() => handleRemoveTag(tag)}
                    className="hover:text-blue-900 focus:outline-none"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                        clipRule="evenodd"
                      />
                    </svg>
                  </button>
                </span>
              ))}
              <button
                onClick={handleClearAll}
                className="text-sm text-gray-600 hover:text-gray-900 underline"
              >
                Clear all
              </button>
            </div>
          )}
        </div>

        {/* Sort selector */}
        <div className="w-48">
          <label htmlFor="sort-select" className="block text-sm font-medium text-gray-700 mb-2">
            Sort by
          </label>
          <select
            id="sort-select"
            value={currentSort}
            onChange={(e) => onSortChange(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="createdAt,desc">Newest first</option>
            <option value="createdAt,asc">Oldest first</option>
            <option value="fileName,asc">Name (A-Z)</option>
            <option value="fileName,desc">Name (Z-A)</option>
          </select>
        </div>
      </div>
    </div>
  );
}

'use client'

import { MagnifyingGlassIcon, FunnelIcon } from '@heroicons/react/24/outline'

interface SearchFilterBarProps {
  searchQuery: string
  onSearchChange: (query: string) => void
  placeholder?: string
  showFilters?: boolean
  onFilterClick?: () => void
  filterCount?: number
  rightContent?: React.ReactNode
}

export function SearchFilterBar({
  searchQuery,
  onSearchChange,
  placeholder = 'Search...',
  showFilters = false,
  onFilterClick,
  filterCount = 0,
  rightContent,
}: SearchFilterBarProps) {
  return (
    <div className="flex gap-4 mb-6">
      <div className="flex-1 relative">
        <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-[var(--text-secondary)]" />
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder={placeholder}
          className="w-full pl-10 pr-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)] focus:outline-none focus:ring-2 focus:ring-purple-500"
        />
      </div>
      {showFilters && onFilterClick && (
        <button
          onClick={onFilterClick}
          className="px-4 py-2 bg-[var(--bg-secondary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)] hover:bg-[var(--bg-tertiary)] flex items-center gap-2"
        >
          <FunnelIcon className="h-5 w-5" />
          Filters
          {filterCount > 0 && (
            <span className="bg-purple-500 text-white text-xs rounded-full px-2 py-0.5">
              {filterCount}
            </span>
          )}
        </button>
      )}
      {rightContent}
    </div>
  )
}


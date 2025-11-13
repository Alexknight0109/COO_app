import { useState, useMemo } from 'react'

export interface SortConfig<T> {
  key: keyof T
  direction: 'asc' | 'desc'
}

export interface FilterConfig<T> {
  [key: string]: any
}

export function useListControls<T extends Record<string, any>>(
  items: T[],
  searchFields: (keyof T)[]
) {
  const [searchQuery, setSearchQuery] = useState('')
  const [sortConfig, setSortConfig] = useState<SortConfig<T> | null>(null)
  const [filters, setFilters] = useState<FilterConfig<T>>({})
  const [currentPage, setCurrentPage] = useState(1)
  const [itemsPerPage, setItemsPerPage] = useState(25)

  // Filter and search
  const filteredItems = useMemo(() => {
    let result = items

    // Apply search
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase()
      result = result.filter((item) =>
        searchFields.some((field) => {
          const value = item[field]
          return value && String(value).toLowerCase().includes(query)
        })
      )
    }

    // Apply filters
    Object.keys(filters).forEach((key) => {
      const filterValue = filters[key]
      if (filterValue !== null && filterValue !== undefined && filterValue !== '') {
        result = result.filter((item) => {
          const itemValue = item[key]
          if (Array.isArray(filterValue)) {
            return filterValue.includes(itemValue)
          }
          return itemValue === filterValue
        })
      }
    })

    return result
  }, [items, searchQuery, filters, searchFields])

  // Sort
  const sortedItems = useMemo(() => {
    if (!sortConfig) return filteredItems

    return [...filteredItems].sort((a, b) => {
      const aValue = a[sortConfig.key]
      const bValue = b[sortConfig.key]

      if (aValue === null || aValue === undefined) return 1
      if (bValue === null || bValue === undefined) return -1

      if (typeof aValue === 'string' && typeof bValue === 'string') {
        return sortConfig.direction === 'asc'
          ? aValue.localeCompare(bValue)
          : bValue.localeCompare(aValue)
      }

      if (typeof aValue === 'number' && typeof bValue === 'number') {
        return sortConfig.direction === 'asc' ? aValue - bValue : bValue - aValue
      }

      return 0
    })
  }, [filteredItems, sortConfig])

  // Paginate
  const paginatedItems = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage
    return sortedItems.slice(startIndex, startIndex + itemsPerPage)
  }, [sortedItems, currentPage, itemsPerPage])

  const totalPages = Math.ceil(sortedItems.length / itemsPerPage)

  const handleSort = (key: keyof T) => {
    setSortConfig((current) => {
      if (current?.key === key) {
        return {
          key,
          direction: current.direction === 'asc' ? 'desc' : 'asc',
        }
      }
      return { key, direction: 'asc' }
    })
    setCurrentPage(1) // Reset to first page on sort
  }

  const handleFilterChange = (key: keyof T, value: any) => {
    setFilters((current) => ({
      ...current,
      [key]: value,
    }))
    setCurrentPage(1) // Reset to first page on filter
  }

  const clearFilters = () => {
    setFilters({})
    setSearchQuery('')
    setCurrentPage(1)
  }

  const activeFilterCount = Object.values(filters).filter(
    (v) => v !== null && v !== undefined && v !== ''
  ).length

  return {
    searchQuery,
    setSearchQuery,
    sortConfig,
    handleSort,
    filters,
    handleFilterChange,
    clearFilters,
    activeFilterCount,
    currentPage,
    setCurrentPage,
    itemsPerPage,
    setItemsPerPage,
    paginatedItems,
    totalPages,
    totalItems: sortedItems.length,
    filteredCount: filteredItems.length,
  }
}


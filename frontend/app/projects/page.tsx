'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { projectsApi, Project, CreateProjectDto } from '@/lib/api/projects'
import toast from 'react-hot-toast'
import { PlusIcon, PencilIcon, TrashIcon, ArrowUpIcon, ArrowDownIcon } from '@heroicons/react/24/outline'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'
import { FormField } from '@/components/ui/FormField'
import { SearchFilterBar } from '@/components/ui/SearchFilterBar'
import { Pagination } from '@/components/ui/Pagination'
import { useListControls } from '@/lib/hooks/useListControls'
import { validateForm, ValidationRule } from '@/lib/utils/validation'

export default function ProjectsPage() {
  const [projects, setProjects] = useState<Project[]>([])
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [editingProject, setEditingProject] = useState<Project | null>(null)
  const [formData, setFormData] = useState<CreateProjectDto>({
    name: '',
    description: '',
    poNumber: '',
    poValue: 0,
    status: 'PLANNING',
    startDate: '',
    endDate: '',
  })
  const [formErrors, setFormErrors] = useState<Record<string, string>>({})
  const [showFilters, setShowFilters] = useState(false)

  // List controls
  const {
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
    totalItems,
  } = useListControls<Project>(projects, ['name', 'description', 'poNumber', 'status'])

  useEffect(() => {
    loadProjects()
  }, [])

  const loadProjects = async () => {
    try {
      setLoading(true)
      const data = await projectsApi.getAll()
      setProjects(data)
    } catch (error: any) {
      console.error('Failed to load projects:', error)
      const errorMessage = error?.response?.data?.message || error?.message || 'Failed to load projects. Please try again.'
      toast.error(errorMessage)
    } finally {
      setLoading(false)
    }
  }

  const validationRules: Record<string, ValidationRule> = {
    name: { required: true, minLength: 3, maxLength: 100 },
    description: { maxLength: 500 },
    poNumber: { maxLength: 50 },
    poValue: { number: true, min: 0 },
    startDate: {
      custom: (value) => {
        if (formData.endDate && value && new Date(value) > new Date(formData.endDate)) {
          return 'Start date must be before end date'
        }
        return null
      },
    },
    endDate: {
      custom: (value) => {
        if (formData.startDate && value && new Date(value) < new Date(formData.startDate)) {
          return 'End date must be after start date'
        }
        return null
      },
    },
  }

  const getStatusColor = (status: string) => {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
        return 'bg-green-500/20 text-green-400'
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        return 'bg-blue-500/20 text-blue-400'
      case 'PLANNING':
        return 'bg-yellow-500/20 text-yellow-400'
      default:
        return 'bg-gray-500/20 text-gray-400'
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    // Validate form
    const errors = validateForm(formData, validationRules)
    setFormErrors(errors)
    
    if (Object.keys(errors).length > 0) {
      toast.error('Please fix the errors in the form')
      return
    }

    try {
      setSubmitting(true)
      if (editingProject) {
        await projectsApi.update(editingProject.id, formData)
        toast.success('Project updated successfully')
      } else {
        await projectsApi.create(formData)
        toast.success('Project created successfully')
      }
      setShowForm(false)
      setEditingProject(null)
      setFormErrors({})
      setFormData({
        name: '',
        description: '',
        poNumber: '',
        poValue: 0,
        status: 'PLANNING',
        startDate: '',
        endDate: '',
      })
      loadProjects()
    } catch (error: any) {
      console.error('Failed to save project:', error)
      const errorMessage = error?.response?.data?.message || error?.message || 'Failed to save project. Please try again.'
      toast.error(errorMessage)
    } finally {
      setSubmitting(false)
    }
  }

  const handleEdit = (project: Project) => {
    setEditingProject(project)
    setFormData({
      name: project.name,
      description: project.description || '',
      poNumber: project.poNumber || '',
      poValue: project.poValue || 0,
      status: project.status || 'PLANNING',
      startDate: project.startDate?.split('T')[0] || '',
      endDate: project.endDate?.split('T')[0] || '',
    })
    setShowForm(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this project? This action cannot be undone.')) return
    try {
      await projectsApi.delete(id)
      toast.success('Project deleted successfully')
      loadProjects()
    } catch (error: any) {
      console.error('Failed to delete project:', error)
      const errorMessage = error?.response?.data?.message || error?.message || 'Failed to delete project. Please try again.'
      toast.error(errorMessage)
    }
  }

  const handleFieldChange = (field: string, value: any) => {
    setFormData({ ...formData, [field]: value })
    // Clear error for this field when user starts typing
    if (formErrors[field]) {
      setFormErrors({ ...formErrors, [field]: '' })
    }
  }

  const getSortIcon = (field: keyof Project) => {
    if (sortConfig?.key !== field) return null
    return sortConfig.direction === 'asc' ? (
      <ArrowUpIcon className="w-4 h-4 inline ml-1" />
    ) : (
      <ArrowDownIcon className="w-4 h-4 inline ml-1" />
    )
  }

  const totalPOValue = projects.reduce((sum, p) => sum + (p.poValue || 0), 0)
  const activeProjects = projects.filter((p) => 
    p.status?.toUpperCase() === 'IN_PROGRESS' || p.status?.toUpperCase() === 'INPROGRESS'
  ).length

  return (
    <ProtectedRoute>
      <div className="flex min-h-screen">
        <Sidebar />
        <div className="flex-1 ml-64">
          <Header />
          <main className="p-6">
            <div className="mb-6 flex items-center justify-between">
              <div>
                <h1 className="text-3xl font-bold text-[var(--text-primary)] mb-2">
                  Projects & Sites
                </h1>
                <p className="text-[var(--text-secondary)]">
                  Manage all projects and site locations
                </p>
              </div>
              <button
                onClick={() => {
                  setShowForm(true)
                  setEditingProject(null)
                  setFormData({
                    name: '',
                    description: '',
                    poNumber: '',
                    poValue: 0,
                    status: 'PLANNING',
                    startDate: '',
                    endDate: '',
                  })
                }}
                className="flex items-center gap-2 px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
              >
                <PlusIcon className="w-5 h-5" />
                New Project
              </button>
            </div>

            {showForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingProject ? 'Edit Project' : 'Create Project'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleSubmit} className="space-y-4">
                    <FormField label="Project Name" required error={formErrors.name}>
                      <input
                        type="text"
                        value={formData.name}
                        onChange={(e) => handleFieldChange('name', e.target.value)}
                        className={`w-full px-4 py-2 bg-[var(--bg-primary)] border ${
                          formErrors.name ? 'border-red-500' : 'border-[var(--border-color)]'
                        } rounded-lg text-[var(--text-primary)] focus:outline-none focus:ring-2 focus:ring-purple-500`}
                      />
                    </FormField>
                    <FormField label="Description" error={formErrors.description}>
                      <textarea
                        value={formData.description}
                        onChange={(e) => handleFieldChange('description', e.target.value)}
                        className={`w-full px-4 py-2 bg-[var(--bg-primary)] border ${
                          formErrors.description ? 'border-red-500' : 'border-[var(--border-color)]'
                        } rounded-lg text-[var(--text-primary)] focus:outline-none focus:ring-2 focus:ring-purple-500`}
                        rows={3}
                      />
                    </FormField>
                    <div className="grid grid-cols-2 gap-4">
                      <FormField label="PO Number" error={formErrors.poNumber}>
                        <input
                          type="text"
                          value={formData.poNumber}
                          onChange={(e) => handleFieldChange('poNumber', e.target.value)}
                          className={`w-full px-4 py-2 bg-[var(--bg-primary)] border ${
                            formErrors.poNumber ? 'border-red-500' : 'border-[var(--border-color)]'
                          } rounded-lg text-[var(--text-primary)] focus:outline-none focus:ring-2 focus:ring-purple-500`}
                        />
                      </FormField>
                      <FormField label="PO Value" error={formErrors.poValue}>
                        <input
                          type="number"
                          value={formData.poValue}
                          onChange={(e) => handleFieldChange('poValue', Number(e.target.value))}
                          min={0}
                          step="0.01"
                          className={`w-full px-4 py-2 bg-[var(--bg-primary)] border ${
                            formErrors.poValue ? 'border-red-500' : 'border-[var(--border-color)]'
                          } rounded-lg text-[var(--text-primary)] focus:outline-none focus:ring-2 focus:ring-purple-500`}
                        />
                      </FormField>
                    </div>
                    <div className="grid grid-cols-3 gap-4">
                      <FormField label="Status">
                        <select
                          value={formData.status}
                          onChange={(e) => handleFieldChange('status', e.target.value)}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)] focus:outline-none focus:ring-2 focus:ring-purple-500"
                        >
                          <option value="PLANNING">Planning</option>
                          <option value="IN_PROGRESS">In Progress</option>
                          <option value="COMPLETED">Completed</option>
                          <option value="ON_HOLD">On Hold</option>
                        </select>
                      </FormField>
                      <FormField label="Start Date" error={formErrors.startDate}>
                        <input
                          type="date"
                          value={formData.startDate}
                          onChange={(e) => handleFieldChange('startDate', e.target.value)}
                          className={`w-full px-4 py-2 bg-[var(--bg-primary)] border ${
                            formErrors.startDate ? 'border-red-500' : 'border-[var(--border-color)]'
                          } rounded-lg text-[var(--text-primary)] focus:outline-none focus:ring-2 focus:ring-purple-500`}
                        />
                      </FormField>
                      <FormField label="End Date" error={formErrors.endDate}>
                        <input
                          type="date"
                          value={formData.endDate}
                          onChange={(e) => handleFieldChange('endDate', e.target.value)}
                          className={`w-full px-4 py-2 bg-[var(--bg-primary)] border ${
                            formErrors.endDate ? 'border-red-500' : 'border-[var(--border-color)]'
                          } rounded-lg text-[var(--text-primary)] focus:outline-none focus:ring-2 focus:ring-purple-500`}
                        />
                      </FormField>
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        disabled={submitting}
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                      >
                        {submitting && <LoadingSpinner size="sm" />}
                        {editingProject ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowForm(false)
                          setEditingProject(null)
                          setFormErrors({})
                        }}
                        disabled={submitting}
                        className="px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)] disabled:opacity-50"
                      >
                        Cancel
                      </button>
                    </div>
                  </form>
                </CardContent>
              </Card>
            )}

            {loading ? (
              <div className="flex items-center justify-center py-12">
                <LoadingSpinner size="lg" />
              </div>
            ) : (
              <>
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
                  <Card hover>
                    <CardHeader>
                      <CardTitle className="text-sm font-medium text-[var(--text-secondary)]">
                        Total Projects
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-3xl font-bold text-[var(--text-primary)]">
                        {projects.length}
                      </p>
                    </CardContent>
                  </Card>
                  <Card hover>
                    <CardHeader>
                      <CardTitle className="text-sm font-medium text-[var(--text-secondary)]">
                        Active Projects
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-3xl font-bold text-blue-400">
                        {activeProjects}
                      </p>
                    </CardContent>
                  </Card>
                  <Card hover>
                    <CardHeader>
                      <CardTitle className="text-sm font-medium text-[var(--text-secondary)]">
                        Total PO Value
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-3xl font-bold text-green-400">
                        ${totalPOValue.toLocaleString()}
                      </p>
                    </CardContent>
                  </Card>
                </div>

                <SearchFilterBar
                  searchQuery={searchQuery}
                  onSearchChange={setSearchQuery}
                  placeholder="Search projects by name, description, PO number, or status..."
                  showFilters={true}
                  onFilterClick={() => setShowFilters(!showFilters)}
                  filterCount={activeFilterCount}
                  rightContent={
                    activeFilterCount > 0 && (
                      <button
                        onClick={clearFilters}
                        className="px-4 py-2 text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
                      >
                        Clear Filters
                      </button>
                    )
                  }
                />

                {showFilters && (
                  <Card className="mb-6">
                    <CardContent className="pt-6">
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div>
                          <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                            Filter by Status
                          </label>
                          <select
                            value={filters.status || ''}
                            onChange={(e) => handleFilterChange('status', e.target.value || null)}
                            className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                          >
                            <option value="">All Statuses</option>
                            <option value="PLANNING">Planning</option>
                            <option value="IN_PROGRESS">In Progress</option>
                            <option value="COMPLETED">Completed</option>
                            <option value="ON_HOLD">On Hold</option>
                          </select>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                )}

                <Card className="mb-6">
                  <CardContent className="p-0">
                    <div className="overflow-x-auto">
                      <table className="w-full">
                        <thead className="bg-[var(--bg-secondary)]">
                          <tr>
                            <th
                              className="px-6 py-3 text-left text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider cursor-pointer hover:bg-[var(--bg-tertiary)]"
                              onClick={() => handleSort('name')}
                            >
                              <div className="flex items-center">
                                Project Name
                                {getSortIcon('name')}
                              </div>
                            </th>
                            <th
                              className="px-6 py-3 text-left text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider cursor-pointer hover:bg-[var(--bg-tertiary)]"
                              onClick={() => handleSort('poValue')}
                            >
                              <div className="flex items-center">
                                PO Value
                                {getSortIcon('poValue')}
                              </div>
                            </th>
                            <th
                              className="px-6 py-3 text-left text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider cursor-pointer hover:bg-[var(--bg-tertiary)]"
                              onClick={() => handleSort('status')}
                            >
                              <div className="flex items-center">
                                Status
                                {getSortIcon('status')}
                              </div>
                            </th>
                            <th
                              className="px-6 py-3 text-left text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider cursor-pointer hover:bg-[var(--bg-tertiary)]"
                              onClick={() => handleSort('startDate')}
                            >
                              <div className="flex items-center">
                                Start Date
                                {getSortIcon('startDate')}
                              </div>
                            </th>
                            <th className="px-6 py-3 text-right text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                              Actions
                            </th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-[var(--border-color)]">
                          {paginatedItems.length === 0 ? (
                            <tr>
                              <td colSpan={5} className="px-6 py-12 text-center">
                                <p className="text-[var(--text-secondary)]">
                                  {searchQuery || activeFilterCount > 0
                                    ? 'No projects match your search criteria.'
                                    : 'No projects found. Create your first project!'}
                                </p>
                              </td>
                            </tr>
                          ) : (
                            paginatedItems.map((project) => (
                              <tr key={project.id} className="hover:bg-[var(--bg-secondary)]">
                                <td className="px-6 py-4 whitespace-nowrap">
                                  <div>
                                    <div className="text-sm font-medium text-[var(--text-primary)]">
                                      {project.name}
                                    </div>
                                    {project.poNumber && (
                                      <div className="text-sm text-[var(--text-secondary)]">
                                        PO: {project.poNumber}
                                      </div>
                                    )}
                                    {project.description && (
                                      <div className="text-xs text-[var(--text-secondary)] mt-1 line-clamp-1">
                                        {project.description}
                                      </div>
                                    )}
                                  </div>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  <div className="text-sm text-[var(--text-primary)]">
                                    {project.poValue ? `$${project.poValue.toLocaleString()}` : '-'}
                                  </div>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  {project.status && (
                                    <span
                                      className={`px-3 py-1 rounded-full text-sm ${getStatusColor(
                                        project.status
                                      )}`}
                                    >
                                      {project.status.replace('_', ' ')}
                                    </span>
                                  )}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                  <div className="text-sm text-[var(--text-primary)]">
                                    {project.startDate
                                      ? new Date(project.startDate).toLocaleDateString()
                                      : '-'}
                                  </div>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                  <div className="flex items-center justify-end gap-2">
                                    <button
                                      onClick={() => handleEdit(project)}
                                      className="p-2 hover:bg-purple-500/20 rounded"
                                      title="Edit"
                                    >
                                      <PencilIcon className="w-4 h-4 text-purple-400" />
                                    </button>
                                    <button
                                      onClick={() => handleDelete(project.id)}
                                      className="p-2 hover:bg-red-500/20 rounded"
                                      title="Delete"
                                    >
                                      <TrashIcon className="w-4 h-4 text-red-400" />
                                    </button>
                                  </div>
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </CardContent>
                </Card>

                {totalItems > 0 && (
                  <Pagination
                    currentPage={currentPage}
                    totalPages={totalPages}
                    onPageChange={setCurrentPage}
                    itemsPerPage={itemsPerPage}
                    totalItems={totalItems}
                    onItemsPerPageChange={setItemsPerPage}
                  />
                )}
              </>
            )}
          </main>
        </div>
      </div>
    </ProtectedRoute>
  )
}

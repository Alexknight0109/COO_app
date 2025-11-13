'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { sitesApi, Site, SiteLog } from '@/lib/api/sites'
import { FileUpload } from '@/components/ui/FileUpload'
import toast from 'react-hot-toast'
import { PlusIcon, PencilIcon, TrashIcon, MapPinIcon } from '@heroicons/react/24/outline'
import { format } from 'date-fns'

export default function SiteLogsPage() {
  const [sites, setSites] = useState<Site[]>([])
  const [selectedSite, setSelectedSite] = useState<Site | null>(null)
  const [logs, setLogs] = useState<SiteLog[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [showSiteForm, setShowSiteForm] = useState(false)
  const [editingSite, setEditingSite] = useState<Site | null>(null)
  const [formData, setFormData] = useState({
    workDone: '',
    materialsNeeded: '',
    issues: '',
    photos: [] as string[],
  })
  const [siteFormData, setSiteFormData] = useState({
    name: '',
    address: '',
    status: 'ACTIVE',
  })

  useEffect(() => {
    loadSites()
  }, [])

  useEffect(() => {
    if (selectedSite) {
      loadLogs(selectedSite.id)
    }
  }, [selectedSite])

  const loadSites = async () => {
    try {
      setLoading(true)
      const data = await sitesApi.getAll()
      setSites(data)
      if (data.length > 0 && !selectedSite) {
        setSelectedSite(data[0])
      }
    } catch (error: any) {
      console.error('Failed to load sites:', error)
      const errorMessage = error?.response?.data?.message || error?.message || 'Failed to load sites. Please check if the backend is running.'
      toast.error(errorMessage)
    } finally {
      setLoading(false)
    }
  }

  const loadLogs = async (siteId: string) => {
    try {
      const data = await sitesApi.getLogs(siteId)
      setLogs(data)
    } catch (error: any) {
      console.error('Failed to load logs:', error)
      const errorMessage = error?.response?.data?.message || error?.message || 'Failed to load logs. Please try again.'
      toast.error(errorMessage)
    }
  }

  const handleLogSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedSite) return
    try {
      await sitesApi.createLog({
        siteId: selectedSite.id,
        ...formData,
      })
      toast.success('Log created successfully')
      setShowForm(false)
      setFormData({ workDone: '', materialsNeeded: '', issues: '', photos: [] })
      loadLogs(selectedSite.id)
    } catch (error: any) {
      console.error('Failed to create log:', error)
      const errorMessage = error?.response?.data?.message || error?.message || 'Failed to create log. Please try again.'
      toast.error(errorMessage)
    }
  }

  const handleSiteSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingSite) {
        await sitesApi.update(editingSite.id, siteFormData)
        toast.success('Site updated successfully')
      } else {
        await sitesApi.create(siteFormData)
        toast.success('Site created successfully')
      }
      setShowSiteForm(false)
      setEditingSite(null)
      setSiteFormData({ name: '', address: '', status: 'ACTIVE' })
      loadSites()
    } catch (error: any) {
      console.error('Failed to save site:', error)
      const errorMessage = error?.response?.data?.message || error?.message || 'Failed to save site. Please try again.'
      toast.error(errorMessage)
    }
  }

  const handleDeleteSite = async (id: string) => {
    if (!confirm('Are you sure you want to delete this site? This action cannot be undone.')) return
    try {
      await sitesApi.delete(id)
      toast.success('Site deleted successfully')
      if (selectedSite?.id === id) {
        setSelectedSite(null)
        setLogs([])
      }
      loadSites()
    } catch (error: any) {
      console.error('Failed to delete site:', error)
      const errorMessage = error?.response?.data?.message || error?.message || 'Failed to delete site. Please try again.'
      toast.error(errorMessage)
    }
  }

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
                  Daily Site Logs
                </h1>
                <p className="text-[var(--text-secondary)]">
                  Track daily work done at sites
                </p>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => {
                    setShowSiteForm(true)
                    setEditingSite(null)
                    setSiteFormData({ name: '', address: '', status: 'ACTIVE' })
                  }}
                  className="flex items-center gap-2 px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)] hover:border-purple-500"
                >
                  <PlusIcon className="w-5 h-5" />
                  New Site
                </button>
                {selectedSite && (
                  <button
                    onClick={() => setShowForm(true)}
                    className="flex items-center gap-2 px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                  >
                    <PlusIcon className="w-5 h-5" />
                    New Log
                  </button>
                )}
              </div>
            </div>

            {showSiteForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingSite ? 'Edit Site' : 'Create Site'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleSiteSubmit} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Site Name *
                      </label>
                      <input
                        type="text"
                        value={siteFormData.name}
                        onChange={(e) => setSiteFormData({ ...siteFormData, name: e.target.value })}
                        required
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Address
                      </label>
                      <input
                        type="text"
                        value={siteFormData.address}
                        onChange={(e) => setSiteFormData({ ...siteFormData, address: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      />
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        {editingSite ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowSiteForm(false)
                          setEditingSite(null)
                        }}
                        className="px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      >
                        Cancel
                      </button>
                    </div>
                  </form>
                </CardContent>
              </Card>
            )}

            {showForm && selectedSite && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>Create Site Log - {selectedSite.name}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleLogSubmit} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Work Done
                      </label>
                      <textarea
                        value={formData.workDone}
                        onChange={(e) => setFormData({ ...formData, workDone: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        rows={4}
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Materials Needed
                      </label>
                      <textarea
                        value={formData.materialsNeeded}
                        onChange={(e) => setFormData({ ...formData, materialsNeeded: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        rows={3}
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Issues
                      </label>
                      <textarea
                        value={formData.issues}
                        onChange={(e) => setFormData({ ...formData, issues: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        rows={3}
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Photos
                      </label>
                      <FileUpload
                        onUpload={(urls) => setFormData({ ...formData, photos: urls })}
                        multiple
                        accept="image/*"
                        folder="site-logs"
                      />
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        Create Log
                      </button>
                      <button
                        type="button"
                        onClick={() => setShowForm(false)}
                        className="px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
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
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500"></div>
              </div>
            ) : (
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div>
                  <Card>
                    <CardHeader>
                      <CardTitle>Sites</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {sites.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">No sites found</p>
                      ) : (
                        <div className="space-y-2">
                          {sites.map((site) => (
                            <button
                              key={site.id}
                              onClick={() => setSelectedSite(site)}
                              className={`w-full p-3 rounded-lg text-left transition-colors ${
                                selectedSite?.id === site.id
                                  ? 'bg-gradient-purple-blue/20 border border-purple-500/50'
                                  : 'hover:bg-[var(--hover-bg)] border border-transparent'
                              }`}
                            >
                              <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                  <MapPinIcon className="w-5 h-5 text-purple-400" />
                                  <div>
                                    <h3 className="font-medium text-[var(--text-primary)]">{site.name}</h3>
                                    {site.address && (
                                      <p className="text-xs text-[var(--text-secondary)]">{site.address}</p>
                                    )}
                                  </div>
                                </div>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation()
                                    setEditingSite(site)
                                    setSiteFormData({
                                      name: site.name,
                                      address: site.address || '',
                                      status: site.status || 'ACTIVE',
                                    })
                                    setShowSiteForm(true)
                                  }}
                                  className="p-1 hover:bg-purple-500/20 rounded"
                                >
                                  <PencilIcon className="w-4 h-4 text-purple-400" />
                                </button>
                              </div>
                            </button>
                          ))}
                        </div>
                      )}
                    </CardContent>
                  </Card>
                </div>

                <div className="lg:col-span-2">
                  <Card>
                    <CardHeader>
                      <CardTitle>
                        Logs {selectedSite && `- ${selectedSite.name}`}
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      {!selectedSite ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">
                          Select a site to view logs
                        </p>
                      ) : logs.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">No logs found</p>
                      ) : (
                        <div className="space-y-4">
                          {logs.map((log) => (
                            <div
                              key={log.id}
                              className="p-4 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)]"
                            >
                              <div className="mb-2">
                                <p className="text-xs text-[var(--text-secondary)]">
                                  {format(new Date(log.createdAt), 'MMM d, yyyy h:mm a')}
                                </p>
                              </div>
                              {log.workDone && (
                                <div className="mb-2">
                                  <h4 className="text-sm font-medium text-[var(--text-primary)] mb-1">
                                    Work Done:
                                  </h4>
                                  <p className="text-sm text-[var(--text-secondary)]">{log.workDone}</p>
                                </div>
                              )}
                              {log.materialsNeeded && (
                                <div className="mb-2">
                                  <h4 className="text-sm font-medium text-[var(--text-primary)] mb-1">
                                    Materials Needed:
                                  </h4>
                                  <p className="text-sm text-[var(--text-secondary)]">{log.materialsNeeded}</p>
                                </div>
                              )}
                              {log.issues && (
                                <div className="mb-2">
                                  <h4 className="text-sm font-medium text-[var(--text-primary)] mb-1">
                                    Issues:
                                  </h4>
                                  <p className="text-sm text-[var(--text-secondary)]">{log.issues}</p>
                                </div>
                              )}
                              {log.photos && log.photos.length > 0 && (
                                <div className="mt-2">
                                  <h4 className="text-sm font-medium text-[var(--text-primary)] mb-2">
                                    Photos:
                                  </h4>
                                  <div className="grid grid-cols-3 gap-2">
                                    {log.photos.map((photo, idx) => (
                                      <img
                                        key={idx}
                                        src={photo}
                                        alt={`Photo ${idx + 1}`}
                                        className="w-full h-24 object-cover rounded"
                                      />
                                    ))}
                                  </div>
                                </div>
                              )}
                            </div>
                          ))}
                        </div>
                      )}
                    </CardContent>
                  </Card>
                </div>
              </div>
            )}
          </main>
        </div>
      </div>
    </ProtectedRoute>
  )
}

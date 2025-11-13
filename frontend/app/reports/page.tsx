'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { reportsApi, Report } from '@/lib/api/reports'
import { FileUpload } from '@/components/ui/FileUpload'
import toast from 'react-hot-toast'
import { PlusIcon, PencilIcon, TrashIcon, DocumentIcon } from '@heroicons/react/24/outline'
import { format } from 'date-fns'

export default function ReportsPage() {
  const [reports, setReports] = useState<Report[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editingReport, setEditingReport] = useState<Report | null>(null)
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    type: 'DAILY' as 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'SITE' | 'FACTORY' | 'SALES' | 'OTHER',
    fileUrl: '',
  })

  useEffect(() => {
    loadReports()
  }, [])

  const loadReports = async () => {
    try {
      setLoading(true)
      const data = await reportsApi.getAll()
      setReports(data)
    } catch (error) {
      console.error('Failed to load reports:', error)
      toast.error('Failed to load reports')
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingReport) {
        await reportsApi.update(editingReport.id, formData)
        toast.success('Report updated')
      } else {
        await reportsApi.create(formData)
        toast.success('Report created')
      }
      setShowForm(false)
      setEditingReport(null)
      setFormData({
        title: '',
        description: '',
        type: 'DAILY',
        fileUrl: '',
      })
      loadReports()
    } catch (error) {
      toast.error('Failed to save report')
    }
  }

  const handleEdit = (report: Report) => {
    setEditingReport(report)
    setFormData({
      title: report.title,
      description: report.description || '',
      type: report.type,
      fileUrl: report.fileUrl || '',
    })
    setShowForm(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this report?')) return
    try {
      await reportsApi.delete(id)
      toast.success('Report deleted')
      loadReports()
    } catch (error) {
      toast.error('Failed to delete report')
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
                  Reports
                </h1>
                <p className="text-[var(--text-secondary)]">
                  View and export company reports
                </p>
              </div>
              <button
                onClick={() => {
                  setShowForm(true)
                  setEditingReport(null)
                  setFormData({
                    title: '',
                    description: '',
                    type: 'DAILY',
                    fileUrl: '',
                  })
                }}
                className="flex items-center gap-2 px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
              >
                <PlusIcon className="w-5 h-5" />
                New Report
              </button>
            </div>

            {showForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingReport ? 'Edit Report' : 'Create Report'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Title *
                      </label>
                      <input
                        type="text"
                        value={formData.title}
                        onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                        required
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Description
                      </label>
                      <textarea
                        value={formData.description}
                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        rows={4}
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Type *
                        </label>
                        <select
                          value={formData.type}
                          onChange={(e) => setFormData({ ...formData, type: e.target.value as any })}
                          required
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        >
                          <option value="DAILY">Daily</option>
                          <option value="WEEKLY">Weekly</option>
                          <option value="MONTHLY">Monthly</option>
                          <option value="SITE">Site</option>
                          <option value="FACTORY">Factory</option>
                          <option value="SALES">Sales</option>
                          <option value="OTHER">Other</option>
                        </select>
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Upload File
                      </label>
                      <FileUpload
                        onUpload={(urls) => setFormData({ ...formData, fileUrl: urls[0] || '' })}
                        accept=".pdf,.doc,.docx,.xls,.xlsx"
                        folder="reports"
                      />
                      {formData.fileUrl && (
                        <a
                          href={formData.fileUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="mt-2 text-sm text-purple-400 hover:text-purple-300"
                        >
                          View uploaded file
                        </a>
                      )}
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        {editingReport ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowForm(false)
                          setEditingReport(null)
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

            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500"></div>
              </div>
            ) : (
              <div className="grid grid-cols-1 gap-4">
                {reports.length === 0 ? (
                  <Card>
                    <CardContent className="py-12 text-center">
                      <p className="text-[var(--text-secondary)]">No reports found</p>
                    </CardContent>
                  </Card>
                ) : (
                  reports.map((report) => (
                    <Card key={report.id} hover>
                      <CardHeader>
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-3">
                            <DocumentIcon className="w-6 h-6 text-purple-400" />
                            <div>
                              <CardTitle>{report.title}</CardTitle>
                              {report.createdByUser && (
                                <p className="text-sm text-[var(--text-secondary)] mt-1">
                                  By: {report.createdByUser.firstName} {report.createdByUser.lastName}
                                </p>
                              )}
                            </div>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="px-3 py-1 bg-purple-500/20 text-purple-400 rounded-full text-sm">
                              {report.type}
                            </span>
                            <button
                              onClick={() => handleEdit(report)}
                              className="p-2 hover:bg-purple-500/20 rounded"
                            >
                              <PencilIcon className="w-4 h-4 text-purple-400" />
                            </button>
                            <button
                              onClick={() => handleDelete(report.id)}
                              className="p-2 hover:bg-red-500/20 rounded"
                            >
                              <TrashIcon className="w-4 h-4 text-red-400" />
                            </button>
                          </div>
                        </div>
                      </CardHeader>
                      <CardContent>
                        {report.description && (
                          <p className="text-sm text-[var(--text-secondary)] mb-4">{report.description}</p>
                        )}
                        <div className="flex items-center gap-4 text-sm text-[var(--text-secondary)]">
                          <span>Created: {format(new Date(report.createdAt), 'MMM d, yyyy')}</span>
                          {report.fileUrl && (
                            <a
                              href={report.fileUrl}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-purple-400 hover:text-purple-300"
                            >
                              Download File
                            </a>
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  ))
                )}
              </div>
            )}
          </main>
        </div>
      </div>
    </ProtectedRoute>
  )
}

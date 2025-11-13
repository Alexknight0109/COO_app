'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { complaintsApi, Complaint } from '@/lib/api/complaints'
import { FileUpload } from '@/components/ui/FileUpload'
import toast from 'react-hot-toast'
import { PlusIcon, PencilIcon, TrashIcon } from '@heroicons/react/24/outline'
import { format } from 'date-fns'

export default function ComplaintsPage() {
  const [complaints, setComplaints] = useState<Complaint[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editingComplaint, setEditingComplaint] = useState<Complaint | null>(null)
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    priority: 'MEDIUM' as 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT',
    customerName: '',
    customerContact: '',
    photos: [] as string[],
  })

  useEffect(() => {
    loadComplaints()
  }, [])

  const loadComplaints = async () => {
    try {
      setLoading(true)
      const data = await complaintsApi.getAll()
      setComplaints(data)
    } catch (error) {
      console.error('Failed to load complaints:', error)
      toast.error('Failed to load complaints')
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingComplaint) {
        await complaintsApi.update(editingComplaint.id, formData)
        toast.success('Complaint updated')
      } else {
        await complaintsApi.create(formData)
        toast.success('Complaint created')
      }
      setShowForm(false)
      setEditingComplaint(null)
      setFormData({
        title: '',
        description: '',
        priority: 'MEDIUM',
        customerName: '',
        customerContact: '',
        photos: [],
      })
      loadComplaints()
    } catch (error) {
      toast.error('Failed to save complaint')
    }
  }

  const handleEdit = (complaint: Complaint) => {
    setEditingComplaint(complaint)
    setFormData({
      title: complaint.title,
      description: complaint.description || '',
      priority: complaint.priority || 'MEDIUM',
      customerName: complaint.customerName || '',
      customerContact: complaint.customerContact || '',
      photos: complaint.photos || [],
    })
    setShowForm(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this complaint?')) return
    try {
      await complaintsApi.delete(id)
      toast.success('Complaint deleted')
      loadComplaints()
    } catch (error) {
      toast.error('Failed to delete complaint')
    }
  }

  const handleStatusChange = async (id: string, status: Complaint['status']) => {
    try {
      await complaintsApi.updateStatus(id, status)
      toast.success('Status updated')
      loadComplaints()
    } catch (error) {
      toast.error('Failed to update status')
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'RESOLVED':
      case 'CLOSED':
        return 'bg-green-500/20 text-green-400'
      case 'IN_PROGRESS':
        return 'bg-blue-500/20 text-blue-400'
      default:
        return 'bg-yellow-500/20 text-yellow-400'
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
                  Complaints / Service Tickets
                </h1>
                <p className="text-[var(--text-secondary)]">
                  Manage customer complaints and service tickets
                </p>
              </div>
              <button
                onClick={() => {
                  setShowForm(true)
                  setEditingComplaint(null)
                  setFormData({
                    title: '',
                    description: '',
                    priority: 'MEDIUM',
                    customerName: '',
                    customerContact: '',
                    photos: [],
                  })
                }}
                className="flex items-center gap-2 px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
              >
                <PlusIcon className="w-5 h-5" />
                New Complaint
              </button>
            </div>

            {showForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingComplaint ? 'Edit Complaint' : 'Create Complaint'}</CardTitle>
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
                          Priority
                        </label>
                        <select
                          value={formData.priority}
                          onChange={(e) =>
                            setFormData({ ...formData, priority: e.target.value as any })
                          }
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        >
                          <option value="LOW">Low</option>
                          <option value="MEDIUM">Medium</option>
                          <option value="HIGH">High</option>
                          <option value="URGENT">Urgent</option>
                        </select>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Customer Name
                        </label>
                        <input
                          type="text"
                          value={formData.customerName}
                          onChange={(e) => setFormData({ ...formData, customerName: e.target.value })}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Customer Contact
                        </label>
                        <input
                          type="text"
                          value={formData.customerContact}
                          onChange={(e) => setFormData({ ...formData, customerContact: e.target.value })}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Photos
                      </label>
                      <FileUpload
                        onUpload={(urls) => setFormData({ ...formData, photos: urls })}
                        multiple
                        accept="image/*"
                        folder="complaints"
                      />
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        {editingComplaint ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowForm(false)
                          setEditingComplaint(null)
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
                {complaints.length === 0 ? (
                  <Card>
                    <CardContent className="py-12 text-center">
                      <p className="text-[var(--text-secondary)]">No complaints found</p>
                    </CardContent>
                  </Card>
                ) : (
                  complaints.map((complaint) => (
                    <Card key={complaint.id} hover>
                      <CardHeader>
                        <div className="flex items-center justify-between">
                          <div className="flex-1">
                            <CardTitle>{complaint.title}</CardTitle>
                            {complaint.customerName && (
                              <p className="text-sm text-[var(--text-secondary)] mt-1">
                                Customer: {complaint.customerName}
                              </p>
                            )}
                          </div>
                          <div className="flex items-center gap-2">
                            <span
                              className={`px-3 py-1 rounded-full text-sm ${getStatusColor(complaint.status)}`}
                            >
                              {complaint.status}
                            </span>
                            <select
                              value={complaint.status}
                              onChange={(e) =>
                                handleStatusChange(complaint.id, e.target.value as Complaint['status'])
                              }
                              className="px-2 py-1 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded text-sm text-[var(--text-primary)]"
                            >
                              <option value="OPEN">Open</option>
                              <option value="IN_PROGRESS">In Progress</option>
                              <option value="RESOLVED">Resolved</option>
                              <option value="CLOSED">Closed</option>
                            </select>
                            <button
                              onClick={() => handleEdit(complaint)}
                              className="p-2 hover:bg-purple-500/20 rounded"
                            >
                              <PencilIcon className="w-4 h-4 text-purple-400" />
                            </button>
                            <button
                              onClick={() => handleDelete(complaint.id)}
                              className="p-2 hover:bg-red-500/20 rounded"
                            >
                              <TrashIcon className="w-4 h-4 text-red-400" />
                            </button>
                          </div>
                        </div>
                      </CardHeader>
                      <CardContent>
                        {complaint.description && (
                          <p className="text-sm text-[var(--text-secondary)] mb-4">
                            {complaint.description}
                          </p>
                        )}
                        <div className="flex items-center gap-4 text-sm text-[var(--text-secondary)] mb-4">
                          <span>Priority: {complaint.priority}</span>
                          <span>Created: {format(new Date(complaint.createdAt), 'MMM d, yyyy')}</span>
                        </div>
                        {complaint.photos && complaint.photos.length > 0 && (
                          <div className="grid grid-cols-4 gap-2">
                            {complaint.photos.map((photo, idx) => (
                              <img
                                key={idx}
                                src={photo}
                                alt={`Photo ${idx + 1}`}
                                className="w-full h-24 object-cover rounded"
                              />
                            ))}
                          </div>
                        )}
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

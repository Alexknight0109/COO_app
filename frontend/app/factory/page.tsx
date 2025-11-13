'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { factoryApi, FactoryProduction } from '@/lib/api/factory'
import toast from 'react-hot-toast'
import { PlusIcon, PencilIcon, TrashIcon } from '@heroicons/react/24/outline'
import { format } from 'date-fns'

export default function FactoryPage() {
  const [productions, setProductions] = useState<FactoryProduction[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editingProduction, setEditingProduction] = useState<FactoryProduction | null>(null)
  const [formData, setFormData] = useState({
    ahuSerialNumber: '',
    stage: '',
    status: 'IN_PROGRESS',
    qcStatus: 'PENDING',
    notes: '',
  })

  useEffect(() => {
    loadProductions()
  }, [])

  const loadProductions = async () => {
    try {
      setLoading(true)
      const data = await factoryApi.getAll()
      setProductions(data)
    } catch (error) {
      console.error('Failed to load productions:', error)
      toast.error('Failed to load productions')
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingProduction) {
        await factoryApi.update(editingProduction.id, formData)
        toast.success('Production updated')
      } else {
        await factoryApi.create(formData)
        toast.success('Production created')
      }
      setShowForm(false)
      setEditingProduction(null)
      setFormData({
        ahuSerialNumber: '',
        stage: '',
        status: 'IN_PROGRESS',
        qcStatus: 'PENDING',
        notes: '',
      })
      loadProductions()
    } catch (error) {
      toast.error('Failed to save production')
    }
  }

  const handleEdit = (production: FactoryProduction) => {
    setEditingProduction(production)
    setFormData({
      ahuSerialNumber: production.ahuSerialNumber,
      stage: production.stage,
      status: production.status || 'IN_PROGRESS',
      qcStatus: production.qcStatus || 'PENDING',
      notes: production.notes || '',
    })
    setShowForm(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this production?')) return
    try {
      await factoryApi.delete(id)
      toast.success('Production deleted')
      loadProductions()
    } catch (error) {
      toast.error('Failed to delete production')
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
                  Factory / Production Control
                </h1>
                <p className="text-[var(--text-secondary)]">
                  Track AHU serial numbers and production stages
                </p>
              </div>
              <button
                onClick={() => {
                  setShowForm(true)
                  setEditingProduction(null)
                  setFormData({
                    ahuSerialNumber: '',
                    stage: '',
                    status: 'IN_PROGRESS',
                    qcStatus: 'PENDING',
                    notes: '',
                  })
                }}
                className="flex items-center gap-2 px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
              >
                <PlusIcon className="w-5 h-5" />
                New Production
              </button>
            </div>

            {showForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingProduction ? 'Edit Production' : 'Create Production'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        AHU Serial Number *
                      </label>
                      <input
                        type="text"
                        value={formData.ahuSerialNumber}
                        onChange={(e) => setFormData({ ...formData, ahuSerialNumber: e.target.value })}
                        required
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Stage *
                        </label>
                        <input
                          type="text"
                          value={formData.stage}
                          onChange={(e) => setFormData({ ...formData, stage: e.target.value })}
                          required
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Status
                        </label>
                        <select
                          value={formData.status}
                          onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        >
                          <option value="IN_PROGRESS">In Progress</option>
                          <option value="COMPLETED">Completed</option>
                          <option value="ON_HOLD">On Hold</option>
                        </select>
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        QC Status
                      </label>
                      <select
                        value={formData.qcStatus}
                        onChange={(e) => setFormData({ ...formData, qcStatus: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      >
                        <option value="PENDING">Pending</option>
                        <option value="PASSED">Passed</option>
                        <option value="FAILED">Failed</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Notes
                      </label>
                      <textarea
                        value={formData.notes}
                        onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        rows={3}
                      />
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        {editingProduction ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowForm(false)
                          setEditingProduction(null)
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
                {productions.length === 0 ? (
                  <Card>
                    <CardContent className="py-12 text-center">
                      <p className="text-[var(--text-secondary)]">No productions found</p>
                    </CardContent>
                  </Card>
                ) : (
                  productions.map((production) => (
                    <Card key={production.id} hover>
                      <CardHeader>
                        <div className="flex items-center justify-between">
                          <div>
                            <CardTitle>AHU Serial: {production.ahuSerialNumber}</CardTitle>
                            <p className="text-sm text-[var(--text-secondary)] mt-1">
                              Stage: {production.stage}
                            </p>
                          </div>
                          <div className="flex items-center gap-2">
                            <span
                              className={`px-3 py-1 rounded-full text-sm ${
                                production.dispatchReady
                                  ? 'bg-green-500/20 text-green-400'
                                  : 'bg-yellow-500/20 text-yellow-400'
                              }`}
                            >
                              {production.dispatchReady ? 'Ready' : 'Not Ready'}
                            </span>
                            <button
                              onClick={() => handleEdit(production)}
                              className="p-2 hover:bg-purple-500/20 rounded"
                            >
                              <PencilIcon className="w-4 h-4 text-purple-400" />
                            </button>
                            <button
                              onClick={() => handleDelete(production.id)}
                              className="p-2 hover:bg-red-500/20 rounded"
                            >
                              <TrashIcon className="w-4 h-4 text-red-400" />
                            </button>
                          </div>
                        </div>
                      </CardHeader>
                      <CardContent>
                        <div className="grid grid-cols-3 gap-4 mb-4">
                          <div>
                            <p className="text-sm text-[var(--text-secondary)]">Status</p>
                            <p className="font-medium text-[var(--text-primary)]">{production.status}</p>
                          </div>
                          <div>
                            <p className="text-sm text-[var(--text-secondary)]">QC Status</p>
                            <p className="font-medium text-[var(--text-primary)]">{production.qcStatus}</p>
                          </div>
                          <div>
                            <p className="text-sm text-[var(--text-secondary)]">Created</p>
                            <p className="font-medium text-[var(--text-primary)]">
                              {format(new Date(production.createdAt), 'MMM d, yyyy')}
                            </p>
                          </div>
                        </div>
                        {production.notes && (
                          <p className="text-sm text-[var(--text-secondary)]">{production.notes}</p>
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

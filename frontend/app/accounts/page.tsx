'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { accountsApi, Account, PaymentStage } from '@/lib/api/accounts'
import toast from 'react-hot-toast'
import { PlusIcon, PencilIcon, TrashIcon, CurrencyDollarIcon } from '@heroicons/react/24/outline'
import { format } from 'date-fns'

export default function AccountsPage() {
  const [accounts, setAccounts] = useState<Account[]>([])
  const [selectedAccount, setSelectedAccount] = useState<Account | null>(null)
  const [paymentStages, setPaymentStages] = useState<PaymentStage[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [showPaymentForm, setShowPaymentForm] = useState(false)
  const [editingAccount, setEditingAccount] = useState<Account | null>(null)
  const [formData, setFormData] = useState({
    poNumber: '',
    poValue: 0,
    outstandingBalance: 0,
    status: 'ACTIVE',
  })
  const [paymentFormData, setPaymentFormData] = useState({
    stage: '',
    amount: 0,
    dueDate: '',
    notes: '',
  })

  useEffect(() => {
    loadAccounts()
  }, [])

  useEffect(() => {
    if (selectedAccount) {
      loadPaymentStages(selectedAccount.id)
    }
  }, [selectedAccount])

  const loadAccounts = async () => {
    try {
      setLoading(true)
      const data = await accountsApi.getAll()
      setAccounts(data)
      if (data.length > 0 && !selectedAccount) {
        setSelectedAccount(data[0])
      }
    } catch (error) {
      console.error('Failed to load accounts:', error)
      toast.error('Failed to load accounts')
    } finally {
      setLoading(false)
    }
  }

  const loadPaymentStages = async (accountId: string) => {
    try {
      const data = await accountsApi.getPaymentStages(accountId)
      setPaymentStages(data)
    } catch (error) {
      console.error('Failed to load payment stages:', error)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingAccount) {
        await accountsApi.update(editingAccount.id, formData)
        toast.success('Account updated')
      } else {
        await accountsApi.create(formData)
        toast.success('Account created')
      }
      setShowForm(false)
      setEditingAccount(null)
      setFormData({ poNumber: '', poValue: 0, outstandingBalance: 0, status: 'ACTIVE' })
      loadAccounts()
    } catch (error) {
      toast.error('Failed to save account')
    }
  }

  const handlePaymentSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedAccount) return
    try {
      await accountsApi.createPaymentStage({
        accountId: selectedAccount.id,
        ...paymentFormData,
      })
      toast.success('Payment stage created')
      setShowPaymentForm(false)
      setPaymentFormData({ stage: '', amount: 0, dueDate: '', notes: '' })
      loadPaymentStages(selectedAccount.id)
    } catch (error) {
      toast.error('Failed to create payment stage')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this account?')) return
    try {
      await accountsApi.delete(id)
      toast.success('Account deleted')
      loadAccounts()
    } catch (error) {
      toast.error('Failed to delete account')
    }
  }

  const totalPOValue = accounts.reduce((sum, a) => sum + (a.poValue || 0), 0)
  const totalOutstanding = accounts.reduce((sum, a) => sum + (a.outstandingBalance || 0), 0)

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
                  Accounts & Payments
                </h1>
                <p className="text-[var(--text-secondary)]">
                  Track PO values and payment stages
                </p>
              </div>
              <button
                onClick={() => {
                  setShowForm(true)
                  setEditingAccount(null)
                  setFormData({ poNumber: '', poValue: 0, outstandingBalance: 0, status: 'ACTIVE' })
                }}
                className="flex items-center gap-2 px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
              >
                <PlusIcon className="w-5 h-5" />
                New Account
              </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
              <Card hover>
                <CardHeader>
                  <CardTitle className="text-sm font-medium text-[var(--text-secondary)]">
                    Total Accounts
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-3xl font-bold text-[var(--text-primary)]">{accounts.length}</p>
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
              <Card hover>
                <CardHeader>
                  <CardTitle className="text-sm font-medium text-[var(--text-secondary)]">
                    Outstanding Balance
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-3xl font-bold text-red-400">
                    ${totalOutstanding.toLocaleString()}
                  </p>
                </CardContent>
              </Card>
            </div>

            {showForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingAccount ? 'Edit Account' : 'Create Account'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        PO Number
                      </label>
                      <input
                        type="text"
                        value={formData.poNumber}
                        onChange={(e) => setFormData({ ...formData, poNumber: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          PO Value
                        </label>
                        <input
                          type="number"
                          value={formData.poValue}
                          onChange={(e) => setFormData({ ...formData, poValue: Number(e.target.value) })}
                          min={0}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Outstanding Balance
                        </label>
                        <input
                          type="number"
                          value={formData.outstandingBalance}
                          onChange={(e) =>
                            setFormData({ ...formData, outstandingBalance: Number(e.target.value) })
                          }
                          min={0}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        {editingAccount ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowForm(false)
                          setEditingAccount(null)
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

            {showPaymentForm && selectedAccount && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>Add Payment Stage - {selectedAccount.poNumber || 'Account'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handlePaymentSubmit} className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Stage *
                        </label>
                        <input
                          type="text"
                          value={paymentFormData.stage}
                          onChange={(e) => setPaymentFormData({ ...paymentFormData, stage: e.target.value })}
                          required
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Amount *
                        </label>
                        <input
                          type="number"
                          value={paymentFormData.amount}
                          onChange={(e) =>
                            setPaymentFormData({ ...paymentFormData, amount: Number(e.target.value) })
                          }
                          required
                          min={0}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Due Date
                      </label>
                      <input
                        type="date"
                        value={paymentFormData.dueDate}
                        onChange={(e) => setPaymentFormData({ ...paymentFormData, dueDate: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Notes
                      </label>
                      <textarea
                        value={paymentFormData.notes}
                        onChange={(e) => setPaymentFormData({ ...paymentFormData, notes: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        rows={3}
                      />
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        Create Payment Stage
                      </button>
                      <button
                        type="button"
                        onClick={() => setShowPaymentForm(false)}
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
                      <CardTitle>Accounts</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {accounts.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">No accounts found</p>
                      ) : (
                        <div className="space-y-2">
                          {accounts.map((account) => (
                            <button
                              key={account.id}
                              onClick={() => setSelectedAccount(account)}
                              className={`w-full p-3 rounded-lg text-left transition-colors ${
                                selectedAccount?.id === account.id
                                  ? 'bg-gradient-purple-blue/20 border border-purple-500/50'
                                  : 'hover:bg-[var(--hover-bg)] border border-transparent'
                              }`}
                            >
                              <div className="flex items-center justify-between">
                                <div>
                                  <h3 className="font-medium text-[var(--text-primary)]">
                                    {account.poNumber || 'No PO Number'}
                                  </h3>
                                  <p className="text-xs text-[var(--text-secondary)]">
                                    ${account.poValue?.toLocaleString() || 0}
                                  </p>
                                </div>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation()
                                    setEditingAccount(account)
                                    setFormData({
                                      poNumber: account.poNumber || '',
                                      poValue: account.poValue || 0,
                                      outstandingBalance: account.outstandingBalance || 0,
                                      status: account.status || 'ACTIVE',
                                    })
                                    setShowForm(true)
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
                      <div className="flex items-center justify-between">
                        <CardTitle>
                          Payment Stages {selectedAccount && `- ${selectedAccount.poNumber || 'Account'}`}
                        </CardTitle>
                        {selectedAccount && (
                          <button
                            onClick={() => setShowPaymentForm(true)}
                            className="flex items-center gap-2 px-3 py-1 gradient-purple-blue rounded-lg text-white text-sm"
                          >
                            <PlusIcon className="w-4 h-4" />
                            Add Stage
                          </button>
                        )}
                      </div>
                    </CardHeader>
                    <CardContent>
                      {!selectedAccount ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">
                          Select an account to view payment stages
                        </p>
                      ) : paymentStages.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">No payment stages found</p>
                      ) : (
                        <div className="space-y-4">
                          {paymentStages.map((stage) => (
                            <div
                              key={stage.id}
                              className="p-4 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)]"
                            >
                              <div className="flex items-center justify-between mb-2">
                                <div>
                                  <h3 className="font-medium text-[var(--text-primary)]">{stage.stage}</h3>
                                  <p className="text-sm text-[var(--text-secondary)]">
                                    ${stage.amount.toLocaleString()}
                                  </p>
                                </div>
                                <span
                                  className={`px-3 py-1 rounded-full text-sm ${
                                    stage.status === 'PAID'
                                      ? 'bg-green-500/20 text-green-400'
                                      : stage.status === 'OVERDUE'
                                      ? 'bg-red-500/20 text-red-400'
                                      : 'bg-yellow-500/20 text-yellow-400'
                                  }`}
                                >
                                  {stage.status}
                                </span>
                              </div>
                              {stage.dueDate && (
                                <p className="text-xs text-[var(--text-secondary)] mb-2">
                                  Due: {format(new Date(stage.dueDate), 'MMM d, yyyy')}
                                </p>
                              )}
                              {stage.notes && (
                                <p className="text-sm text-[var(--text-secondary)]">{stage.notes}</p>
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

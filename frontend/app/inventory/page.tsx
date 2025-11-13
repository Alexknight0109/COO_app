'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { inventoryApi, InventoryItem, InventoryTransaction } from '@/lib/api/inventory'
import toast from 'react-hot-toast'
import { PlusIcon, PencilIcon, TrashIcon, ArrowDownIcon, ArrowUpIcon } from '@heroicons/react/24/outline'

export default function InventoryPage() {
  const [items, setItems] = useState<InventoryItem[]>([])
  const [transactions, setTransactions] = useState<InventoryTransaction[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [showTransactionForm, setShowTransactionForm] = useState(false)
  const [selectedItem, setSelectedItem] = useState<InventoryItem | null>(null)
  const [editingItem, setEditingItem] = useState<InventoryItem | null>(null)
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    category: '',
    quantity: 0,
    unit: 'pcs',
    minStockLevel: 0,
    location: '',
  })
  const [transactionData, setTransactionData] = useState({
    inventoryId: '',
    type: 'IN' as 'IN' | 'OUT',
    quantity: 0,
    reason: '',
  })

  useEffect(() => {
    loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      const [itemsData, transactionsData] = await Promise.all([
        inventoryApi.getAll(),
        inventoryApi.getTransactions(),
      ])
      setItems(itemsData)
      setTransactions(transactionsData)
    } catch (error) {
      console.error('Failed to load data:', error)
      toast.error('Failed to load data')
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingItem) {
        await inventoryApi.update(editingItem.id, formData)
        toast.success('Item updated')
      } else {
        await inventoryApi.create(formData)
        toast.success('Item created')
      }
      setShowForm(false)
      setEditingItem(null)
      setFormData({
        name: '',
        description: '',
        category: '',
        quantity: 0,
        unit: 'pcs',
        minStockLevel: 0,
        location: '',
      })
      loadData()
    } catch (error) {
      toast.error('Failed to save item')
    }
  }

  const handleTransactionSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await inventoryApi.createTransaction(transactionData)
      toast.success('Transaction created')
      setShowTransactionForm(false)
      setTransactionData({
        inventoryId: '',
        type: 'IN',
        quantity: 0,
        reason: '',
      })
      loadData()
    } catch (error) {
      toast.error('Failed to create transaction')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this item?')) return
    try {
      await inventoryApi.delete(id)
      toast.success('Item deleted')
      loadData()
    } catch (error) {
      toast.error('Failed to delete item')
    }
  }

  const lowStockItems = items.filter(
    (item) => item.minStockLevel && item.quantity <= item.minStockLevel
  )

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
                  Inventory / Store
                </h1>
                <p className="text-[var(--text-secondary)]">
                  Manage stock levels and material issues
                </p>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => {
                    setShowTransactionForm(true)
                    setSelectedItem(null)
                  }}
                  className="flex items-center gap-2 px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)] hover:border-purple-500"
                >
                  <ArrowUpIcon className="w-5 h-5" />
                  Stock In/Out
                </button>
                <button
                  onClick={() => {
                    setShowForm(true)
                    setEditingItem(null)
                    setFormData({
                      name: '',
                      description: '',
                      category: '',
                      quantity: 0,
                      unit: 'pcs',
                      minStockLevel: 0,
                      location: '',
                    })
                  }}
                  className="flex items-center gap-2 px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                >
                  <PlusIcon className="w-5 h-5" />
                  New Item
                </button>
              </div>
            </div>

            {lowStockItems.length > 0 && (
              <Card className="mb-6 border-yellow-500/50 bg-yellow-500/10">
                <CardHeader>
                  <CardTitle className="text-yellow-400">Low Stock Alert</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    {lowStockItems.map((item) => (
                      <p key={item.id} className="text-sm text-[var(--text-primary)]">
                        {item.name}: {item.quantity} {item.unit} (Min: {item.minStockLevel})
                      </p>
                    ))}
                  </div>
                </CardContent>
              </Card>
            )}

            {showForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingItem ? 'Edit Item' : 'Create Item'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleSubmit} className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Name *
                        </label>
                        <input
                          type="text"
                          value={formData.name}
                          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                          required
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Category
                        </label>
                        <input
                          type="text"
                          value={formData.category}
                          onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Description
                      </label>
                      <textarea
                        value={formData.description}
                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        rows={3}
                      />
                    </div>
                    <div className="grid grid-cols-4 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Quantity *
                        </label>
                        <input
                          type="number"
                          value={formData.quantity}
                          onChange={(e) => setFormData({ ...formData, quantity: Number(e.target.value) })}
                          required
                          min={0}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Unit
                        </label>
                        <input
                          type="text"
                          value={formData.unit}
                          onChange={(e) => setFormData({ ...formData, unit: e.target.value })}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Min Stock Level
                        </label>
                        <input
                          type="number"
                          value={formData.minStockLevel}
                          onChange={(e) => setFormData({ ...formData, minStockLevel: Number(e.target.value) })}
                          min={0}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Location
                        </label>
                        <input
                          type="text"
                          value={formData.location}
                          onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        {editingItem ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowForm(false)
                          setEditingItem(null)
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

            {showTransactionForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>Stock In/Out</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleTransactionSubmit} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Item *
                      </label>
                      <select
                        value={transactionData.inventoryId}
                        onChange={(e) => setTransactionData({ ...transactionData, inventoryId: e.target.value })}
                        required
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      >
                        <option value="">Select item</option>
                        {items.map((item) => (
                          <option key={item.id} value={item.id}>
                            {item.name} ({item.quantity} {item.unit})
                          </option>
                        ))}
                      </select>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Type *
                        </label>
                        <select
                          value={transactionData.type}
                          onChange={(e) =>
                            setTransactionData({ ...transactionData, type: e.target.value as 'IN' | 'OUT' })
                          }
                          required
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        >
                          <option value="IN">Stock In</option>
                          <option value="OUT">Stock Out</option>
                        </select>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Quantity *
                        </label>
                        <input
                          type="number"
                          value={transactionData.quantity}
                          onChange={(e) =>
                            setTransactionData({ ...transactionData, quantity: Number(e.target.value) })
                          }
                          required
                          min={1}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Reason
                      </label>
                      <input
                        type="text"
                        value={transactionData.reason}
                        onChange={(e) => setTransactionData({ ...transactionData, reason: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      />
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        Create Transaction
                      </button>
                      <button
                        type="button"
                        onClick={() => setShowTransactionForm(false)}
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
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div>
                  <Card>
                    <CardHeader>
                      <CardTitle>Inventory Items</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {items.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">No items found</p>
                      ) : (
                        <div className="space-y-4">
                          {items.map((item) => (
                            <div
                              key={item.id}
                              className={`p-4 rounded-lg border ${
                                item.minStockLevel && item.quantity <= item.minStockLevel
                                  ? 'border-yellow-500/50 bg-yellow-500/10'
                                  : 'border-[var(--border-color)] bg-[var(--bg-primary)]'
                              }`}
                            >
                              <div className="flex items-center justify-between mb-2">
                                <div>
                                  <h3 className="font-medium text-[var(--text-primary)]">{item.name}</h3>
                                  {item.category && (
                                    <p className="text-xs text-[var(--text-secondary)]">{item.category}</p>
                                  )}
                                </div>
                                <div className="flex items-center gap-2">
                                  <span
                                    className={`px-2 py-1 rounded text-sm ${
                                      item.minStockLevel && item.quantity <= item.minStockLevel
                                        ? 'bg-yellow-500/20 text-yellow-400'
                                        : 'bg-green-500/20 text-green-400'
                                    }`}
                                  >
                                    {item.quantity} {item.unit}
                                  </span>
                                  <button
                                    onClick={() => {
                                      setEditingItem(item)
                                      setFormData({
                                        name: item.name,
                                        description: item.description || '',
                                        category: item.category || '',
                                        quantity: item.quantity,
                                        unit: item.unit || 'pcs',
                                        minStockLevel: item.minStockLevel || 0,
                                        location: item.location || '',
                                      })
                                      setShowForm(true)
                                    }}
                                    className="p-1 hover:bg-purple-500/20 rounded"
                                  >
                                    <PencilIcon className="w-4 h-4 text-purple-400" />
                                  </button>
                                  <button
                                    onClick={() => handleDelete(item.id)}
                                    className="p-1 hover:bg-red-500/20 rounded"
                                  >
                                    <TrashIcon className="w-4 h-4 text-red-400" />
                                  </button>
                                </div>
                              </div>
                              {item.description && (
                                <p className="text-sm text-[var(--text-secondary)] mb-2">{item.description}</p>
                              )}
                              <div className="flex items-center gap-4 text-xs text-[var(--text-secondary)]">
                                {item.location && <span>Location: {item.location}</span>}
                                {item.minStockLevel && <span>Min: {item.minStockLevel}</span>}
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </CardContent>
                  </Card>
                </div>

                <div>
                  <Card>
                    <CardHeader>
                      <CardTitle>Recent Transactions</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {transactions.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">No transactions found</p>
                      ) : (
                        <div className="space-y-2">
                          {transactions.slice(0, 10).map((transaction) => {
                            const item = items.find((i) => i.id === transaction.inventoryId)
                            return (
                              <div
                                key={transaction.id}
                                className="p-3 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)]"
                              >
                                <div className="flex items-center justify-between">
                                  <div className="flex items-center gap-2">
                                    {transaction.type === 'IN' ? (
                                      <ArrowDownIcon className="w-4 h-4 text-green-400" />
                                    ) : (
                                      <ArrowUpIcon className="w-4 h-4 text-red-400" />
                                    )}
                                    <div>
                                      <p className="text-sm font-medium text-[var(--text-primary)]">
                                        {item?.name || 'Unknown Item'}
                                      </p>
                                      <p className="text-xs text-[var(--text-secondary)]">
                                        {transaction.quantity} {item?.unit || 'pcs'} - {transaction.reason || 'No reason'}
                                      </p>
                                    </div>
                                  </div>
                                  <span
                                    className={`px-2 py-1 rounded text-xs ${
                                      transaction.type === 'IN'
                                        ? 'bg-green-500/20 text-green-400'
                                        : 'bg-red-500/20 text-red-400'
                                    }`}
                                  >
                                    {transaction.type}
                                  </span>
                                </div>
                              </div>
                            )
                          })}
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

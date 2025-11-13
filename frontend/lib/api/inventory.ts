import apiClient from './client'

export interface InventoryItem {
  id: string
  name: string
  description?: string
  category?: string
  quantity: number
  unit?: string
  minStockLevel?: number
  location?: string
  createdAt: string
  updatedAt: string
}

export interface InventoryTransaction {
  id: string
  inventoryId: string
  type: 'IN' | 'OUT'
  quantity: number
  reason?: string
  siteId?: string
  projectId?: string
  createdBy?: string
  createdAt: string
}

export interface CreateInventoryItemDto {
  name: string
  description?: string
  category?: string
  quantity: number
  unit?: string
  minStockLevel?: number
  location?: string
}

export interface CreateTransactionDto {
  inventoryId: string
  type: 'IN' | 'OUT'
  quantity: number
  reason?: string
  siteId?: string
  projectId?: string
}

export const inventoryApi = {
  getAll: async (): Promise<InventoryItem[]> => {
    const response = await apiClient.get<InventoryItem[]>('/inventory')
    return response.data
  },

  getById: async (id: string): Promise<InventoryItem> => {
    const response = await apiClient.get<InventoryItem>(`/inventory/${id}`)
    return response.data
  },

  create: async (data: CreateInventoryItemDto): Promise<InventoryItem> => {
    const response = await apiClient.post<InventoryItem>('/inventory', data)
    return response.data
  },

  update: async (id: string, data: Partial<CreateInventoryItemDto>): Promise<InventoryItem> => {
    const response = await apiClient.patch<InventoryItem>(`/inventory/${id}`, data)
    return response.data
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/inventory/${id}`)
  },

  getTransactions: async (inventoryId?: string): Promise<InventoryTransaction[]> => {
    const params = inventoryId ? { inventoryId } : {}
    const response = await apiClient.get<InventoryTransaction[]>('/inventory/transactions', { params })
    return response.data
  },

  createTransaction: async (data: CreateTransactionDto): Promise<InventoryTransaction> => {
    const response = await apiClient.post<InventoryTransaction>('/inventory/transactions', data)
    return response.data
  },
}


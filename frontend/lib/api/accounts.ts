import apiClient from './client'

export interface Account {
  id: string
  projectId?: string
  poNumber?: string
  poValue?: number
  outstandingBalance?: number
  status?: string
  createdAt: string
  updatedAt: string
}

export interface PaymentStage {
  id: string
  accountId: string
  stage: string
  amount: number
  dueDate?: string
  paidDate?: string
  status: 'PENDING' | 'PAID' | 'OVERDUE'
  notes?: string
  createdAt: string
  updatedAt: string
}

export interface CreateAccountDto {
  projectId?: string
  poNumber?: string
  poValue?: number
  outstandingBalance?: number
  status?: string
}

export interface CreatePaymentStageDto {
  accountId: string
  stage: string
  amount: number
  dueDate?: string
  notes?: string
}

export const accountsApi = {
  getAll: async (): Promise<Account[]> => {
    const response = await apiClient.get<Account[]>('/accounts')
    return response.data
  },

  getById: async (id: string): Promise<Account> => {
    const response = await apiClient.get<Account>(`/accounts/${id}`)
    return response.data
  },

  create: async (data: CreateAccountDto): Promise<Account> => {
    const response = await apiClient.post<Account>('/accounts', data)
    return response.data
  },

  update: async (id: string, data: Partial<CreateAccountDto>): Promise<Account> => {
    const response = await apiClient.patch<Account>(`/accounts/${id}`, data)
    return response.data
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/accounts/${id}`)
  },

  getPaymentStages: async (accountId: string): Promise<PaymentStage[]> => {
    const response = await apiClient.get<PaymentStage[]>(`/accounts/${accountId}/payment-stages`)
    return response.data
  },

  createPaymentStage: async (data: CreatePaymentStageDto): Promise<PaymentStage> => {
    const response = await apiClient.post<PaymentStage>('/accounts/payment-stages', data)
    return response.data
  },

  updatePaymentStage: async (id: string, data: Partial<CreatePaymentStageDto>): Promise<PaymentStage> => {
    const response = await apiClient.patch<PaymentStage>(`/accounts/payment-stages/${id}`, data)
    return response.data
  },
}


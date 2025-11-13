import apiClient from './client'

export interface Complaint {
  id: string
  title: string
  description?: string
  status: 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED'
  priority?: 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT'
  assignedToId?: string
  assignedTo?: {
    id: string
    firstName: string
    lastName: string
  }
  customerName?: string
  customerContact?: string
  siteId?: string
  photos?: string[]
  signature?: string
  createdAt: string
  updatedAt: string
}

export interface CreateComplaintDto {
  title: string
  description?: string
  priority?: 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT'
  assignedToId?: string
  customerName?: string
  customerContact?: string
  siteId?: string
  photos?: string[]
}

export const complaintsApi = {
  getAll: async (): Promise<Complaint[]> => {
    const response = await apiClient.get<Complaint[]>('/complaints')
    return response.data
  },

  getById: async (id: string): Promise<Complaint> => {
    const response = await apiClient.get<Complaint>(`/complaints/${id}`)
    return response.data
  },

  create: async (data: CreateComplaintDto): Promise<Complaint> => {
    const response = await apiClient.post<Complaint>('/complaints', data)
    return response.data
  },

  update: async (id: string, data: Partial<CreateComplaintDto>): Promise<Complaint> => {
    const response = await apiClient.patch<Complaint>(`/complaints/${id}`, data)
    return response.data
  },

  updateStatus: async (id: string, status: Complaint['status']): Promise<Complaint> => {
    const response = await apiClient.patch<Complaint>(`/complaints/${id}/status`, { status })
    return response.data
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/complaints/${id}`)
  },
}


import apiClient from './client'

export interface Report {
  id: string
  title: string
  description?: string
  type: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'SITE' | 'FACTORY' | 'SALES' | 'OTHER'
  fileUrl?: string
  createdBy?: string
  createdByUser?: {
    id: string
    firstName: string
    lastName: string
  }
  projectId?: string
  siteId?: string
  createdAt: string
  updatedAt: string
}

export interface CreateReportDto {
  title: string
  description?: string
  type: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'SITE' | 'FACTORY' | 'SALES' | 'OTHER'
  fileUrl?: string
  projectId?: string
  siteId?: string
}

export const reportsApi = {
  getAll: async (): Promise<Report[]> => {
    const response = await apiClient.get<Report[]>('/reports')
    return response.data
  },

  getById: async (id: string): Promise<Report> => {
    const response = await apiClient.get<Report>(`/reports/${id}`)
    return response.data
  },

  create: async (data: CreateReportDto): Promise<Report> => {
    const response = await apiClient.post<Report>('/reports', data)
    return response.data
  },

  update: async (id: string, data: Partial<CreateReportDto>): Promise<Report> => {
    const response = await apiClient.patch<Report>(`/reports/${id}`, data)
    return response.data
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/reports/${id}`)
  },
}


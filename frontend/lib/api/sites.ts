import apiClient from './client'

export interface Site {
  id: string
  name: string
  address?: string
  projectId?: string
  status?: string
  latitude?: number
  longitude?: number
  createdAt: string
  updatedAt: string
}

export interface SiteLog {
  id: string
  siteId: string
  workDone?: string
  materialsNeeded?: string
  issues?: string
  photos?: string[]
  createdBy?: string
  createdAt: string
  updatedAt: string
}

export interface CreateSiteDto {
  name: string
  address?: string
  projectId?: string
  status?: string
  latitude?: number
  longitude?: number
}

export interface CreateSiteLogDto {
  siteId: string
  workDone?: string
  materialsNeeded?: string
  issues?: string
  photos?: string[]
}

export const sitesApi = {
  getAll: async (): Promise<Site[]> => {
    const response = await apiClient.get<Site[]>('/sites')
    return response.data
  },

  getById: async (id: string): Promise<Site> => {
    const response = await apiClient.get<Site>(`/sites/${id}`)
    return response.data
  },

  create: async (data: CreateSiteDto): Promise<Site> => {
    const response = await apiClient.post<Site>('/sites', data)
    return response.data
  },

  update: async (id: string, data: Partial<CreateSiteDto>): Promise<Site> => {
    const response = await apiClient.patch<Site>(`/sites/${id}`, data)
    return response.data
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/sites/${id}`)
  },

  getLogs: async (siteId: string): Promise<SiteLog[]> => {
    const response = await apiClient.get<SiteLog[]>(`/sites/${siteId}/logs`)
    return response.data
  },

  createLog: async (data: CreateSiteLogDto): Promise<SiteLog> => {
    const response = await apiClient.post<SiteLog>('/sites/logs', data)
    return response.data
  },
}


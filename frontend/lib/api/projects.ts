import apiClient from './client'

export interface Project {
  id: string
  name: string
  description?: string
  poNumber?: string
  poValue?: number
  status: string
  startDate?: string
  endDate?: string
  createdAt: string
  updatedAt: string
}

export interface CreateProjectDto {
  name: string
  description?: string
  poNumber?: string
  poValue?: number
  status?: string
  startDate?: string
  endDate?: string
}

export const projectsApi = {
  getAll: async (): Promise<Project[]> => {
    const response = await apiClient.get<Project[]>('/projects')
    return response.data
  },

  getById: async (id: string): Promise<Project> => {
    const response = await apiClient.get<Project>(`/projects/${id}`)
    return response.data
  },

  create: async (data: CreateProjectDto): Promise<Project> => {
    const response = await apiClient.post<Project>('/projects', data)
    return response.data
  },

  update: async (id: string, data: Partial<CreateProjectDto>): Promise<Project> => {
    const response = await apiClient.patch<Project>(`/projects/${id}`, data)
    return response.data
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/projects/${id}`)
  },
}


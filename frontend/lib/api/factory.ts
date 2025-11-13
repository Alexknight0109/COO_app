import apiClient from './client'

export interface FactoryProduction {
  id: string
  ahuSerialNumber: string
  stage: string
  status?: string
  qcStatus?: string
  dispatchReady?: boolean
  notes?: string
  createdAt: string
  updatedAt: string
}

export interface CreateFactoryProductionDto {
  ahuSerialNumber: string
  stage: string
  status?: string
  qcStatus?: string
  notes?: string
}

export const factoryApi = {
  getAll: async (): Promise<FactoryProduction[]> => {
    const response = await apiClient.get<FactoryProduction[]>('/factory')
    return response.data
  },

  getById: async (id: string): Promise<FactoryProduction> => {
    const response = await apiClient.get<FactoryProduction>(`/factory/${id}`)
    return response.data
  },

  create: async (data: CreateFactoryProductionDto): Promise<FactoryProduction> => {
    const response = await apiClient.post<FactoryProduction>('/factory', data)
    return response.data
  },

  update: async (id: string, data: Partial<CreateFactoryProductionDto>): Promise<FactoryProduction> => {
    const response = await apiClient.patch<FactoryProduction>(`/factory/${id}`, data)
    return response.data
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/factory/${id}`)
  },
}


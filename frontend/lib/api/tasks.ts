import apiClient from './client'

export interface Task {
  id: string
  title: string
  description?: string
  status: 'NOT_STARTED' | 'WORKING' | 'BLOCKED' | 'REVIEWING' | 'COMPLETED'
  priority: 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT'
  dueDate?: string
  assigneeId?: string
  assignee?: {
    id: string
    firstName: string
    lastName: string
  }
  projectId?: string
  siteId?: string
  createdAt: string
  updatedAt: string
}

export interface CreateTaskDto {
  title: string
  description?: string
  priority?: 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT'
  dueDate?: string
  assigneeId?: string
  projectId?: string
  siteId?: string
}

export const tasksApi = {
  getAll: async (): Promise<Task[]> => {
    const response = await apiClient.get<Task[]>('/tasks')
    return response.data
  },

  getById: async (id: string): Promise<Task> => {
    const response = await apiClient.get<Task>(`/tasks/${id}`)
    return response.data
  },

  create: async (data: CreateTaskDto): Promise<Task> => {
    const response = await apiClient.post<Task>('/tasks', data)
    return response.data
  },

  update: async (id: string, data: Partial<CreateTaskDto>): Promise<Task> => {
    const response = await apiClient.patch<Task>(`/tasks/${id}`, data)
    return response.data
  },

  updateStatus: async (id: string, status: Task['status']): Promise<Task> => {
    const response = await apiClient.patch<Task>(`/tasks/${id}/status`, { status })
    return response.data
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/tasks/${id}`)
  },
}


import apiClient from './client'

export interface Notification {
  id: string
  title: string
  message: string
  type: 'TASK' | 'MESSAGE' | 'BROADCAST' | 'SYSTEM' | 'OTHER'
  isRead: boolean
  userId?: string
  relatedId?: string
  createdAt: string
  updatedAt: string
}

export const notificationsApi = {
  getAll: async (): Promise<Notification[]> => {
    const response = await apiClient.get<Notification[]>('/notifications')
    return response.data
  },

  getUnread: async (): Promise<Notification[]> => {
    const response = await apiClient.get<Notification[]>('/notifications/unread')
    return response.data
  },

  markAsRead: async (id: string): Promise<Notification> => {
    const response = await apiClient.patch<Notification>(`/notifications/${id}/read`, {})
    return response.data
  },

  markAllAsRead: async (): Promise<void> => {
    await apiClient.patch('/notifications/read-all', {})
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/notifications/${id}`)
  },
}


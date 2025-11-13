import apiClient from './client'

export interface Message {
  id: string
  content: string
  type: 'DM' | 'GROUP' | 'BROADCAST'
  senderId: string
  sender?: {
    id: string
    firstName: string
    lastName: string
  }
  recipients?: Array<{
    id: string
    firstName: string
    lastName: string
  }>
  groupId?: string
  broadcastTarget?: string
  isRead: boolean
  readReceipts?: Array<{
    userId: string
    readAt: string
  }>
  createdAt: string
  updatedAt: string
}

export interface CreateMessageDto {
  content: string
  recipientIds?: string[]
  groupId?: string
  broadcastTarget?: string
  type?: 'DM' | 'GROUP' | 'BROADCAST'
}

export const messagesApi = {
  getAll: async (userId?: string): Promise<Message[]> => {
    const params = userId ? { userId } : {}
    const response = await apiClient.get<Message[]>('/messages', { params })
    return response.data
  },

  getConversation: async (userId: string, currentUserId?: string): Promise<Message[]> => {
    const params = currentUserId ? { currentUserId } : {}
    const response = await apiClient.get<Message[]>(`/messages/conversation/${userId}`, { params })
    return response.data
  },

  create: async (data: CreateMessageDto): Promise<Message> => {
    const response = await apiClient.post<Message>('/messages', data)
    return response.data
  },

  markAsRead: async (id: string, userId?: string): Promise<Message> => {
    const response = await apiClient.post<Message>(`/messages/${id}/read`, { userId })
    return response.data
  },
}


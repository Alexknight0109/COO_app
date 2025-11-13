import apiClient from './client'

export interface CalendarEvent {
  id: string
  title: string
  description?: string
  startDate: string
  endDate?: string
  allDay: boolean
  type?: string
  userId?: string
  projectId?: string
  siteId?: string
  createdAt: string
  updatedAt: string
}

export interface CreateCalendarEventDto {
  title: string
  description?: string
  startDate: string
  endDate?: string
  allDay?: boolean
  type?: string
  projectId?: string
  siteId?: string
}

export const calendarApi = {
  getAll: async (): Promise<CalendarEvent[]> => {
    const response = await apiClient.get<CalendarEvent[]>('/calendar')
    return response.data
  },

  getById: async (id: string): Promise<CalendarEvent> => {
    const response = await apiClient.get<CalendarEvent>(`/calendar/${id}`)
    return response.data
  },

  create: async (data: CreateCalendarEventDto): Promise<CalendarEvent> => {
    const response = await apiClient.post<CalendarEvent>('/calendar', data)
    return response.data
  },

  update: async (id: string, data: Partial<CreateCalendarEventDto>): Promise<CalendarEvent> => {
    const response = await apiClient.patch<CalendarEvent>(`/calendar/${id}`, data)
    return response.data
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/calendar/${id}`)
  },
}


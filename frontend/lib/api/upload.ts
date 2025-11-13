import apiClient from './client'

export interface UploadResponse {
  url: string
  filename: string
  size: number
  mimeType: string
}

export const uploadApi = {
  uploadFile: async (file: File, folder?: string): Promise<UploadResponse> => {
    const formData = new FormData()
    formData.append('file', file)
    if (folder) {
      formData.append('folder', folder)
    }

    const response = await apiClient.post<UploadResponse>('/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    // Convert relative URL to full URL
    const fullUrl = response.data.url.startsWith('http')
      ? response.data.url
      : `${process.env.NEXT_PUBLIC_API_URL?.replace('/api', '') || 'http://localhost:3001'}${response.data.url}`
    return { ...response.data, url: fullUrl }
  },

  uploadMultiple: async (files: File[], folder?: string): Promise<UploadResponse[]> => {
    const formData = new FormData()
    files.forEach((file) => {
      formData.append('files', file)
    })
    if (folder) {
      formData.append('folder', folder)
    }

    const response = await apiClient.post<UploadResponse[]>('/upload/multiple', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    // Convert relative URLs to full URLs
    const baseUrl = process.env.NEXT_PUBLIC_API_URL?.replace('/api', '') || 'http://localhost:3001'
    return response.data.map((item) => ({
      ...item,
      url: item.url.startsWith('http') ? item.url : `${baseUrl}${item.url}`,
    }))
  },
}


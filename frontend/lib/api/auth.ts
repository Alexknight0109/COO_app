import apiClient from './client'

export interface LoginDto {
  email: string
  password: string
}

export interface RegisterDto {
  email: string
  password: string
  firstName: string
  lastName: string
  role?: string
}

export interface AuthResponse {
  access_token: string
  user: {
    id: string
    email: string
    firstName: string
    lastName: string
    role: string
  }
}

export interface User {
  id: string
  email: string
  firstName: string
  lastName: string
  role: string
  department?: {
    id: string
    name: string
  }
}

export const authApi = {
  login: async (data: LoginDto): Promise<AuthResponse> => {
    const response = await apiClient.post<AuthResponse>('/auth/login', data)
    return response.data
  },

  register: async (data: RegisterDto): Promise<AuthResponse> => {
    const response = await apiClient.post<AuthResponse>('/auth/register', data)
    return response.data
  },

  getProfile: async (): Promise<User> => {
    const response = await apiClient.get<User>('/auth/profile')
    return response.data
  },
}


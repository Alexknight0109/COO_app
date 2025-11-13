import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { User, authApi } from '@/lib/api/auth'
import toast from 'react-hot-toast'

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (email: string, password: string) => Promise<void>
  register: (email: string, password: string, firstName: string, lastName: string, role?: string) => Promise<void>
  logout: () => void
  loadProfile: () => Promise<void>
  setUser: (user: User | null) => void
  setToken: (token: string | null) => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,

      login: async (email: string, password: string) => {
        try {
          set({ isLoading: true })
          const response = await authApi.login({ email, password })
          
          // Store token in localStorage (for axios interceptor)
          if (typeof window !== 'undefined') {
            localStorage.setItem('auth_token', response.access_token)
            localStorage.setItem('user', JSON.stringify(response.user))
          }

          set({
            user: response.user,
            token: response.access_token,
            isAuthenticated: true,
            isLoading: false,
          })

          toast.success('Login successful!')
        } catch (error: any) {
          set({ isLoading: false })
          const message = error.response?.data?.message || 'Login failed'
          toast.error(message)
          throw error
        }
      },

      register: async (email: string, password: string, firstName: string, lastName: string, role?: string) => {
        try {
          set({ isLoading: true })
          const response = await authApi.register({ email, password, firstName, lastName, role })
          
          // Store token in localStorage
          if (typeof window !== 'undefined') {
            localStorage.setItem('auth_token', response.access_token)
            localStorage.setItem('user', JSON.stringify(response.user))
          }

          set({
            user: response.user,
            token: response.access_token,
            isAuthenticated: true,
            isLoading: false,
          })

          toast.success('Registration successful!')
        } catch (error: any) {
          set({ isLoading: false })
          const message = error.response?.data?.message || 'Registration failed'
          toast.error(message)
          throw error
        }
      },

      logout: () => {
        if (typeof window !== 'undefined') {
          localStorage.removeItem('auth_token')
          localStorage.removeItem('user')
        }
        set({
          user: null,
          token: null,
          isAuthenticated: false,
        })
        toast.success('Logged out successfully')
      },

      loadProfile: async () => {
        try {
          const profile = await authApi.getProfile()
          set({ user: profile })
        } catch (error) {
          // If profile load fails, user might not be authenticated
          get().logout()
        }
      },

      setUser: (user: User | null) => {
        set({ user, isAuthenticated: !!user })
      },

      setToken: (token: string | null) => {
        set({ token })
        if (typeof window !== 'undefined' && token) {
          localStorage.setItem('auth_token', token)
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
)


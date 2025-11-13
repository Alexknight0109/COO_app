'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuthStore } from '@/lib/store/authStore'

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const { isAuthenticated, isLoading, loadProfile } = useAuthStore()

  useEffect(() => {
    const checkAuth = async () => {
      // Check if token exists in localStorage
      if (typeof window !== 'undefined') {
        const token = localStorage.getItem('auth_token')
        const user = localStorage.getItem('user')

        if (token && user) {
          // Restore auth state from localStorage
          useAuthStore.getState().setToken(token)
          useAuthStore.getState().setUser(JSON.parse(user))
          
          // Try to load profile to verify token is still valid
          try {
            await loadProfile()
          } catch (error) {
            // Token invalid, redirect to login
            router.push('/auth/login')
          }
        } else if (!isAuthenticated && !isLoading) {
          // No token, redirect to login
          router.push('/auth/login')
        }
      }
    }

    checkAuth()
  }, [isAuthenticated, isLoading, router, loadProfile])

  // Show loading state while checking auth
  if (isLoading || (!isAuthenticated && typeof window !== 'undefined' && localStorage.getItem('auth_token'))) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--bg-primary)]">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500 mx-auto mb-4"></div>
          <p className="text-[var(--text-secondary)]">Loading...</p>
        </div>
      </div>
    )
  }

  // If not authenticated, don't render children (will redirect)
  if (!isAuthenticated) {
    return null
  }

  return <>{children}</>
}


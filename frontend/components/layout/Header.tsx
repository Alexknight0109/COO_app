'use client'

import { ThemeToggle } from '@/components/theme/ThemeToggle'
import { BellIcon } from '@heroicons/react/24/outline'
import { useAuthStore } from '@/lib/store/authStore'
import { useRouter } from 'next/navigation'
import { useState } from 'react'

export function Header() {
  const { user, logout } = useAuthStore()
  const router = useRouter()
  const [notifications] = useState(3) // Mock notification count

  const handleLogout = () => {
    logout()
    router.push('/auth/login')
  }

  const userInitials = user
    ? `${user.firstName?.[0] || ''}${user.lastName?.[0] || ''}`.toUpperCase()
    : 'U'

  const userName = user ? `${user.firstName} ${user.lastName}` : 'User'
  const userRole = user?.role || 'User'

  return (
    <header className="bg-[var(--bg-card)] border-b border-[var(--border-color)] sticky top-0 z-50 px-6 py-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h2 className="text-xl font-semibold text-[var(--text-primary)]">
            Welcome Back{user?.firstName ? `, ${user.firstName}` : ''}
          </h2>
        </div>

        <div className="flex items-center gap-4">
          {/* Notifications */}
          <button className="relative p-2 rounded-lg hover:bg-[var(--hover-bg)] transition-colors">
            <BellIcon className="w-6 h-6 text-[var(--text-secondary)]" />
            {notifications > 0 && (
              <span className="absolute top-0 right-0 w-5 h-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center">
                {notifications}
              </span>
            )}
          </button>

          {/* Theme Toggle */}
          <ThemeToggle />

          {/* User Profile */}
          <div className="flex items-center gap-3 pl-4 border-l border-[var(--border-color)]">
            <div className="w-10 h-10 rounded-full gradient-purple-blue flex items-center justify-center text-white font-semibold">
              {userInitials}
            </div>
            <div className="hidden md:block">
              <p className="text-sm font-medium text-[var(--text-primary)]">
                {userName}
              </p>
              <p className="text-xs text-[var(--text-secondary)]">{userRole}</p>
            </div>
            <button
              onClick={handleLogout}
              className="ml-2 px-3 py-1 text-sm text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-lg transition-colors"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    </header>
  )
}

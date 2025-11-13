'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { tasksApi, Task } from '@/lib/api/tasks'
import { messagesApi } from '@/lib/api/messages'
import {
  ClipboardDocumentListIcon,
  ChatBubbleLeftRightIcon,
  CalendarIcon,
  ChartBarIcon,
} from '@heroicons/react/24/outline'

export default function DashboardPage() {
  const [stats, setStats] = useState({
    activeTasks: 0,
    unreadMessages: 0,
    upcomingEvents: 0,
    completedTasks: 0,
  })
  const [recentTasks, setRecentTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadDashboardData()
  }, [])

  const loadDashboardData = async () => {
    try {
      setLoading(true)
      const [tasks, messages] = await Promise.all([
        tasksApi.getAll().catch(() => []),
        messagesApi.getAll().catch(() => []),
      ])

      // Calculate stats
      const activeTasks = tasks.filter(
        (t) => t.status === 'NOT_STARTED' || t.status === 'WORKING' || t.status === 'BLOCKED'
      ).length
      const completedTasks = tasks.filter((t) => t.status === 'COMPLETED').length
      const unreadMessages = messages.filter((m) => !m.isRead).length

      setStats({
        activeTasks,
        unreadMessages,
        upcomingEvents: 0, // Calendar not implemented yet
        completedTasks,
      })

      // Get recent tasks (limit to 5)
      const sortedTasks = tasks
        .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
        .slice(0, 5)
      setRecentTasks(sortedTasks)
    } catch (error) {
      console.error('Failed to load dashboard data:', error)
    } finally {
      setLoading(false)
    }
  }

  const statsData = [
    { label: 'Active Tasks', value: stats.activeTasks.toString(), icon: ClipboardDocumentListIcon, color: 'text-purple-400' },
    { label: 'Unread Messages', value: stats.unreadMessages.toString(), icon: ChatBubbleLeftRightIcon, color: 'text-blue-400' },
    { label: 'Upcoming Events', value: stats.upcomingEvents.toString(), icon: CalendarIcon, color: 'text-green-400' },
    { label: 'Completed Tasks', value: stats.completedTasks.toString(), icon: ChartBarIcon, color: 'text-yellow-400' },
  ]

  const announcements = [
    { id: '1', title: 'New Safety Protocol', message: 'All site workers must attend safety briefing tomorrow at 9 AM.', date: '2024-01-12' },
    { id: '2', title: 'Holiday Schedule', message: 'Factory will be closed next Friday for maintenance.', date: '2024-01-11' },
  ]

  return (
    <ProtectedRoute>
      <div className="flex min-h-screen">
        <Sidebar />
        <div className="flex-1 ml-64">
          <Header />
          <main className="p-6">
            <div className="mb-6">
              <h1 className="text-3xl font-bold text-[var(--text-primary)] mb-2">
                Dashboard
              </h1>
              <p className="text-[var(--text-secondary)]">
                Welcome back! Here's what's happening today.
              </p>
            </div>

            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500"></div>
              </div>
            ) : (
              <>
                {/* Stats Grid */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
                  {statsData.map((stat) => {
                    const Icon = stat.icon
                    return (
                      <Card key={stat.label} hover>
                        <CardHeader>
                          <div className="flex items-center justify-between">
                            <CardTitle className="text-sm font-medium text-[var(--text-secondary)]">
                              {stat.label}
                            </CardTitle>
                            <Icon className={`w-6 h-6 ${stat.color}`} />
                          </div>
                        </CardHeader>
                        <CardContent>
                          <p className="text-3xl font-bold text-[var(--text-primary)]">
                            {stat.value}
                          </p>
                        </CardContent>
                      </Card>
                    )
                  })}
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  {/* Recent Tasks */}
                  <Card>
                    <CardHeader>
                      <CardTitle>Recent Tasks</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {recentTasks.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">
                          No tasks found
                        </p>
                      ) : (
                        <div className="space-y-4">
                          {recentTasks.map((task) => (
                            <div
                              key={task.id}
                              className="p-4 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)] hover:border-purple-500 transition-colors"
                            >
                              <div className="flex items-start justify-between mb-2">
                                <h4 className="font-medium text-[var(--text-primary)]">
                                  {task.title}
                                </h4>
                                <span
                                  className={`px-2 py-1 text-xs rounded-full ${
                                    task.priority === 'URGENT'
                                      ? 'bg-red-500/20 text-red-400'
                                      : task.priority === 'HIGH'
                                      ? 'bg-orange-500/20 text-orange-400'
                                      : task.priority === 'MEDIUM'
                                      ? 'bg-blue-500/20 text-blue-400'
                                      : 'bg-gray-500/20 text-gray-400'
                                  }`}
                                >
                                  {task.priority}
                                </span>
                              </div>
                              <div className="flex items-center justify-between text-sm">
                                <span className="text-[var(--text-secondary)] capitalize">
                                  {task.status.toLowerCase().replace('_', ' ')}
                                </span>
                                <span className="text-[var(--text-secondary)]">
                                  {task.dueDate ? `Due: ${new Date(task.dueDate).toLocaleDateString()}` : 'No due date'}
                                </span>
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </CardContent>
                  </Card>

                  {/* Announcements */}
                  <Card>
                    <CardHeader>
                      <CardTitle>Announcements</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-4">
                        {announcements.map((announcement) => (
                          <div
                            key={announcement.id}
                            className="p-4 bg-gradient-purple-blue/10 rounded-lg border border-purple-500/20"
                          >
                            <h4 className="font-semibold text-[var(--text-primary)] mb-1">
                              {announcement.title}
                            </h4>
                            <p className="text-sm text-[var(--text-secondary)] mb-2">
                              {announcement.message}
                            </p>
                            <p className="text-xs text-[var(--text-secondary)]">
                              {announcement.date}
                            </p>
                          </div>
                        ))}
                      </div>
                    </CardContent>
                  </Card>
                </div>
              </>
            )}
          </main>
        </div>
      </div>
    </ProtectedRoute>
  )
}

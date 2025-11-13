'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { calendarApi, CalendarEvent } from '@/lib/api/calendar'
import toast from 'react-hot-toast'
import { CalendarIcon, ClockIcon, PlusIcon, PencilIcon, TrashIcon } from '@heroicons/react/24/outline'
import { format } from 'date-fns'

export default function CalendarPage() {
  const [events, setEvents] = useState<CalendarEvent[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editingEvent, setEditingEvent] = useState<CalendarEvent | null>(null)
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    startDate: '',
    endDate: '',
    allDay: false,
    type: 'MEETING',
  })

  useEffect(() => {
    loadEvents()
  }, [])

  const loadEvents = async () => {
    try {
      setLoading(true)
      const data = await calendarApi.getAll()
      setEvents(data)
    } catch (error) {
      console.error('Failed to load events:', error)
      toast.error('Failed to load events')
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingEvent) {
        await calendarApi.update(editingEvent.id, formData)
        toast.success('Event updated')
      } else {
        await calendarApi.create(formData)
        toast.success('Event created')
      }
      setShowForm(false)
      setEditingEvent(null)
      setFormData({ title: '', description: '', startDate: '', endDate: '', allDay: false, type: 'MEETING' })
      loadEvents()
    } catch (error) {
      toast.error('Failed to save event')
    }
  }

  const handleEdit = (event: CalendarEvent) => {
    setEditingEvent(event)
    setFormData({
      title: event.title,
      description: event.description || '',
      startDate: event.startDate.split('T')[0],
      endDate: event.endDate?.split('T')[0] || '',
      allDay: event.allDay,
      type: event.type || 'MEETING',
    })
    setShowForm(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this event?')) return
    try {
      await calendarApi.delete(id)
      toast.success('Event deleted')
      loadEvents()
    } catch (error) {
      toast.error('Failed to delete event')
    }
  }

  const upcomingEvents = events
    .filter((e) => new Date(e.startDate) >= new Date())
    .sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime())
    .slice(0, 10)

  return (
    <ProtectedRoute>
      <div className="flex min-h-screen">
        <Sidebar />
        <div className="flex-1 ml-64">
          <Header />
          <main className="p-6">
            <div className="mb-6 flex items-center justify-between">
              <div>
                <h1 className="text-3xl font-bold text-[var(--text-primary)] mb-2">
                  Calendar
                </h1>
                <p className="text-[var(--text-secondary)]">
                  View your schedule and upcoming events
                </p>
              </div>
              <button
                onClick={() => {
                  setShowForm(true)
                  setEditingEvent(null)
                  setFormData({ title: '', description: '', startDate: '', endDate: '', allDay: false, type: 'MEETING' })
                }}
                className="flex items-center gap-2 px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
              >
                <PlusIcon className="w-5 h-5" />
                New Event
              </button>
            </div>

            {showForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingEvent ? 'Edit Event' : 'Create Event'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Title *
                      </label>
                      <input
                        type="text"
                        value={formData.title}
                        onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                        required
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Description
                      </label>
                      <textarea
                        value={formData.description}
                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        rows={3}
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Start Date *
                        </label>
                        <input
                          type="datetime-local"
                          value={formData.startDate}
                          onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                          required
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          End Date
                        </label>
                        <input
                          type="datetime-local"
                          value={formData.endDate}
                          onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                    </div>
                    <div className="flex items-center gap-4">
                      <label className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={formData.allDay}
                          onChange={(e) => setFormData({ ...formData, allDay: e.target.checked })}
                          className="rounded"
                        />
                        <span className="text-sm text-[var(--text-secondary)]">All Day</span>
                      </label>
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        {editingEvent ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowForm(false)
                          setEditingEvent(null)
                        }}
                        className="px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      >
                        Cancel
                      </button>
                    </div>
                  </form>
                </CardContent>
              </Card>
            )}

            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500"></div>
              </div>
            ) : (
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-2">
                  <Card>
                    <CardHeader>
                      <CardTitle>All Events</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {events.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">No events found</p>
                      ) : (
                        <div className="space-y-4">
                          {events.map((event) => (
                            <div
                              key={event.id}
                              className="p-4 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)] hover:border-purple-500 transition-colors"
                            >
                              <div className="flex items-start justify-between">
                                <div className="flex-1">
                                  <h3 className="font-medium text-[var(--text-primary)] mb-1">
                                    {event.title}
                                  </h3>
                                  {event.description && (
                                    <p className="text-sm text-[var(--text-secondary)] mb-2">
                                      {event.description}
                                    </p>
                                  )}
                                  <div className="flex items-center gap-2 text-sm text-[var(--text-secondary)]">
                                    <ClockIcon className="w-4 h-4" />
                                    <span>
                                      {format(new Date(event.startDate), 'MMM d, yyyy h:mm a')}
                                      {event.endDate && ` - ${format(new Date(event.endDate), 'h:mm a')}`}
                                    </span>
                                  </div>
                                </div>
                                <div className="flex gap-2">
                                  <button
                                    onClick={() => handleEdit(event)}
                                    className="p-2 hover:bg-purple-500/20 rounded"
                                  >
                                    <PencilIcon className="w-4 h-4 text-purple-400" />
                                  </button>
                                  <button
                                    onClick={() => handleDelete(event.id)}
                                    className="p-2 hover:bg-red-500/20 rounded"
                                  >
                                    <TrashIcon className="w-4 h-4 text-red-400" />
                                  </button>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </CardContent>
                  </Card>
                </div>

                <div>
                  <Card>
                    <CardHeader>
                      <CardTitle>Upcoming Events</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {upcomingEvents.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">No upcoming events</p>
                      ) : (
                        <div className="space-y-4">
                          {upcomingEvents.map((event) => (
                            <div
                              key={event.id}
                              className="p-4 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)]"
                            >
                              <div className="flex items-start gap-3">
                                <CalendarIcon className="w-5 h-5 text-purple-400 mt-0.5" />
                                <div className="flex-1">
                                  <h3 className="font-medium text-[var(--text-primary)] mb-1">
                                    {event.title}
                                  </h3>
                                  <p className="text-xs text-[var(--text-secondary)]">
                                    {format(new Date(event.startDate), 'MMM d, h:mm a')}
                                  </p>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </CardContent>
                  </Card>
                </div>
              </div>
            )}
          </main>
        </div>
      </div>
    </ProtectedRoute>
  )
}

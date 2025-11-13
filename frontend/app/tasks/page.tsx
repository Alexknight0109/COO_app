'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { DragDropContext, Droppable, Draggable, DropResult } from 'react-beautiful-dnd'
import { tasksApi, Task, CreateTaskDto } from '@/lib/api/tasks'
import toast from 'react-hot-toast'
import { PlusIcon, PencilIcon, TrashIcon } from '@heroicons/react/24/outline'

const taskStatuses = {
  NOT_STARTED: { label: 'Not Started', color: 'bg-gray-500/20 text-gray-400' },
  WORKING: { label: 'Working', color: 'bg-blue-500/20 text-blue-400' },
  BLOCKED: { label: 'Blocked', color: 'bg-red-500/20 text-red-400' },
  REVIEWING: { label: 'Reviewing', color: 'bg-yellow-500/20 text-yellow-400' },
  COMPLETED: { label: 'Completed', color: 'bg-green-500/20 text-green-400' },
}

type TaskStatus = keyof typeof taskStatuses

interface TasksByStatus {
  NOT_STARTED: Task[]
  WORKING: Task[]
  BLOCKED: Task[]
  REVIEWING: Task[]
  COMPLETED: Task[]
}

export default function TasksPage() {
  const [tasks, setTasks] = useState<TasksByStatus>({
    NOT_STARTED: [],
    WORKING: [],
    BLOCKED: [],
    REVIEWING: [],
    COMPLETED: [],
  })
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editingTask, setEditingTask] = useState<Task | null>(null)
  const [formData, setFormData] = useState<CreateTaskDto>({
    title: '',
    description: '',
    priority: 'MEDIUM',
    dueDate: '',
  })

  useEffect(() => {
    loadTasks()
  }, [])

  const loadTasks = async () => {
    try {
      setLoading(true)
      const allTasks = await tasksApi.getAll()
      
      // Group tasks by status
      const grouped: TasksByStatus = {
        NOT_STARTED: [],
        WORKING: [],
        BLOCKED: [],
        REVIEWING: [],
        COMPLETED: [],
      }

      allTasks.forEach((task) => {
        if (task.status in grouped) {
          grouped[task.status as TaskStatus].push(task)
        }
      })

      setTasks(grouped)
    } catch (error) {
      console.error('Failed to load tasks:', error)
      toast.error('Failed to load tasks')
    } finally {
      setLoading(false)
    }
  }

  const onDragEnd = async (result: DropResult) => {
    const { destination, source, draggableId } = result

    if (!destination) return

    if (
      destination.droppableId === source.droppableId &&
      destination.index === source.index
    ) {
      return
    }

    const sourceStatus = source.droppableId as TaskStatus
    const destStatus = destination.droppableId as TaskStatus
    const sourceColumn = tasks[sourceStatus]
    const draggedTask = sourceColumn.find((t) => t.id === draggableId)

    if (!draggedTask) return

    // Optimistically update UI
    const newSourceColumn = Array.from(sourceColumn)
    newSourceColumn.splice(source.index, 1)

    const destColumn = tasks[destStatus]
    const newDestColumn = Array.from(destColumn)
    newDestColumn.splice(destination.index, 0, draggedTask)

    setTasks({
      ...tasks,
      [sourceStatus]: newSourceColumn,
      [destStatus]: newDestColumn,
    })

    // Update task status in backend
    try {
      await tasksApi.updateStatus(draggedTask.id, destStatus)
      toast.success('Task status updated')
    } catch (error) {
      console.error('Failed to update task status:', error)
      toast.error('Failed to update task status')
      // Revert on error
      loadTasks()
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingTask) {
        await tasksApi.update(editingTask.id, formData)
        toast.success('Task updated')
      } else {
        await tasksApi.create(formData)
        toast.success('Task created')
      }
      setShowForm(false)
      setEditingTask(null)
      setFormData({ title: '', description: '', priority: 'MEDIUM', dueDate: '' })
      loadTasks()
    } catch (error) {
      toast.error('Failed to save task')
    }
  }

  const handleEdit = (task: Task) => {
    setEditingTask(task)
    setFormData({
      title: task.title,
      description: task.description || '',
      priority: task.priority,
      dueDate: task.dueDate?.split('T')[0] || '',
    })
    setShowForm(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this task?')) return
    try {
      await tasksApi.delete(id)
      toast.success('Task deleted')
      loadTasks()
    } catch (error) {
      toast.error('Failed to delete task')
    }
  }

  const getAssigneeName = (task: Task) => {
    if (task.assignee) {
      return `${task.assignee.firstName} ${task.assignee.lastName}`
    }
    return 'Unassigned'
  }

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
                  Task Management
                </h1>
                <p className="text-[var(--text-secondary)]">
                  Drag and drop tasks to update their status
                </p>
              </div>
              <button
                onClick={() => {
                  setShowForm(true)
                  setEditingTask(null)
                  setFormData({ title: '', description: '', priority: 'MEDIUM', dueDate: '' })
                }}
                className="flex items-center gap-2 px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
              >
                <PlusIcon className="w-5 h-5" />
                New Task
              </button>
            </div>

            {showForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingTask ? 'Edit Task' : 'Create Task'}</CardTitle>
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
                          Priority
                        </label>
                        <select
                          value={formData.priority}
                          onChange={(e) => setFormData({ ...formData, priority: e.target.value as any })}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        >
                          <option value="LOW">Low</option>
                          <option value="MEDIUM">Medium</option>
                          <option value="HIGH">High</option>
                          <option value="URGENT">Urgent</option>
                        </select>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Due Date
                        </label>
                        <input
                          type="date"
                          value={formData.dueDate}
                          onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })}
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        {editingTask ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowForm(false)
                          setEditingTask(null)
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
              <DragDropContext onDragEnd={onDragEnd}>
                <div className="grid grid-cols-5 gap-4">
                  {Object.entries(taskStatuses).map(([statusKey, status]) => {
                    const statusTasks = tasks[statusKey as TaskStatus]
                    return (
                      <Droppable key={statusKey} droppableId={statusKey}>
                        {(provided, snapshot) => (
                          <div
                            ref={provided.innerRef}
                            {...provided.droppableProps}
                            className={`kanban-column ${
                              snapshot.isDraggingOver ? 'border-purple-500 border-2' : ''
                            }`}
                          >
                            <div className="mb-4">
                              <h3 className="font-semibold text-[var(--text-primary)] mb-2">
                                {status.label}
                              </h3>
                              <span
                                className={`px-2 py-1 text-xs rounded-full ${status.color}`}
                              >
                                {statusTasks.length}
                              </span>
                            </div>

                            {statusTasks.map((task, index) => (
                              <Draggable
                                key={task.id}
                                draggableId={task.id}
                                index={index}
                              >
                                {(provided, snapshot) => (
                                  <div
                                    ref={provided.innerRef}
                                    {...provided.draggableProps}
                                    {...provided.dragHandleProps}
                                    className={`mb-3 p-3 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)] ${
                                      snapshot.isDragging ? 'shadow-lg' : ''
                                    }`}
                                  >
                                    <div className="flex items-start justify-between mb-2">
                                      <h4 className="font-medium text-[var(--text-primary)] flex-1">
                                        {task.title}
                                      </h4>
                                      <div className="flex gap-1 ml-2">
                                        <button
                                          onClick={(e) => {
                                            e.stopPropagation()
                                            handleEdit(task)
                                          }}
                                          className="p-1 hover:bg-purple-500/20 rounded"
                                        >
                                          <PencilIcon className="w-3 h-3 text-purple-400" />
                                        </button>
                                        <button
                                          onClick={(e) => {
                                            e.stopPropagation()
                                            handleDelete(task.id)
                                          }}
                                          className="p-1 hover:bg-red-500/20 rounded"
                                        >
                                          <TrashIcon className="w-3 h-3 text-red-400" />
                                        </button>
                                      </div>
                                    </div>
                                    <div className="flex items-center justify-between text-xs">
                                      <span className="text-[var(--text-secondary)]">
                                        {getAssigneeName(task)}
                                      </span>
                                      <span
                                        className={`px-2 py-0.5 rounded ${
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
                                  </div>
                                )}
                              </Draggable>
                            ))}
                            {provided.placeholder}
                          </div>
                        )}
                      </Droppable>
                    )
                  })}
                </div>
              </DragDropContext>
            )}
          </main>
        </div>
      </div>
    </ProtectedRoute>
  )
}

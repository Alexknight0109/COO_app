'use client'

import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { ProtectedRoute } from '@/components/auth/ProtectedRoute'
import { hrApi, Employee, Department } from '@/lib/api/hr'
import toast from 'react-hot-toast'
import { PlusIcon, PencilIcon, TrashIcon, UserGroupIcon } from '@heroicons/react/24/outline'

export default function HRPage() {
  const [employees, setEmployees] = useState<Employee[]>([])
  const [departments, setDepartments] = useState<Department[]>([])
  const [loading, setLoading] = useState(true)
  const [showEmployeeForm, setShowEmployeeForm] = useState(false)
  const [showDeptForm, setShowDeptForm] = useState(false)
  const [editingEmployee, setEditingEmployee] = useState<Employee | null>(null)
  const [editingDept, setEditingDept] = useState<Department | null>(null)
  const [employeeFormData, setEmployeeFormData] = useState({
    email: '',
    password: '',
    firstName: '',
    lastName: '',
    role: 'GENERAL_STAFF',
    departmentId: '',
  })
  const [deptFormData, setDeptFormData] = useState({
    name: '',
    description: '',
  })

  useEffect(() => {
    loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      const [employeesData, departmentsData] = await Promise.all([
        hrApi.getEmployees(),
        hrApi.getDepartments(),
      ])
      setEmployees(employeesData)
      setDepartments(departmentsData)
    } catch (error) {
      console.error('Failed to load data:', error)
      toast.error('Failed to load data')
    } finally {
      setLoading(false)
    }
  }

  const handleEmployeeSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingEmployee) {
        await hrApi.updateEmployee(editingEmployee.id, employeeFormData)
        toast.success('Employee updated')
      } else {
        await hrApi.createEmployee(employeeFormData)
        toast.success('Employee created')
      }
      setShowEmployeeForm(false)
      setEditingEmployee(null)
      setEmployeeFormData({
        email: '',
        password: '',
        firstName: '',
        lastName: '',
        role: 'GENERAL_STAFF',
        departmentId: '',
      })
      loadData()
    } catch (error) {
      toast.error('Failed to save employee')
    }
  }

  const handleDeptSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingDept) {
        await hrApi.updateDepartment(editingDept.id, deptFormData)
        toast.success('Department updated')
      } else {
        await hrApi.createDepartment(deptFormData)
        toast.success('Department created')
      }
      setShowDeptForm(false)
      setEditingDept(null)
      setDeptFormData({ name: '', description: '' })
      loadData()
    } catch (error) {
      toast.error('Failed to save department')
    }
  }

  const handleDeleteEmployee = async (id: string) => {
    if (!confirm('Are you sure you want to delete this employee?')) return
    try {
      await hrApi.deleteEmployee(id)
      toast.success('Employee deleted')
      loadData()
    } catch (error) {
      toast.error('Failed to delete employee')
    }
  }

  const handleDeleteDept = async (id: string) => {
    if (!confirm('Are you sure you want to delete this department?')) return
    try {
      await hrApi.deleteDepartment(id)
      toast.success('Department deleted')
      loadData()
    } catch (error) {
      toast.error('Failed to delete department')
    }
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
                  HR / Employees
                </h1>
                <p className="text-[var(--text-secondary)]">
                  Manage employee profiles and permissions
                </p>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => {
                    setShowDeptForm(true)
                    setEditingDept(null)
                    setDeptFormData({ name: '', description: '' })
                  }}
                  className="flex items-center gap-2 px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)] hover:border-purple-500"
                >
                  <UserGroupIcon className="w-5 h-5" />
                  New Department
                </button>
                <button
                  onClick={() => {
                    setShowEmployeeForm(true)
                    setEditingEmployee(null)
                    setEmployeeFormData({
                      email: '',
                      password: '',
                      firstName: '',
                      lastName: '',
                      role: 'GENERAL_STAFF',
                      departmentId: '',
                    })
                  }}
                  className="flex items-center gap-2 px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                >
                  <PlusIcon className="w-5 h-5" />
                  New Employee
                </button>
              </div>
            </div>

            {showEmployeeForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingEmployee ? 'Edit Employee' : 'Create Employee'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleEmployeeSubmit} className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          First Name *
                        </label>
                        <input
                          type="text"
                          value={employeeFormData.firstName}
                          onChange={(e) =>
                            setEmployeeFormData({ ...employeeFormData, firstName: e.target.value })
                          }
                          required
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Last Name *
                        </label>
                        <input
                          type="text"
                          value={employeeFormData.lastName}
                          onChange={(e) =>
                            setEmployeeFormData({ ...employeeFormData, lastName: e.target.value })
                          }
                          required
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Email *
                        </label>
                        <input
                          type="email"
                          value={employeeFormData.email}
                          onChange={(e) =>
                            setEmployeeFormData({ ...employeeFormData, email: e.target.value })
                          }
                          required
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        />
                      </div>
                      {!editingEmployee && (
                        <div>
                          <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                            Password *
                          </label>
                          <input
                            type="password"
                            value={employeeFormData.password}
                            onChange={(e) =>
                              setEmployeeFormData({ ...employeeFormData, password: e.target.value })
                            }
                            required
                            minLength={6}
                            className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                          />
                        </div>
                      )}
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Role *
                        </label>
                        <select
                          value={employeeFormData.role}
                          onChange={(e) =>
                            setEmployeeFormData({ ...employeeFormData, role: e.target.value })
                          }
                          required
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        >
                          <option value="GENERAL_STAFF">General Staff</option>
                          <option value="MANAGER">Manager</option>
                          <option value="SITE_ENGINEER">Site Engineer</option>
                          <option value="FACTORY_MANAGER">Factory Manager</option>
                          <option value="ACCOUNTS">Accounts</option>
                          <option value="STOREKEEPER">Storekeeper</option>
                          <option value="SALES">Sales</option>
                          <option value="SERVICE_TEAM">Service Team</option>
                        </select>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                          Department
                        </label>
                        <select
                          value={employeeFormData.departmentId}
                          onChange={(e) =>
                            setEmployeeFormData({ ...employeeFormData, departmentId: e.target.value })
                          }
                          className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        >
                          <option value="">No Department</option>
                          {departments.map((dept) => (
                            <option key={dept.id} value={dept.id}>
                              {dept.name}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        {editingEmployee ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowEmployeeForm(false)
                          setEditingEmployee(null)
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

            {showDeptForm && (
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle>{editingDept ? 'Edit Department' : 'Create Department'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleDeptSubmit} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Name *
                      </label>
                      <input
                        type="text"
                        value={deptFormData.name}
                        onChange={(e) => setDeptFormData({ ...deptFormData, name: e.target.value })}
                        required
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-[var(--text-secondary)] mb-2">
                        Description
                      </label>
                      <textarea
                        value={deptFormData.description}
                        onChange={(e) => setDeptFormData({ ...deptFormData, description: e.target.value })}
                        className="w-full px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg text-[var(--text-primary)]"
                        rows={3}
                      />
                    </div>
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        className="px-4 py-2 gradient-purple-blue rounded-lg text-white font-medium"
                      >
                        {editingDept ? 'Update' : 'Create'}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowDeptForm(false)
                          setEditingDept(null)
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
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div>
                  <Card>
                    <CardHeader>
                      <CardTitle>Employees ({employees.length})</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {employees.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">No employees found</p>
                      ) : (
                        <div className="space-y-2">
                          {employees.map((employee) => (
                            <div
                              key={employee.id}
                              className="p-3 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)]"
                            >
                              <div className="flex items-center justify-between">
                                <div>
                                  <h3 className="font-medium text-[var(--text-primary)]">
                                    {employee.firstName} {employee.lastName}
                                  </h3>
                                  <p className="text-xs text-[var(--text-secondary)]">{employee.email}</p>
                                  <p className="text-xs text-[var(--text-secondary)]">
                                    {employee.role} {employee.department && `• ${employee.department.name}`}
                                  </p>
                                </div>
                                <div className="flex gap-2">
                                  <button
                                    onClick={() => {
                                      setEditingEmployee(employee)
                                      setEmployeeFormData({
                                        email: employee.email,
                                        password: '',
                                        firstName: employee.firstName,
                                        lastName: employee.lastName,
                                        role: employee.role,
                                        departmentId: employee.departmentId || '',
                                      })
                                      setShowEmployeeForm(true)
                                    }}
                                    className="p-1 hover:bg-purple-500/20 rounded"
                                  >
                                    <PencilIcon className="w-4 h-4 text-purple-400" />
                                  </button>
                                  <button
                                    onClick={() => handleDeleteEmployee(employee.id)}
                                    className="p-1 hover:bg-red-500/20 rounded"
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
                      <CardTitle>Departments ({departments.length})</CardTitle>
                    </CardHeader>
                    <CardContent>
                      {departments.length === 0 ? (
                        <p className="text-[var(--text-secondary)] text-center py-8">No departments found</p>
                      ) : (
                        <div className="space-y-2">
                          {departments.map((dept) => (
                            <div
                              key={dept.id}
                              className="p-3 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)]"
                            >
                              <div className="flex items-center justify-between">
                                <div>
                                  <h3 className="font-medium text-[var(--text-primary)]">{dept.name}</h3>
                                  {dept.description && (
                                    <p className="text-xs text-[var(--text-secondary)]">{dept.description}</p>
                                  )}
                                </div>
                                <div className="flex gap-2">
                                  <button
                                    onClick={() => {
                                      setEditingDept(dept)
                                      setDeptFormData({
                                        name: dept.name,
                                        description: dept.description || '',
                                      })
                                      setShowDeptForm(true)
                                    }}
                                    className="p-1 hover:bg-purple-500/20 rounded"
                                  >
                                    <PencilIcon className="w-4 h-4 text-purple-400" />
                                  </button>
                                  <button
                                    onClick={() => handleDeleteDept(dept.id)}
                                    className="p-1 hover:bg-red-500/20 rounded"
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
              </div>
            )}
          </main>
        </div>
      </div>
    </ProtectedRoute>
  )
}

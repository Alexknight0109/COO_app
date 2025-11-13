import apiClient from './client'

export interface Employee {
  id: string
  email: string
  firstName: string
  lastName: string
  role: string
  departmentId?: string
  department?: {
    id: string
    name: string
  }
  createdAt: string
  updatedAt: string
}

export interface Department {
  id: string
  name: string
  description?: string
  createdAt: string
  updatedAt: string
}

export interface CreateEmployeeDto {
  email: string
  password: string
  firstName: string
  lastName: string
  role: string
  departmentId?: string
}

export interface CreateDepartmentDto {
  name: string
  description?: string
}

export const hrApi = {
  getEmployees: async (): Promise<Employee[]> => {
    const response = await apiClient.get<Employee[]>('/hr/employees')
    return response.data
  },

  getEmployeeById: async (id: string): Promise<Employee> => {
    const response = await apiClient.get<Employee>(`/hr/employees/${id}`)
    return response.data
  },

  createEmployee: async (data: CreateEmployeeDto): Promise<Employee> => {
    const response = await apiClient.post<Employee>('/hr/employees', data)
    return response.data
  },

  updateEmployee: async (id: string, data: Partial<CreateEmployeeDto>): Promise<Employee> => {
    const response = await apiClient.patch<Employee>(`/hr/employees/${id}`, data)
    return response.data
  },

  deleteEmployee: async (id: string): Promise<void> => {
    await apiClient.delete(`/hr/employees/${id}`)
  },

  getDepartments: async (): Promise<Department[]> => {
    const response = await apiClient.get<Department[]>('/hr/departments')
    return response.data
  },

  createDepartment: async (data: CreateDepartmentDto): Promise<Department> => {
    const response = await apiClient.post<Department>('/hr/departments', data)
    return response.data
  },

  updateDepartment: async (id: string, data: Partial<CreateDepartmentDto>): Promise<Department> => {
    const response = await apiClient.patch<Department>(`/hr/departments/${id}`, data)
    return response.data
  },

  deleteDepartment: async (id: string): Promise<void> => {
    await apiClient.delete(`/hr/departments/${id}`)
  },
}


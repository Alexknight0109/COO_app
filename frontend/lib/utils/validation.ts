export interface ValidationRule {
  required?: boolean
  minLength?: number
  maxLength?: number
  pattern?: RegExp
  custom?: (value: any) => string | null
  email?: boolean
  number?: boolean
  min?: number
  max?: number
}

export interface ValidationErrors {
  [key: string]: string
}

export function validateField(name: string, value: any, rules: ValidationRule): string | null {
  if (rules.required && (!value || (typeof value === 'string' && value.trim() === ''))) {
    return `${name} is required`
  }

  if (value === null || value === undefined || value === '') {
    return null // Skip other validations if field is empty and not required
  }

  if (rules.minLength && typeof value === 'string' && value.length < rules.minLength) {
    return `${name} must be at least ${rules.minLength} characters`
  }

  if (rules.maxLength && typeof value === 'string' && value.length > rules.maxLength) {
    return `${name} must be no more than ${rules.maxLength} characters`
  }

  if (rules.pattern && typeof value === 'string' && !rules.pattern.test(value)) {
    return `${name} format is invalid`
  }

  if (rules.email && typeof value === 'string') {
    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailPattern.test(value)) {
      return `${name} must be a valid email address`
    }
  }

  if (rules.number) {
    const numValue = typeof value === 'number' ? value : parseFloat(value)
    if (isNaN(numValue)) {
      return `${name} must be a number`
    }
    if (rules.min !== undefined && numValue < rules.min) {
      return `${name} must be at least ${rules.min}`
    }
    if (rules.max !== undefined && numValue > rules.max) {
      return `${name} must be no more than ${rules.max}`
    }
  }

  if (rules.custom) {
    return rules.custom(value)
  }

  return null
}

export function validateForm(
  data: Record<string, any>,
  rules: Record<string, ValidationRule>
): ValidationErrors {
  const errors: ValidationErrors = {}

  Object.keys(rules).forEach((field) => {
    const error = validateField(field, data[field], rules[field])
    if (error) {
      errors[field] = error
    }
  })

  return errors
}


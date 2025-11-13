'use client'

import { useState, useRef } from 'react'
import { PaperClipIcon, XMarkIcon } from '@heroicons/react/24/outline'
import { uploadApi } from '@/lib/api/upload'
import toast from 'react-hot-toast'

interface FileUploadProps {
  onUpload: (urls: string[]) => void
  multiple?: boolean
  accept?: string
  folder?: string
  maxSize?: number // in MB
}

export function FileUpload({ onUpload, multiple = false, accept, folder, maxSize = 10 }: FileUploadProps) {
  const [files, setFiles] = useState<File[]>([])
  const [uploading, setUploading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = Array.from(e.target.files || [])
    
    // Validate file size
    const validFiles = selectedFiles.filter((file) => {
      const fileSizeMB = file.size / (1024 * 1024)
      if (fileSizeMB > maxSize) {
        toast.error(`File ${file.name} is too large. Max size is ${maxSize}MB`)
        return false
      }
      return true
    })

    if (multiple) {
      setFiles([...files, ...validFiles])
    } else {
      setFiles(validFiles.slice(0, 1))
    }
  }

  const handleUpload = async () => {
    if (files.length === 0) return

    try {
      setUploading(true)
      const uploads = multiple
        ? await uploadApi.uploadMultiple(files, folder)
        : [await uploadApi.uploadFile(files[0], folder)]

      const urls = uploads.map((u) => u.url)
      onUpload(urls)
      setFiles([])
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
      toast.success('Files uploaded successfully')
    } catch (error) {
      console.error('Upload failed:', error)
      toast.error('Failed to upload files')
    } finally {
      setUploading(false)
    }
  }

  const removeFile = (index: number) => {
    setFiles(files.filter((_, i) => i !== index))
  }

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2">
        <input
          ref={fileInputRef}
          type="file"
          onChange={handleFileSelect}
          multiple={multiple}
          accept={accept}
          className="hidden"
          id="file-upload"
        />
        <label
          htmlFor="file-upload"
          className="flex items-center gap-2 px-4 py-2 bg-[var(--bg-primary)] border border-[var(--border-color)] rounded-lg cursor-pointer hover:border-purple-500 transition-colors"
        >
          <PaperClipIcon className="w-5 h-5 text-[var(--text-secondary)]" />
          <span className="text-sm text-[var(--text-primary)]">
            {files.length > 0 ? `${files.length} file(s) selected` : 'Select files'}
          </span>
        </label>
        {files.length > 0 && (
          <button
            onClick={handleUpload}
            disabled={uploading}
            className="px-4 py-2 gradient-purple-blue rounded-lg text-white text-sm font-medium disabled:opacity-50"
          >
            {uploading ? 'Uploading...' : 'Upload'}
          </button>
        )}
      </div>

      {files.length > 0 && (
        <div className="space-y-2">
          {files.map((file, index) => (
            <div
              key={index}
              className="flex items-center justify-between p-2 bg-[var(--bg-primary)] rounded-lg border border-[var(--border-color)]"
            >
              <span className="text-sm text-[var(--text-primary)] truncate flex-1">
                {file.name} ({(file.size / (1024 * 1024)).toFixed(2)} MB)
              </span>
              <button
                onClick={() => removeFile(index)}
                className="p-1 hover:bg-red-500/20 rounded"
              >
                <XMarkIcon className="w-4 h-4 text-red-400" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}


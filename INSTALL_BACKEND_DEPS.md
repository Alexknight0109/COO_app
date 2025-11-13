# 📦 Backend Dependencies Installation

## Required Packages

You need to install these packages in the backend for file upload to work:

```bash
cd backend
npm install multer @types/multer uuid @types/uuid
```

## What These Do

- **multer** - Middleware for handling multipart/form-data (file uploads)
- **@types/multer** - TypeScript types for multer
- **uuid** - Generate unique file names
- **@types/uuid** - TypeScript types for uuid

## After Installation

1. Restart the backend server
2. File upload endpoints will be available at:
   - `POST /api/upload` - Single file upload
   - `POST /api/upload/multiple` - Multiple file upload

## File Storage

Files are stored in: `backend/uploads/` directory
- Organized by folder (e.g., `uploads/site-logs/`, `uploads/complaints/`, etc.)
- Files are accessible via: `http://localhost:3001/uploads/[folder]/[filename]`


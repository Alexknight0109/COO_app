# ALMED OPS Control System - Setup Guide

## Prerequisites

- Node.js 18+ and npm
- PostgreSQL 14+
- Git

## Quick Start

### 1. Install Dependencies

From the root directory:
```bash
npm install
```

Or install separately:
```bash
# Backend
cd backend
npm install

# Frontend
cd frontend
npm install
```

### 2. Database Setup

1. Create PostgreSQL database:
```sql
CREATE DATABASE almed_ops;
```

2. Create `.env` file in `backend/` directory:
```bash
cp backend/.env.example backend/.env
```

3. Update `backend/.env` with your database credentials:
```
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=your_password
DB_DATABASE=almed_ops
JWT_SECRET=your-secret-key-change-in-production
PORT=3001
```

### 3. Run the Application

**Option 1: Run both together (from root)**
```bash
npm run dev
```

**Option 2: Run separately**

Terminal 1 (Backend):
```bash
cd backend
npm run start:dev
```

Terminal 2 (Frontend):
```bash
cd frontend
npm run dev
```

### 4. Access the Application

- Frontend: http://localhost:3000
- Backend API: http://localhost:3001/api

## First Time Setup

1. The database schema will be automatically created on first run (synchronize mode is enabled in development)
2. Create your first user via the API:
```bash
POST http://localhost:3001/api/auth/register
{
  "email": "admin@almed.com",
  "password": "password123",
  "firstName": "Admin",
  "lastName": "User",
  "role": "COO"
}
```

## Project Structure

```
COO_app/
├── frontend/          # Next.js frontend
│   ├── app/          # Next.js app router pages
│   ├── components/   # React components
│   └── ...
├── backend/          # NestJS backend
│   ├── src/
│   │   ├── entities/     # TypeORM entities
│   │   ├── modules/      # Feature modules
│   │   └── ...
│   └── ...
└── README.md         # Main documentation
```

## Development Notes

- The backend uses TypeORM with auto-synchronize in development mode
- The frontend uses Next.js 14 with App Router
- Theme system uses CSS variables for dark/light mode
- JWT authentication is used for API security

## Troubleshooting

### Database Connection Issues
- Ensure PostgreSQL is running
- Check database credentials in `.env`
- Verify database exists

### Port Already in Use
- Change PORT in backend `.env` file
- Update FRONTEND_URL in backend `.env` if CORS issues occur

### Module Not Found Errors
- Run `npm install` in both frontend and backend directories
- Clear `node_modules` and reinstall if needed

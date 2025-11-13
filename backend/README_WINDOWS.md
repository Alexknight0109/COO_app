# 🪟 Windows Desktop Setup Guide

## Quick Start for Windows

### Step 1: Install Prerequisites

1. **Node.js** (Required)
   - Download: https://nodejs.org/
   - Install LTS version
   - Restart terminal after installation

2. **PostgreSQL** (Required for database)
   - Download: https://www.postgresql.org/download/windows/
   - Install PostgreSQL
   - Remember your postgres password

3. **Flutter** (Already installed based on earlier commands)
   - Verify: `flutter doctor`

### Step 2: Set Up Database

1. Open PostgreSQL (pgAdmin or psql)
2. Create database:
   ```sql
   CREATE DATABASE almed_ops;
   ```

### Step 3: Configure Backend

1. Edit `backend/.env` file:
   ```
   DB_HOST=localhost
   DB_PORT=5432
   DB_USERNAME=postgres
   DB_PASSWORD=your_postgres_password_here
   DB_DATABASE=almed_ops
   JWT_SECRET=almed-ops-secret-key-change-in-production-2024
   PORT=3001
   ```

### Step 4: Start Backend

**Option A: Use the batch file (Easiest)**
```batch
cd backend
START_BACKEND.bat
```

**Option B: Manual start**
```batch
cd backend
npm install
npm run start:dev
```

Backend will run on: `http://127.0.0.1:3001`

### Step 5: Test Backend API

Open a new terminal:
```batch
cd backend
TEST_API.bat
```

Or manually test:
```batch
curl http://127.0.0.1:3001/api/projects
```

### Step 6: Run Flutter Windows App

**Terminal 1 - Backend (if not running):**
```batch
cd backend
npm run start:dev
```

**Terminal 2 - Flutter App:**
```batch
cd flutter_app
flutter run -d windows
```

### Step 7: Start Both Together

Run from root directory:
```batch
START_ALL.bat
```

## API Endpoints

All endpoints are prefixed with `/api`:

- `GET /api/projects` - Get all projects
- `GET /api/tasks` - Get all tasks
- `GET /api/messages` - Get messages
- `POST /api/auth/register` - Register user
- `POST /api/auth/login` - Login
- And more...

Base URL: `http://127.0.0.1:3001/api`

## Troubleshooting

### Backend won't start
- Check PostgreSQL is running
- Verify database credentials in `.env`
- Check if port 3001 is available: `netstat -ano | findstr :3001`

### Can't connect to API from Flutter
- Make sure backend is running
- Check `baseUrl` in `flutter_app/lib/services/api_service.dart`
- Verify CORS settings in `backend/src/main.ts`

### Database connection errors
- Make sure PostgreSQL is running
- Check database exists: `psql -U postgres -l` (should see `almed_ops`)
- Verify credentials in `.env` file

### Flutter app errors
- Run `flutter pub get` in `flutter_app` directory
- Check `flutter doctor` for issues
- Make sure Windows desktop is enabled: `flutter config --enable-windows-desktop`

## Next Steps

1. ✅ Backend is running
2. ✅ Database is connected
3. ✅ Flutter app can connect to backend
4. ⏳ Test all features in Windows app
5. ⏳ Complete authentication flow
6. ⏳ Add real-time WebSocket features

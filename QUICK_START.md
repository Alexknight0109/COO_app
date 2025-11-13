# 🚀 Quick Start Guide

## Step 1: Install Node.js

If you don't have Node.js installed:

### Windows
1. Download Node.js LTS from: https://nodejs.org/
2. Run the installer
3. Restart your terminal/PowerShell

### Mac
```bash
# Using Homebrew
brew install node

# Or download from https://nodejs.org/
```

### Linux (Ubuntu/Debian)
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Verify installation:**
```bash
node --version
npm --version
```

## Step 2: Install Dependencies

### Option A: Automated Installation (Recommended)

**Windows (PowerShell):**
```powershell
.\install.ps1
```

**Linux/Mac:**
```bash
chmod +x install.sh
./install.sh
```

### Option B: Manual Installation

```bash
# Install root dependencies
npm install

# Install backend dependencies
cd backend
npm install
cd ..

# Install frontend dependencies
cd frontend
npm install
cd ..
```

## Step 3: Set Up Database

### Install PostgreSQL

**Windows:**
1. Download from: https://www.postgresql.org/download/windows/
2. Run the installer
3. Remember your postgres password

**Mac:**
```bash
brew install postgresql
brew services start postgresql
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### Create Database

Open PostgreSQL (psql) and run:
```sql
CREATE DATABASE almed_ops;
```

Or via command line:
```bash
createdb almed_ops
```

## Step 4: Configure Environment

1. Copy the example environment file:
```bash
# Windows PowerShell
Copy-Item backend\.env.example backend\.env

# Linux/Mac
cp backend/.env.example backend/.env
```

2. Edit `backend/.env` with your database credentials:
```env
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=your_postgres_password
DB_DATABASE=almed_ops
JWT_SECRET=your-secret-key-change-in-production
PORT=3001
FRONTEND_URL=http://localhost:3000
```

## Step 5: Run the Application

### Option A: Run Both Together (From Root)

```bash
npm run dev
```

This will start both backend and frontend concurrently.

### Option B: Run Separately (Two Terminals)

**Terminal 1 - Backend:**
```bash
cd backend
npm run start:dev
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm run dev
```

## Step 6: Access the Application

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:3001/api

## Step 7: Create First User

The database schema will be created automatically on first run.

Create your first admin user via API:

```bash
# Using curl
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@almed.com",
    "password": "password123",
    "firstName": "Admin",
    "lastName": "User",
    "role": "COO"
  }'
```

Or use Postman/Thunder Client:
- URL: `POST http://localhost:3001/api/auth/register`
- Body (JSON):
```json
{
  "email": "admin@almed.com",
  "password": "password123",
  "firstName": "Admin",
  "lastName": "User",
  "role": "COO"
}
```

## Troubleshooting

### "npm is not recognized"
- Node.js is not installed or not in PATH
- Restart terminal after installing Node.js
- Verify: `node --version` and `npm --version`

### "Cannot connect to database"
- Make sure PostgreSQL is running
- Check credentials in `backend/.env`
- Verify database exists: `psql -l` (should see `almed_ops`)

### Port already in use
- Change `PORT` in `backend/.env`
- Or kill the process using the port:
  - Windows: `netstat -ano | findstr :3001` then `taskkill /PID <pid> /F`
  - Linux/Mac: `lsof -ti:3001 | xargs kill`

### Module not found errors
- Delete `node_modules` folders and reinstall:
  ```bash
  rm -rf node_modules backend/node_modules frontend/node_modules
  npm install
  cd backend && npm install && cd ..
  cd frontend && npm install && cd ..
  ```

## Need Help?

Check the documentation:
- `README.md` - Main documentation
- `SETUP.md` - Detailed setup guide
- `ARCHITECTURE.md` - System architecture
- `backend/README.md` - Backend API documentation
- `frontend/README.md` - Frontend documentation

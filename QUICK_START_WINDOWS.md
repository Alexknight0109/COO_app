# 🚀 Quick Start - Windows Desktop

## ⚠️ IMPORTANT: Node.js Must Be Installed

**If you see "npm is not recognized" error:**
1. **Install Node.js**: https://nodejs.org/ (Download LTS version)
2. **Restart your terminal/PowerShell** after installation
3. **Verify**: `node --version` and `npm --version` should work

---

## 🎯 Step-by-Step: Start Backend & Test

### **Step 1: Start Backend**

**Option A: Double-click the batch file**
- Double-click `START_BACKEND_NOW.bat` in the root directory
- OR navigate to `backend` folder and double-click `START_BACKEND.bat`

**Option B: Command line**
```batch
cd backend
START_BACKEND.bat
```

**Option C: Manual start**
```batch
cd backend
npm install
npm run start:dev
```

**You should see:**
```
Application is running on: http://localhost:3001
```

### **Step 2: Test API (In a NEW Terminal)**

**Option A: Double-click test file**
- Double-click `TEST_BACKEND_API.bat` in the root directory

**Option B: Command line**
```batch
cd backend
TEST_API.bat
```

**Option C: Manual test**
```batch
curl http://127.0.0.1:3001/api/projects
```

**Expected response:**
- Empty array: `[]` (means backend is working but no projects yet)
- Or JSON with projects data

---

## ✅ Success Indicators

### **Backend Started Successfully:**
- Terminal shows: `Application is running on: http://localhost:3001`
- No error messages about database connection
- Server keeps running (don't close the window)

### **API Test Successful:**
- `curl` returns JSON (even if empty `[]`)
- No connection errors
- Status code 200

---

## 🐛 Troubleshooting

### **"npm is not recognized"**
**Solution:**
1. Install Node.js: https://nodejs.org/
2. Restart terminal/PowerShell
3. Verify: `node --version`

### **"Cannot connect to database"**
**Solution:**
1. Make sure PostgreSQL is running
2. Edit `backend/.env` with correct database password
3. Create database: `CREATE DATABASE almed_ops;`

### **"Port 3001 already in use"**
**Solution:**
```batch
REM Find what's using port 3001
netstat -ano | findstr :3001

REM Kill the process (replace PID with actual number)
taskkill /PID <PID> /F
```

### **Backend starts but API returns error**
- Check database connection in `.env`
- Make sure PostgreSQL is running
- Check if database `almed_ops` exists

---

## 🎯 After Backend Works

1. ✅ Backend is running on `http://127.0.0.1:3001`
2. ✅ API test returns JSON (even if empty)
3. **Next:** Run Flutter Windows app
   ```batch
   cd flutter_app
   flutter run -d windows
   ```

---

## 📋 Quick Commands Reference

```batch
# Start backend
cd backend
START_BACKEND.bat

# Test API (in new terminal)
curl http://127.0.0.1:3001/api/projects

# Run Flutter app (in new terminal)
cd flutter_app
flutter run -d windows

# Or start both together
START_ALL.bat
```

---

**Once backend is running and API test works, you're ready to run Flutter Windows app!** 🚀

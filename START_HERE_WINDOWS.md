# 🚀 START HERE - Windows Desktop

## ⚠️ PREREQUISITE: Node.js Must Be Installed

**You're seeing "npm is not recognized" because Node.js isn't installed or not in PATH.**

### Step 1: Install Node.js

1. **Download Node.js LTS** from: https://nodejs.org/
2. **Install it** (use default settings)
3. **Restart your terminal/PowerShell** after installation
4. **Verify installation:**
   ```batch
   node --version
   npm --version
   ```
   Both commands should work!

---

## 🎯 Once Node.js is Installed

### Step 2: Start Backend

**Open a NEW terminal/PowerShell window:**

```batch
cd C:\dev\software22\COO_app
cd backend
START_BACKEND.bat
```

**OR navigate to backend folder and double-click:**
- `backend\START_BACKEND.bat`

**You should see:**
```
[INFO] Node.js found: v18.x.x (or similar)
[INFO] Starting backend server...
Application is running on: http://localhost:3001
```

**✅ Keep this terminal window OPEN** (backend is running here)

---

### Step 3: Test API

**Open a NEW terminal/PowerShell window:**

```batch
curl http://127.0.0.1:3001/api/projects
```

**Expected response:**
- `[]` (empty array) - ✅ Backend is working!
- OR JSON with projects data

**If you get connection error:**
- Make sure backend is running (Step 2)
- Wait 5-10 seconds after starting backend
- Try again

---

### Step 4: Run Flutter Windows App

**Open a NEW terminal/PowerShell window:**

```batch
cd C:\dev\software22\COO_app
cd flutter_app
flutter run -d windows
```

**Or double-click:**
- `START_ALL.bat` (if backend is already running)

---

## 📋 Quick Checklist

- [ ] Node.js installed and in PATH (`node --version` works)
- [ ] PostgreSQL installed and running
- [ ] Database `almed_ops` created
- [ ] `backend\.env` file configured (with database password)
- [ ] Backend started successfully (`START_BACKEND.bat`)
- [ ] API test works (`curl http://127.0.0.1:3001/api/projects`)
- [ ] Flutter Windows app running (`flutter run -d windows`)

---

## 🔧 If Node.js Still Not Found After Installing

1. **Close ALL terminal windows**
2. **Restart your computer** (ensures PATH is updated)
3. **Open NEW terminal**
4. **Try again:** `node --version`

---

## 🎯 Alternative: Install Node.js Manually

If Node.js installer doesn't add to PATH:

1. Find Node.js installation (usually `C:\Program Files\nodejs\`)
2. Add to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" variable
   - Add: `C:\Program Files\nodejs\`
   - Restart terminal

---

## ✅ Once Everything Works

You'll have:
1. ✅ Backend running on `http://127.0.0.1:3001`
2. ✅ API responding to requests
3. ✅ Flutter Windows app connecting to backend
4. ✅ Projects screen loading from API
5. ✅ Tasks screen loading from API
6. ✅ Full functionality!

---

**After Node.js is installed and backend is running, test the API, then run Flutter Windows app!** 🚀

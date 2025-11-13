# 🪟 Windows Testing Guide - Complete Setup

## ✅ All Backend Endpoints Are Now Fixed!

All CRUD operations have been added to:
- Calendar, Complaints, Factory, Inventory, Accounts, HR, Reports, Sites

## 🚀 Quick Start (Windows)

### Step 1: Start Backend

**Open PowerShell or Command Prompt:**

```powershell
cd C:\dev\software22\COO_app\backend
npm run start:dev
```

**OR double-click:**
- `backend\START_BACKEND.bat`

**You should see:**
```
Application is running on: http://localhost:3001
```

**✅ Keep this window open!** (Backend is running here)

---

### Step 2: Start Frontend (New Terminal)

**Open a NEW PowerShell/Command Prompt window:**

```powershell
cd C:\dev\software22\COO_app\frontend
npm run dev
```

**You should see:**
```
  ▲ Next.js 14.x.x
  - Local:        http://localhost:3000
```

**✅ Keep this window open too!**

---

### Step 3: Test in Browser

1. **Open your browser:**
   - Go to: `http://localhost:3000`

2. **Login/Register:**
   - If you don't have an account, click "Register"
   - Create a new account
   - Login with your credentials

3. **Test Each Page:**
   - **Dashboard** - Should show stats (may be 0 if no data)
   - **Projects** - Click "New Project" to create one
   - **Tasks** - Create a task, drag to change status
   - **Calendar** - Create an event
   - **Site Logs** - Create a site, then create logs
   - **Complaints** - Create a complaint
   - **Factory** - Create production entry
   - **Inventory** - Create inventory item
   - **Accounts** - Create account
   - **HR** - Create employee or department
   - **Reports** - Create report

---

## 🔍 Verify Everything Works

### Check Backend is Running:
```powershell
# In a new terminal
curl http://localhost:3001/api/projects
```

**Expected:** `[]` (empty array) or JSON data

### Check Frontend is Running:
- Open browser: `http://localhost:3000`
- Should see login page or dashboard

### Check Browser Console:
1. Press `F12` in browser
2. Go to **Console** tab
3. Look for any **red errors**
4. Go to **Network** tab
5. Try creating an item
6. Check if API calls succeed (status 200/201)

---

## 🐛 Troubleshooting

### Backend Won't Start

**Error: "Cannot connect to database"**
```powershell
# Check PostgreSQL is running
# Edit backend\.env with correct password
# Make sure database exists:
# CREATE DATABASE almed_ops;
```

**Error: "npm is not recognized"**
- Install Node.js: https://nodejs.org/
- Restart terminal after installation
- Verify: `node --version`

**Error: "Port 3001 already in use"**
```powershell
# Find and kill process using port 3001
netstat -ano | findstr :3001
taskkill /PID <PID_NUMBER> /F
```

### Frontend Won't Start

**Error: "Port 3000 already in use"**
```powershell
# Find and kill process using port 3000
netstat -ano | findstr :3000
taskkill /PID <PID_NUMBER> /F
```

**Error: "Module not found"**
```powershell
cd frontend
npm install
```

### Pages Show Empty/No Data

1. **Check backend is running** (Step 1)
2. **Check browser console** (F12) for errors
3. **Check Network tab** - Are API calls failing?
4. **Try creating a new item** - Does it save?

### API Calls Fail (404/500 errors)

1. **Restart backend** - New endpoints need server restart
2. **Check backend terminal** - Any error messages?
3. **Verify database connection** - Check backend logs
4. **Check CORS** - Should be configured in `backend/src/main.ts`

---

## 📋 Quick Checklist

- [ ] Backend running on `http://localhost:3001`
- [ ] Frontend running on `http://localhost:3000`
- [ ] Can login/register
- [ ] Dashboard loads (may show 0s if no data)
- [ ] Can create items on any page
- [ ] Can edit items
- [ ] Can delete items
- [ ] No errors in browser console (F12)
- [ ] API calls succeed in Network tab

---

## 🎯 What Should Work Now

✅ **All pages can:**
- Load data from backend
- Create new records
- Update existing records
- Delete records
- Show proper error messages

✅ **All modules have full CRUD:**
- Calendar, Complaints, Factory, Inventory
- Accounts, HR, Reports, Sites
- Tasks, Projects, Messages

---

## 💡 Pro Tips

1. **Keep both terminals open** - Backend and Frontend need to run simultaneously
2. **Hard refresh browser** - `Ctrl + Shift + R` to clear cache
3. **Check both terminals** - Errors show in terminal windows
4. **Start with Dashboard** - Easiest to verify connection
5. **Create test data** - Use "New" buttons to add items

---

## 🚨 Still Not Working?

1. **Check backend terminal** - Any error messages?
2. **Check frontend terminal** - Any build errors?
3. **Check browser console** (F12) - Any JavaScript errors?
4. **Check Network tab** - Are API calls reaching backend?
5. **Verify database** - Is PostgreSQL running?

**All endpoints are now implemented - if something doesn't work, it's likely a connection or configuration issue!**


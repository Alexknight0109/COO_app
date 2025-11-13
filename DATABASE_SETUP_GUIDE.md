# 🗄️ Database Setup Guide

## Current Status

✅ **PostgreSQL is installed** (version 18.1 found)  
❌ **Database connection failed** - Password authentication issue  
❌ **Backend not starting** - Needs database connection

---

## 🔧 Quick Fix: Set Up Database

### **Option 1: Using pgAdmin (Easiest)**

1. **Open pgAdmin** from Start Menu
2. **Connect to PostgreSQL server:**
   - Enter your PostgreSQL password (the one you set during installation)
3. **Create database:**
   - Right-click on "Databases" → "Create" → "Database"
   - Name: `almed_ops`
   - Click "Save"

### **Option 2: Using Command Line**

1. **Open Command Prompt or PowerShell**
2. **Run the setup script:**
   ```batch
   SETUP_DATABASE.bat
   ```
3. **Enter your PostgreSQL password when prompted**

### **Option 3: Manual psql Command**

1. **Open Command Prompt**
2. **Navigate to PostgreSQL bin:**
   ```batch
   cd "C:\Program Files\PostgreSQL\18\bin"
   ```
3. **Run:**
   ```batch
   psql -U postgres
   ```
4. **Enter your password**
5. **Create database:**
   ```sql
   CREATE DATABASE almed_ops;
   \q
   ```

---

## 🔑 Update Backend Configuration

After creating the database, update `backend/.env`:

1. **Open:** `backend/.env`
2. **Update this line:**
   ```
   DB_PASSWORD=your_actual_postgres_password
   ```
   Replace `your_actual_postgres_password` with the password you set during PostgreSQL installation.

---

## 🚀 Start Backend

After database is created and .env is updated:

**Option 1: Use the script**
```batch
cd backend
SETUP_AND_START.bat
```

**Option 2: Manual start**
```batch
cd backend
npm run start:dev
```

**You should see:**
```
Application is running on: http://localhost:3001
```

---

## ✅ Test API

Once backend is running:

```batch
curl http://127.0.0.1:3001/api/projects
```

Should return: `[]` or JSON data

---

## 🐛 Troubleshooting

### **"Password authentication failed"**
- Make sure you're using the correct PostgreSQL password
- Check if PostgreSQL service is running
- Try connecting with pgAdmin first to verify password

### **"Database does not exist"**
- Create database using one of the methods above
- Verify database name is exactly `almed_ops`

### **"Connection refused"**
- Make sure PostgreSQL service is running
- Check if port 5432 is available
- Verify `DB_HOST=localhost` in .env

---

## 📋 Checklist

- [ ] PostgreSQL service is running
- [ ] Database `almed_ops` created
- [ ] `backend/.env` updated with correct password
- [ ] Backend starts without errors
- [ ] API test works (`curl http://127.0.0.1:3001/api/projects`)

---

**Once database is set up and backend is running, you can start the Flutter Windows app!** 🚀

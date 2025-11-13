# ⚡ Quick Fix - Get Backend Running

## What I Found

✅ PostgreSQL installed (version 18.1)  
✅ Node.js working  
✅ Dependencies installed  
❌ **Database password authentication failed**  
❌ **Backend needs database connection**

---

## 🎯 Do This Now (3 Steps)

### **Step 1: Create Database**

**Easiest way - Use pgAdmin:**
1. Open **pgAdmin** from Start Menu
2. Connect to PostgreSQL (enter your password)
3. Right-click "Databases" → "Create" → "Database"
4. Name: `almed_ops`
5. Click "Save"

**OR use the script:**
```batch
SETUP_DATABASE.bat
```
(Will prompt for your PostgreSQL password)

---

### **Step 2: Update Password in .env**

1. Open `backend/.env` file
2. Find this line:
   ```
   DB_PASSWORD=postgres
   ```
3. Change it to your actual PostgreSQL password:
   ```
   DB_PASSWORD=your_actual_password_here
   ```

---

### **Step 3: Start Backend**

```batch
cd backend
SETUP_AND_START.bat
```

**OR manually:**
```batch
cd backend
npm run start:dev
```

**Look for:**
```
Application is running on: http://localhost:3001
```

---

## ✅ Then Test

```batch
curl http://127.0.0.1:3001/api/projects
```

**Should return:** `[]` (empty array = working!)

---

## 🚀 Then Run Flutter

Once backend is running:

```batch
cd flutter_app
flutter run -d windows
```

---

**That's it! Just 3 steps and you're ready to go!** 🎉

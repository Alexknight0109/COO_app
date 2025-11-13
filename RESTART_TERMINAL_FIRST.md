# ⚠️ IMPORTANT: Restart Your Terminal First!

## 🔄 Node.js Installed But Not Recognized?

**This happens because your current terminal session doesn't know about Node.js yet.**

### **Solution: Restart Your Terminal**

1. **Close this terminal/PowerShell window completely**
2. **Open a NEW terminal/PowerShell window**
3. **Then try again:**
   ```batch
   node --version
   npm --version
   ```

Both commands should work now!

---

## 🚀 Then Start Backend

**After restarting terminal, run:**

```batch
cd C:\dev\software22\COO_app
cd backend
START_BACKEND.bat
```

**Or double-click:**
- `backend\START_BACKEND.bat`

---

## ✅ Verify Node.js Works

**In your NEW terminal, run:**
```batch
node --version
npm --version
```

**You should see version numbers like:**
```
v18.17.0
9.6.7
```

**If you still see "not recognized":**
1. Restart your computer (ensures PATH is fully updated)
2. Then try again

---

## 🎯 Quick Steps

1. ✅ **Close this terminal window**
2. ✅ **Open NEW terminal**
3. ✅ **Verify:** `node --version` works
4. ✅ **Start backend:** `cd backend && START_BACKEND.bat`
5. ✅ **Test API:** `curl http://127.0.0.1:3001/api/projects`
6. ✅ **Run Flutter:** `cd flutter_app && flutter run -d windows`

---

**Once you restart terminal and Node.js works, the backend will start successfully!** 🚀

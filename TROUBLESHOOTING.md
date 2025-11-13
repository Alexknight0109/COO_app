# 🔧 Troubleshooting Guide

## Issue: "Nothing Working" - Site Logs Page Empty

### Problem
The Site Logs page shows an empty screen with an X mark, indicating the page isn't loading data.

### Root Cause
The backend was missing several API endpoints that the frontend was trying to call:
- `POST /api/sites` - Create site
- `PATCH /api/sites/:id` - Update site  
- `DELETE /api/sites/:id` - Delete site
- `GET /api/sites/:id/logs` - Get logs for a site
- `POST /api/sites/logs` - Create a site log

### ✅ Solution Applied

1. **Added Missing Backend Endpoints:**
   - Updated `backend/src/modules/sites/sites.controller.ts` with all CRUD operations
   - Updated `backend/src/modules/sites/sites.service.ts` with all service methods
   - Created DTOs: `create-site.dto.ts`, `update-site.dto.ts`, `create-site-log.dto.ts`

2. **Fixed Entity Issues:**
   - Made `userId` nullable in `SiteLog` entity (since auth is optional for now)
   - Made `workDone` nullable in `SiteLog` entity

3. **Backend Endpoints Now Available:**
   ```
   GET    /api/sites              - Get all sites
   GET    /api/sites/:id          - Get site by ID
   POST   /api/sites               - Create site
   PATCH  /api/sites/:id           - Update site
   DELETE /api/sites/:id           - Delete site
   GET    /api/sites/:id/logs       - Get logs for a site
   POST   /api/sites/logs          - Create a site log
   ```

### How to Verify It's Working

1. **Start the Backend:**
   ```powershell
   cd backend
   npm run start:dev
   ```
   Should see: `Application is running on: http://localhost:3001`

2. **Start the Frontend:**
   ```powershell
   cd frontend
   npm run dev
   ```
   Should see: `Ready on http://localhost:3000`

3. **Test the Site Logs Page:**
   - Navigate to http://localhost:3000/site-logs
   - You should see:
     - Left sidebar with sites list (or "No sites found")
     - Right side showing logs (or "Select a site to view logs")
   - Click "New Site" to create a site
   - Select a site to view/create logs

4. **Check Browser Console:**
   - Open DevTools (F12)
   - Check Console tab for any errors
   - Check Network tab to see API calls

### Common Issues

#### Issue 1: Backend Not Running
**Symptom:** Network errors in browser console, "Failed to load sites"

**Solution:**
- Make sure backend is running on port 3001
- Check `backend/.env` file exists and has correct database config
- Verify database is running and accessible

#### Issue 2: Database Connection Error
**Symptom:** Backend crashes with database connection error

**Solution:**
- Check PostgreSQL is running
- Verify `backend/.env` has correct database credentials:
  ```
  DB_HOST=localhost
  DB_PORT=5432
  DB_USERNAME=postgres
  DB_PASSWORD=your_password
  DB_DATABASE=almed_ops
  ```
- Make sure database `almed_ops` exists

#### Issue 3: CORS Errors
**Symptom:** CORS errors in browser console

**Solution:**
- Backend CORS is already configured in `backend/src/main.ts`
- Make sure frontend is accessing `http://localhost:3000`
- Check `NEXT_PUBLIC_API_URL` in `frontend/.env.local` (if exists)

#### Issue 4: 401 Unauthorized Errors
**Symptom:** All API calls return 401

**Solution:**
- Make sure you're logged in
- Check `localStorage` has `auth_token`
- Try logging in again at `/auth/login`

#### Issue 5: Empty Page After Login
**Symptom:** Page loads but shows empty content

**Solution:**
- Check browser console for JavaScript errors
- Check Network tab - are API calls succeeding?
- Try creating a site first (click "New Site" button)
- Refresh the page

### Debugging Steps

1. **Check Backend Logs:**
   - Look at the terminal where backend is running
   - Check for any error messages
   - Verify endpoints are being hit

2. **Check Frontend Console:**
   - Open browser DevTools (F12)
   - Check Console for errors
   - Check Network tab for failed requests

3. **Test API Directly:**
   ```bash
   # Test if backend is running
   curl http://localhost:3001/api/sites
   
   # Test with authentication (if needed)
   curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3001/api/sites
   ```

4. **Verify Database:**
   ```sql
   -- Connect to PostgreSQL
   psql -U postgres -d almed_ops
   
   -- Check if tables exist
   \dt
   
   -- Check sites table
   SELECT * FROM sites;
   
   -- Check site_logs table
   SELECT * FROM site_logs;
   ```

### Next Steps

If the page is still not working:

1. **Check all error messages** in browser console and backend logs
2. **Verify database** has the required tables
3. **Test API endpoints** directly using curl or Postman
4. **Check network connectivity** between frontend and backend
5. **Verify environment variables** are set correctly

### Files Changed

- ✅ `backend/src/modules/sites/sites.controller.ts` - Added all endpoints
- ✅ `backend/src/modules/sites/sites.service.ts` - Added all service methods
- ✅ `backend/src/modules/sites/dto/create-site.dto.ts` - Created
- ✅ `backend/src/modules/sites/dto/update-site.dto.ts` - Created
- ✅ `backend/src/modules/sites/dto/create-site-log.dto.ts` - Created
- ✅ `backend/src/entities/site-log.entity.ts` - Made userId and workDone nullable

The backend should now have all the endpoints needed for the Site Logs page to work!


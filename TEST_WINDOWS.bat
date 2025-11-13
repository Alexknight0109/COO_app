@echo off
echo ========================================
echo Windows Testing - Verify Setup
echo ========================================
echo.

echo [1] Checking Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found!
    echo Please install from: https://nodejs.org/
    pause
    exit /b 1
)
echo [OK] Node.js found
node --version
echo.

echo [2] Checking if backend is running...
curl -s http://localhost:3001/api/projects >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Backend is running on port 3001
) else (
    echo [WARNING] Backend not responding on port 3001
    echo           Start it with: cd backend ^&^& npm run start:dev
)
echo.

echo [3] Checking if frontend is running...
curl -s http://localhost:3000 >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Frontend is running on port 3000
) else (
    echo [WARNING] Frontend not responding on port 3000
    echo           Start it with: cd frontend ^&^& npm run dev
)
echo.

echo ========================================
echo Testing Complete
echo ========================================
echo.
echo Next steps:
echo 1. If backend not running: cd backend ^&^& npm run start:dev
echo 2. If frontend not running: cd frontend ^&^& npm run dev
echo 3. Open browser: http://localhost:3000
echo.
pause


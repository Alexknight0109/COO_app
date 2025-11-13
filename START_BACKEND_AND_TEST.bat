@echo off
echo ========================================
echo ALMED OPS - Start Backend & Test API
echo ========================================
echo.

REM Check if Node.js is in PATH
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not found in PATH!
    echo.
    echo Please do the following:
    echo   1. Close this terminal window
    echo   2. Open a NEW terminal window
    echo   3. Run this script again
    echo.
    echo OR restart your computer if Node.js was just installed.
    echo.
    pause
    exit /b 1
)

echo [OK] Node.js found:
node --version
npm --version
echo.

REM Navigate to backend directory
cd /d %~dp0backend

REM Check if node_modules exists
if not exist "node_modules" (
    echo [INFO] Installing dependencies...
    echo.
    call npm install
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install dependencies!
        pause
        exit /b 1
    )
    echo.
)

REM Check if .env exists
if not exist ".env" (
    echo [WARNING] .env file not found!
    echo Creating default .env...
    (
        echo DB_HOST=localhost
        echo DB_PORT=5432
        echo DB_USERNAME=postgres
        echo DB_PASSWORD=postgres
        echo DB_DATABASE=almed_ops
        echo JWT_SECRET=almed-ops-secret-key-change-in-production-2024
        echo PORT=3001
        echo NODE_ENV=development
    ) > .env
    echo [IMPORTANT] Please edit .env with your database credentials!
    echo.
    pause
)

echo [INFO] Starting backend server...
echo.
echo Backend will run on: http://127.0.0.1:3001
echo API endpoints: http://127.0.0.1:3001/api
echo.
echo Waiting 5 seconds for server to start...
echo.

REM Start the server in background
start "ALMED Backend" cmd /k "npm run start:dev"

REM Wait for server to start
timeout /t 8 /nobreak >nul

echo.
echo ========================================
echo Testing API...
echo ========================================
echo.

echo Testing: GET http://127.0.0.1:3001/api/projects
curl http://127.0.0.1:3001/api/projects
echo.
echo.

echo Testing: GET http://127.0.0.1:3001/api/tasks
curl http://127.0.0.1:3001/api/tasks
echo.
echo.

echo ========================================
echo Test Complete!
echo ========================================
echo.
echo Backend should be running in a separate window.
echo.
echo Now you can run Flutter Windows app:
echo   cd flutter_app
echo   flutter run -d windows
echo.
pause

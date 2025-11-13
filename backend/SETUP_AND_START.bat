@echo off
echo ========================================
echo ALMED OPS Backend - Setup and Start
echo ========================================
echo.

REM Check Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found in PATH!
    echo Please restart terminal after installing Node.js.
    pause
    exit /b 1
)

echo [OK] Node.js found
node --version
echo.

REM Check if .env exists
if not exist ".env" (
    echo [INFO] Creating .env file...
    (
        echo DB_HOST=localhost
        echo DB_PORT=5432
        echo DB_USERNAME=postgres
        echo DB_PASSWORD=postgres
        echo DB_DATABASE=almed_ops
        echo JWT_SECRET=almed-ops-secret-key-change-in-production-2024
        echo JWT_EXPIRES_IN=7d
        echo PORT=3001
        echo NODE_ENV=development
        echo FRONTEND_URL=http://localhost:3000
        echo LOG_LEVEL=debug
    ) > .env
    echo.
    echo [IMPORTANT] Please edit .env and update DB_PASSWORD with your PostgreSQL password!
    echo.
    pause
)

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

echo [INFO] Starting backend server...
echo.
echo Backend will run on: http://127.0.0.1:3001
echo API endpoints: http://127.0.0.1:3001/api
echo.
echo If you see database connection errors:
echo   - Make sure PostgreSQL is running
echo   - Update DB_PASSWORD in .env file
echo   - Make sure database 'almed_ops' exists
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the server
call npm run start:dev

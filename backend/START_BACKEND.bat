@echo off
echo ========================================
echo ALMED OPS Backend Server
echo ========================================
echo.

REM Check if Node.js is installed
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed!
    echo.
    echo Please install Node.js from: https://nodejs.org/
    echo Then restart this script.
    pause
    exit /b 1
)

echo [INFO] Node.js found:
node --version
echo.

REM Check if .env exists
if not exist ".env" (
    echo [WARNING] .env file not found!
    echo.
    echo Copying .env.example to .env
    if exist ".env.example" (
        copy .env.example .env
        echo.
        echo [IMPORTANT] Please edit .env with your database credentials!
        echo.
        pause
    ) else (
        echo [ERROR] .env.example not found!
        pause
        exit /b 1
    )
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
echo Backend will run on: http://localhost:3001
echo API endpoints: http://localhost:3001/api
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the server
npm run start:dev

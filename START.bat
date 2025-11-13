@echo off
REM ALMED OPS Control System - Quick Start Script for Windows
echo ========================================
echo ALMED OPS Control System
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
if not exist "backend\.env" (
    echo [WARNING] backend\.env not found!
    echo.
    echo Copying backend\.env.example to backend\.env
    copy backend\.env.example backend\.env
    echo.
    echo [IMPORTANT] Please edit backend\.env with your database credentials!
    echo.
    pause
)

echo Starting application...
echo.
echo Backend will run on: http://localhost:3001
echo Frontend will run on: http://localhost:3000
echo.
echo Press Ctrl+C to stop both servers
echo.

REM Start both servers concurrently
npm run dev

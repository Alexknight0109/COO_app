@echo off
echo ========================================
echo ALMED OPS Control System - Windows Startup
echo ========================================
echo.

REM Check if Node.js is installed
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed!
    echo Please install Node.js from: https://nodejs.org/
    pause
    exit /b 1
)

REM Check if Flutter is installed
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed!
    echo Please install Flutter from: https://flutter.dev/
    pause
    exit /b 1
)

echo [INFO] Starting backend server...
echo.
start "ALMED Backend" cmd /k "cd backend && START_BACKEND.bat"

echo [INFO] Waiting for backend to start...
timeout /t 5 /nobreak >nul

echo [INFO] Starting Flutter Windows app...
echo.
cd flutter_app
flutter run -d windows

pause

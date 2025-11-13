@echo off
echo ========================================
echo Starting Backend and Frontend (Windows)
echo ========================================
echo.

REM Check Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found!
    echo Please install from: https://nodejs.org/
    pause
    exit /b 1
)

echo [INFO] Starting Backend...
start "ALMED Backend" cmd /k "cd /d %~dp0backend && npm run start:dev"

echo [INFO] Waiting 5 seconds for backend to start...
timeout /t 5 /nobreak >nul

echo [INFO] Starting Frontend...
start "ALMED Frontend" cmd /k "cd /d %~dp0frontend && npm run dev"

echo.
echo [OK] Both servers starting in separate windows
echo.
echo Backend:  http://localhost:3001
echo Frontend: http://localhost:3000
echo.
echo Open your browser to: http://localhost:3000
echo.
pause


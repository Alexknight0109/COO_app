@echo off
echo ========================================
echo ALMED OPS Backend - Starting...
echo ========================================
echo.

cd /d %~dp0backend

REM Add Node.js to PATH
set PATH=%PATH%;C:\Program Files\nodejs

echo [INFO] Current directory: %CD%
echo [INFO] Node.js version:
node --version
echo.

echo [INFO] Starting backend server...
echo Backend will run on: http://127.0.0.1:3001
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the server
call npm run start:dev

pause
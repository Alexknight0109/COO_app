@echo off
echo ========================================
echo ALMED OPS - Starting Flutter Windows App
echo ========================================
echo.

cd /d %~dp0flutter_app

echo [INFO] Starting Flutter Windows app...
echo.
echo Make sure backend is running on http://127.0.0.1:3001
echo.

flutter run -d windows

pause

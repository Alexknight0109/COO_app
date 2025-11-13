@echo off
echo ========================================
echo Testing Backend API
echo ========================================
echo.

echo Testing: GET http://127.0.0.1:3001/api/projects
echo.
curl http://127.0.0.1:3001/api/projects
echo.
echo.

echo Testing: GET http://127.0.0.1:3001/api/tasks
echo.
curl http://127.0.0.1:3001/api/tasks
echo.
echo.

echo Testing: GET http://127.0.0.1:3001/api/auth/profile
echo.
curl http://127.0.0.1:3001/api/auth/profile
echo.
echo.

echo ========================================
echo API Test Complete
echo ========================================
echo.
pause

@echo off
echo ========================================
echo Testing Backend API
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

echo Testing: POST http://127.0.0.1:3001/api/auth/register
curl -X POST http://127.0.0.1:3001/api/auth/register -H "Content-Type: application/json" -d "{\"email\":\"admin@almed.com\",\"password\":\"password123\",\"firstName\":\"Admin\",\"lastName\":\"User\",\"role\":\"COO\"}"
echo.
echo.

pause

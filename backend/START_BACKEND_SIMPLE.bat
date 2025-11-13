@echo off
REM Simple backend starter - assumes everything is set up
echo Starting ALMED OPS Backend...
echo.

cd /d %~dp0

REM Add Node.js to PATH if not already there
set PATH=%PATH%;C:\Program Files\nodejs

REM Start backend
call npm run start:dev

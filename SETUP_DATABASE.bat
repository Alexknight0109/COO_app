@echo off
echo ========================================
echo ALMED OPS - Database Setup
echo ========================================
echo.

REM Find PostgreSQL installation
set PG_PATH=
for /d %%i in ("C:\Program Files\PostgreSQL\*") do (
    if exist "%%i\bin\psql.exe" (
        set PG_PATH=%%i\bin
        goto :found
    )
)

:found
if "%PG_PATH%"=="" (
    echo [ERROR] PostgreSQL not found!
    echo Please make sure PostgreSQL is installed.
    pause
    exit /b 1
)

echo [INFO] PostgreSQL found at: %PG_PATH%
echo.

echo ========================================
echo Creating Database: almed_ops
echo ========================================
echo.
echo You will be prompted for your PostgreSQL password.
echo (This is the password you set during PostgreSQL installation)
echo.

REM Add PostgreSQL to PATH
set PATH=%PATH%;%PG_PATH%

REM Try to create database
echo Creating database...
psql -U postgres -c "CREATE DATABASE almed_ops;" 2>nul

if %errorlevel% equ 0 (
    echo.
    echo [SUCCESS] Database 'almed_ops' created successfully!
) else (
    echo.
    echo [INFO] Checking if database already exists...
    psql -U postgres -c "SELECT 1 FROM pg_database WHERE datname = 'almed_ops';" -t 2>nul | findstr /C:"1" >nul
    if %errorlevel% equ 0 (
        echo [INFO] Database 'almed_ops' already exists!
    ) else (
        echo [ERROR] Failed to create database.
        echo.
        echo Please create it manually:
        echo   1. Open pgAdmin
        echo   2. Connect to PostgreSQL server
        echo   3. Right-click "Databases" -^> "Create" -^> "Database"
        echo   4. Name: almed_ops
        echo   5. Click "Save"
    )
)

echo.
echo ========================================
echo Next Steps:
echo ========================================
echo.
echo 1. Update backend/.env with your PostgreSQL password
echo 2. Start backend: cd backend ^&^& npm run start:dev
echo.
pause
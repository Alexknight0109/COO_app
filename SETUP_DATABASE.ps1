# ALMED OPS Database Setup Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ALMED OPS - Database Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find psql
$psqlPath = Get-ChildItem "C:\Program Files\PostgreSQL" -Recurse -Filter "psql.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $psqlPath) {
    Write-Host "✗ PostgreSQL psql not found!" -ForegroundColor Red
    Write-Host "Please make sure PostgreSQL is installed." -ForegroundColor Yellow
    exit 1
}

$psqlDir = Split-Path $psqlPath.FullName
$env:PATH += ";$psqlDir"
Write-Host "✓ Found PostgreSQL at: $($psqlPath.FullName)" -ForegroundColor Green
Write-Host ""

# Get PostgreSQL password
Write-Host "Enter your PostgreSQL password (the one you set during installation):" -ForegroundColor Yellow
$securePassword = Read-Host -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))

if ([string]::IsNullOrWhiteSpace($password)) {
    Write-Host "✗ Password cannot be empty!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Creating database 'almed_ops'..." -ForegroundColor Yellow

# Set password for psql
$env:PGPASSWORD = $password

# Check if database exists
$dbExists = psql -U postgres -h localhost -tAc "SELECT 1 FROM pg_database WHERE datname='almed_ops';" 2>&1

if ($dbExists -match "1") {
    Write-Host "✓ Database 'almed_ops' already exists!" -ForegroundColor Green
} else {
    # Create database
    $result = psql -U postgres -h localhost -c "CREATE DATABASE almed_ops;" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database 'almed_ops' created successfully!" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create database!" -ForegroundColor Red
        Write-Host "Error: $result" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please check:" -ForegroundColor Yellow
        Write-Host "  1. PostgreSQL service is running" -ForegroundColor Yellow
        Write-Host "  2. Password is correct" -ForegroundColor Yellow
        Write-Host "  3. You have permission to create databases" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Updating backend/.env file..." -ForegroundColor Yellow

# Update .env file
$envContent = @"
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=$password
DB_DATABASE=almed_ops
JWT_SECRET=almed-ops-secret-key-change-in-production-2024
JWT_EXPIRES_IN=7d
PORT=3001
NODE_ENV=development
FRONTEND_URL=http://localhost:3000
LOG_LEVEL=debug
"@

$envPath = Join-Path $PSScriptRoot "backend\.env"
$envContent | Out-File -FilePath $envPath -Encoding utf8 -NoNewline

Write-Host "✓ .env file updated with your password!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Start backend: cd backend && npm run start:dev" -ForegroundColor Cyan
Write-Host "  2. Test API: curl http://127.0.0.1:3001/api/projects" -ForegroundColor Cyan
Write-Host "  3. Run Flutter: cd flutter_app && flutter run -d windows" -ForegroundColor Cyan
Write-Host ""

# Clear password from memory
$password = $null
$env:PGPASSWORD = $null

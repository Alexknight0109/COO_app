# ALMED OPS Backend Server - PowerShell Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ALMED OPS Backend Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Node.js first:" -ForegroundColor Yellow
    Write-Host "  1. Download from: https://nodejs.org/" -ForegroundColor Yellow
    Write-Host "  2. Install Node.js LTS version" -ForegroundColor Yellow
    Write-Host "  3. Restart your terminal" -ForegroundColor Yellow
    Write-Host "  4. Run this script again" -ForegroundColor Yellow
    exit 1
}

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "[WARNING] .env file not found!" -ForegroundColor Yellow
    Write-Host ""
    if (Test-Path ".env.example") {
        Write-Host "Copying .env.example to .env"
        Copy-Item ".env.example" ".env"
        Write-Host ""
        Write-Host "[IMPORTANT] Please edit .env with your database credentials!" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to continue"
    } else {
        Write-Host "[ERROR] .env.example not found!" -ForegroundColor Red
        exit 1
    }
}

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "[INFO] Installing dependencies..." -ForegroundColor Yellow
    Write-Host ""
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

Write-Host "[INFO] Starting backend server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Backend will run on: http://localhost:3001" -ForegroundColor Cyan
Write-Host "API endpoints: http://localhost:3001/api" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the server
npm run start:dev

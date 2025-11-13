# ALMED OPS Control System - Installation Script for Windows PowerShell
# Run this script after installing Node.js

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ALMED OPS Control System - Installation" -ForegroundColor Cyan
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

# Check if npm is installed
try {
    $npmVersion = npm --version
    Write-Host "✓ npm found: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ npm is not installed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Installing dependencies..." -ForegroundColor Cyan
Write-Host ""

# Install root dependencies
Write-Host "[1/3] Installing root dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to install root dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Root dependencies installed" -ForegroundColor Green
Write-Host ""

# Install backend dependencies
Write-Host "[2/3] Installing backend dependencies..." -ForegroundColor Yellow
Set-Location backend
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to install backend dependencies" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "✓ Backend dependencies installed" -ForegroundColor Green
Set-Location ..
Write-Host ""

# Install frontend dependencies
Write-Host "[3/3] Installing frontend dependencies..." -ForegroundColor Yellow
Set-Location frontend
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to install frontend dependencies" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "✓ Frontend dependencies installed" -ForegroundColor Green
Set-Location ..
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Set up PostgreSQL database" -ForegroundColor Yellow
Write-Host "  2. Copy backend/.env.example to backend/.env and configure" -ForegroundColor Yellow
Write-Host "  3. Run: npm run dev (from root directory)" -ForegroundColor Yellow
Write-Host "     OR separately:" -ForegroundColor Yellow
Write-Host "     - Terminal 1: cd backend && npm run start:dev" -ForegroundColor Yellow
Write-Host "     - Terminal 2: cd frontend && npm run dev" -ForegroundColor Yellow
Write-Host ""

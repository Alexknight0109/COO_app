#!/bin/bash
# ALMED OPS Control System - Installation Script for Linux/Mac
# Run this script after installing Node.js

echo "========================================"
echo "ALMED OPS Control System - Installation"
echo "========================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "✗ Node.js is not installed!"
    echo ""
    echo "Please install Node.js first:"
    echo "  1. Download from: https://nodejs.org/"
    echo "  2. Install Node.js LTS version"
    echo "  3. Restart your terminal"
    echo "  4. Run this script again"
    exit 1
fi

NODE_VERSION=$(node --version)
echo "✓ Node.js found: $NODE_VERSION"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "✗ npm is not installed!"
    exit 1
fi

NPM_VERSION=$(npm --version)
echo "✓ npm found: $NPM_VERSION"

echo ""
echo "Installing dependencies..."
echo ""

# Install root dependencies
echo "[1/3] Installing root dependencies..."
npm install
if [ $? -ne 0 ]; then
    echo "✗ Failed to install root dependencies"
    exit 1
fi
echo "✓ Root dependencies installed"
echo ""

# Install backend dependencies
echo "[2/3] Installing backend dependencies..."
cd backend
npm install
if [ $? -ne 0 ]; then
    echo "✗ Failed to install backend dependencies"
    cd ..
    exit 1
fi
cd ..
echo "✓ Backend dependencies installed"
echo ""

# Install frontend dependencies
echo "[3/3] Installing frontend dependencies..."
cd frontend
npm install
if [ $? -ne 0 ]; then
    echo "✗ Failed to install frontend dependencies"
    cd ..
    exit 1
fi
cd ..
echo "✓ Frontend dependencies installed"
echo ""

echo "========================================"
echo "Installation Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Set up PostgreSQL database"
echo "  2. Copy backend/.env.example to backend/.env and configure"
echo "  3. Run: npm run dev (from root directory)"
echo "     OR separately:"
echo "     - Terminal 1: cd backend && npm run start:dev"
echo "     - Terminal 2: cd frontend && npm run dev"
echo ""

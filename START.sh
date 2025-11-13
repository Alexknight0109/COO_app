#!/bin/bash
# ALMED OPS Control System - Quick Start Script for Linux/Mac

echo "========================================"
echo "ALMED OPS Control System"
echo "========================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "[ERROR] Node.js is not installed!"
    echo ""
    echo "Please install Node.js from: https://nodejs.org/"
    echo "Then restart this script."
    exit 1
fi

echo "[INFO] Node.js found:"
node --version
echo ""

# Check if .env exists
if [ ! -f "backend/.env" ]; then
    echo "[WARNING] backend/.env not found!"
    echo ""
    echo "Copying backend/.env.example to backend/.env"
    cp backend/.env.example backend/.env
    echo ""
    echo "[IMPORTANT] Please edit backend/.env with your database credentials!"
    echo ""
    read -p "Press Enter to continue..."
fi

echo "Starting application..."
echo ""
echo "Backend will run on: http://localhost:3001"
echo "Frontend will run on: http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop both servers"
echo ""

# Start both servers concurrently
npm run dev

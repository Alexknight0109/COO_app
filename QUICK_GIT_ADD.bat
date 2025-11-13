@echo off
echo ========================================
echo Quick Git Add - Important Files Only
echo ========================================
echo.

echo Adding backend source code...
git add backend/src/
git add backend/*.json
git add backend/nest-cli.json
git add backend/tsconfig.json

echo Adding frontend source code...
git add frontend/app/
git add frontend/components/
git add frontend/lib/
git add frontend/*.config.js
git add frontend/*.json
git add frontend/tsconfig.json

echo Adding configuration files...
git add package.json
git add package-lock.json
git add .gitignore

echo Adding Windows scripts...
git add *.bat
git add *.ps1

echo Adding important documentation...
git add README.md
git add ARCHITECTURE.md
git add WINDOWS_TESTING_GUIDE.md
git add BACKEND_ENDPOINTS_FIXED.md
git add UI_IMPROVEMENTS_COMPLETE.md
git add TROUBLESHOOTING.md

echo.
echo ========================================
echo Files Added Successfully!
echo ========================================
echo.
echo Next step: Review with "git status"
echo Then commit with: git commit -m "Your message"
echo.
pause


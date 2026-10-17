@echo off
TITLE Expense Tracker Launcher
echo ========================================================
echo       Launching Full-Stack Expense Tracker App
echo ========================================================
echo.
echo Starting Express + SQLite Backend API on port 5000...
start "Expense Tracker - Backend API" cmd /k "cd server && npm start"

echo.
echo Waiting 2 seconds for backend initialization...
timeout /t 2 /nobreak > nul

echo.
echo Starting Vite + React Frontend Dashboard on port 5173...
start "Expense Tracker - Frontend Client" cmd /k "cd client && npm run dev"

echo.
echo ========================================================
echo Backend running at:  http://localhost:5000
echo Frontend running at: http://localhost:5173
echo ========================================================
echo.

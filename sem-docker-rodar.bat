@echo off
cd /d "%~dp0"
start "Valit - Backend (porta 3309)" cmd /k "cd /d "%~dp0backEnd" && npm run dev"
start "Valit - Frontend (porta 3000)" cmd /k "cd /d "%~dp0front_end" && npm run dev"
timeout /t 10 /nobreak >nul
start http://localhost:3000

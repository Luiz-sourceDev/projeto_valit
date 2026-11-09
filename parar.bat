@echo off
chcp 65001 >nul
title Valit - Parar
cd /d "%~dp0"
echo Desligando o Valit (os dados do banco sao mantidos)...
docker compose down
echo.
echo Pronto. Para ligar de novo: rodar.bat
pause

@echo off
chcp 65001 >nul
title Valit - Configuracao
cd /d "%~dp0"

echo ==========================================
echo   Projeto Valit - configuracao automatica
echo ==========================================
echo.

where node >nul 2>nul
if errorlevel 1 (
  echo [ERRO] Node.js nao encontrado. Instale a versao LTS em https://nodejs.org e rode este arquivo de novo.
  pause
  exit /b 1
)
for /f "delims=" %%v in ('node -v') do echo Node.js encontrado: %%v

echo.
echo [1/4] Instalando dependencias do backend...
cd backEnd
if not exist .env copy .env.example .env >nul
call npm install --no-audit --no-fund || goto erro

echo.
echo [2/4] Criando o banco de dados db_valit...
call npm run db:setup
if errorlevel 1 (
  echo.
  echo [ERRO] Nao consegui acessar o MySQL.
  echo  - Verifique se o MySQL esta ligado ^(Servicos do Windows ou XAMPP^).
  echo  - Confira DB_USER e DB_PASSWORD em backEnd\.env e rode este arquivo de novo.
  pause
  exit /b 1
)
cd ..

echo.
echo [3/4] Instalando dependencias do frontend ^(pode demorar alguns minutos^)...
cd front_end
if not exist .env.local copy .env.local.example .env.local >nul
call npm install --no-audit --no-fund || goto erro
cd ..

echo.
echo [4/4] Iniciando o sistema...
start "Valit - Backend (porta 3309)" cmd /k "cd /d "%~dp0backEnd" && npm run dev"
start "Valit - Frontend (porta 3000)" cmd /k "cd /d "%~dp0front_end" && npm run dev"

echo Aguardando o frontend subir...
timeout /t 12 /nobreak >nul
start http://localhost:3000

echo.
echo Pronto! Login de teste: teste@email.com / 123456
echo Para parar o sistema, feche as duas janelas "Valit - Backend" e "Valit - Frontend".
echo Nas proximas vezes, use o arquivo rodar.bat ^(nao precisa instalar de novo^).
pause
exit /b 0

:erro
echo.
echo [ERRO] A instalacao falhou. Veja a mensagem acima.
pause
exit /b 1

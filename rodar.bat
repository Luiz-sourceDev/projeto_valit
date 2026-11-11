@echo off
chcp 65001 >nul
title Valit - Rodar
cd /d "%~dp0"

echo ==========================================
echo   Projeto Valit - iniciando (Docker)
echo ==========================================
echo.

if not exist ".env" (
  echo Primeira vez? Rodando a configuracao completa...
  call "%~dp0configurar.bat"
  exit /b
)

docker info >nul 2>nul
if not errorlevel 1 goto subir
echo Abrindo o Docker Desktop...
if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
echo Aguardando o Docker iniciar...
set /a tentativas=0
:espera
timeout /t 5 /nobreak >nul
set /a tentativas+=1
docker info >nul 2>nul
if not errorlevel 1 goto subir
if %tentativas% lss 36 goto espera
echo [ERRO] O Docker nao iniciou. Abra o Docker Desktop e rode de novo.
pause
exit /b 1

:subir
rem Porta do site escolhida pelo configurar.bat (padrao 3000)
set "WEB_PORT=3000"
for /f "usebackq tokens=1,2 delims==" %%a in (".env") do if /i "%%a"=="WEB_PORT" set "WEB_PORT=%%b"
set "SITE=http://localhost:%WEB_PORT%"

docker compose up -d
if errorlevel 1 (
  echo.
  echo [ERRO] Nao consegui subir os containers. Rode o configurar.bat para ver o diagnostico.
  pause
  exit /b 1
)

echo.
echo Aguardando o site responder...
powershell -NoProfile -Command "$f=(Get-Date).AddSeconds(90); while((Get-Date) -lt $f){ try{ if((Invoke-WebRequest %SITE% -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200){exit 0} }catch{}; Start-Sleep 2 }; exit 1"
if errorlevel 1 (
  echo [AVISO] O site ainda nao respondeu. Aguarde mais um pouco e acesse %SITE%
) else (
  start %SITE%
)

echo.
echo Sistema no ar: %SITE%
echo   Administrador: admin@valit.com / admin123
echo   Funcionario:   teste@email.com / 123456
echo Para desligar: parar.bat
echo.
pause

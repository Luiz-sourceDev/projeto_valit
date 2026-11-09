# Configura e sobe o Projeto Valit com Docker (MySQL + backend + frontend)
# Uso: dois cliques em configurar.bat
#      configurar.bat -Resetar   -> apaga o banco e recria do zero
param([switch]$Resetar)

$ErrorActionPreference = "Continue"
Set-Location -LiteralPath $PSScriptRoot
$Log = Join-Path $PSScriptRoot "diagnostico.txt"
"Diagnostico Valit - $(Get-Date)" | Out-File $Log -Encoding utf8

function Passo($t) { Write-Host ""; Write-Host "==> $t" -ForegroundColor Cyan; "`n==> $t" | Out-File $Log -Append -Encoding utf8 }
function Ok($t)    { Write-Host "    OK  $t" -ForegroundColor Green; "OK  $t" | Out-File $Log -Append -Encoding utf8 }
function Aviso($t) { Write-Host "    !!  $t" -ForegroundColor Yellow; "AVISO  $t" | Out-File $Log -Append -Encoding utf8 }
function Registrar($t) { $t | Out-File $Log -Append -Encoding utf8 }

function Falhar($t) {
  Write-Host ""
  Write-Host "    ERRO: $t" -ForegroundColor Red
  "ERRO  $t" | Out-File $Log -Append -Encoding utf8
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { exit 1 }
  Registrar "`n--- docker compose ps ---"
  docker compose ps -a 2>&1 | Out-File $Log -Append -Encoding utf8
  foreach ($s in "db", "backend", "frontend") {
    Registrar "`n--- logs: $s ---"
    docker compose logs --tail 60 $s 2>&1 | Out-File $Log -Append -Encoding utf8
  }
  Write-Host ""
  Write-Host "    Detalhes salvos em: $Log" -ForegroundColor Yellow
  Write-Host "    Envie esse arquivo para analise." -ForegroundColor Yellow
  exit 1
}

function Esperar-Url($url, $segundos) {
  $fim = (Get-Date).AddSeconds($segundos)
  while ((Get-Date) -lt $fim) {
    try {
      $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
      if ($r.StatusCode -eq 200) { return $true }
    } catch { }
    Start-Sleep -Seconds 3
  }
  return $false
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Projeto Valit - configuracao com Docker"  -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Docker instalado?
Passo "Verificando o Docker"
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Falhar "Docker nao encontrado. Instale o Docker Desktop: https://www.docker.com/products/docker-desktop/"
}
Registrar (docker --version 2>&1)
docker compose version *> $null
if ($LASTEXITCODE -ne 0) { Falhar "O comando 'docker compose' nao existe. Atualize o Docker Desktop." }
Registrar (docker compose version 2>&1)
Ok "Docker instalado"

# 2. Docker rodando? Se nao, abre o Docker Desktop e espera
docker info *> $null
if ($LASTEXITCODE -ne 0) {
  Aviso "Docker Desktop nao esta rodando. Abrindo..."
  $exe = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
  if (Test-Path $exe) { Start-Process $exe } else { Aviso "Abra o Docker Desktop manualmente." }
  $fim = (Get-Date).AddSeconds(180)
  do {
    Start-Sleep -Seconds 5
    Write-Host "    ...aguardando o Docker iniciar"
    docker info *> $null
  } while ($LASTEXITCODE -ne 0 -and (Get-Date) -lt $fim)
  if ($LASTEXITCODE -ne 0) {
    Falhar "O Docker nao iniciou. Abra o Docker Desktop, espere aparecer 'Engine running' e rode este script de novo. Se ele reclamar de WSL, rode 'wsl --update' no PowerShell como administrador."
  }
}
Ok "Docker rodando"

# 3. Derruba containers antigos do projeto
Passo "Removendo containers antigos do projeto"
if ($Resetar) {
  docker compose down -v --remove-orphans 2>&1 | Out-File $Log -Append -Encoding utf8
  Ok "Containers e banco apagados (modo -Resetar)"
} else {
  docker compose down --remove-orphans 2>&1 | Out-File $Log -Append -Encoding utf8
  Ok "Containers antigos removidos (dados do banco mantidos)"
}

# 4. Portas livres?
function Dono-Porta($p) {
  try {
    $c = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction Stop | Select-Object -First 1
    $proc = (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).ProcessName
    return "'$proc' (PID $($c.OwningProcess))"
  } catch { return $null }
}

Passo "Verificando portas"
# 3000 (site) e 3309 (API) precisam estar livres
$ocupadas = @()
foreach ($p in 3000, 3309) {
  $dono = Dono-Porta $p
  if ($dono) { $ocupadas += "porta $p em uso por $dono" }
}
if ($ocupadas.Count -gt 0) {
  foreach ($o in $ocupadas) { Aviso $o }
  Falhar "Feche os programas acima (ex.: outro 'npm run dev' ou outro container) e rode o script de novo."
}

# MySQL do Docker: usa a primeira porta livre (pode haver um MySQL instalado no PC)
$DbPort = $null
foreach ($p in 3307, 3308, 3310, 3311, 3312, 33060, 33061) {
  $dono = Dono-Porta $p
  if ($dono) { Aviso "porta $p ja usada por $dono - tentando outra" } else { $DbPort = $p; break }
}
if (-not $DbPort) { Falhar "Nenhuma porta livre para o MySQL do Docker." }
$env:DB_HOST_PORT = "$DbPort"
Ok "Portas livres (site 3000, API 3309, MySQL do Docker $DbPort)"

# 5. Build e subida
Passo "Construindo e subindo os containers (a primeira vez demora alguns minutos)"
docker compose up -d --build 2>&1 | ForEach-Object {
  $linha = "$_"
  Write-Host "    $linha"
  $linha | Out-File $Log -Append -Encoding utf8
}
if ($LASTEXITCODE -ne 0) { Falhar "Falha no 'docker compose up'. Verifique a conexao com a internet (Docker Hub e npm)." }
Ok "Containers criados"

# 6. Banco pronto + garante tabela e usuario de teste (funciona mesmo com volume antigo)
Passo "Preparando o banco de dados"
$fim = (Get-Date).AddSeconds(120)
do {
  Start-Sleep -Seconds 3
  docker compose exec -T db mysqladmin ping -h 127.0.0.1 -uroot -psenai@123 *> $null
} while ($LASTEXITCODE -ne 0 -and (Get-Date) -lt $fim)
if ($LASTEXITCODE -ne 0) { Falhar "O MySQL nao respondeu. Tente: configurar.bat -Resetar" }
docker compose exec -T db sh -c "mysql -uroot -psenai@123 < /docker-entrypoint-initdb.d/01-database.sql" 2>&1 | Out-File $Log -Append -Encoding utf8
if ($LASTEXITCODE -ne 0) { Falhar "Nao consegui criar o banco db_valit. Tente: configurar.bat -Resetar" }
Ok "Banco db_valit pronto (usuario teste@email.com / 123456)"

# 7. API e site respondendo?
Passo "Testando a API"
if (-not (Esperar-Url "http://localhost:3309/api/health" 90)) { Falhar "A API nao respondeu em http://localhost:3309" }
try {
  $body = '{"usuario":"teste@email.com","senha":"123456"}'
  $r = Invoke-RestMethod -Uri "http://localhost:3309/api/auth/login" -Method Post -ContentType "application/json" -Body $body
  if (-not $r.token) { throw "sem token" }
  Ok "API e login funcionando"
} catch {
  Falhar "A API subiu, mas o login de teste falhou: $($_.Exception.Message)"
}

Passo "Testando o site"
if (-not (Esperar-Url "http://localhost:3000" 120)) { Falhar "O frontend nao respondeu em http://localhost:3000" }
Ok "Site no ar"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  TUDO PRONTO!"                              -ForegroundColor Green
Write-Host "  Site:   http://localhost:3000"             -ForegroundColor Green
Write-Host "  Login:  teste@email.com / 123456"          -ForegroundColor Green
Write-Host "  MySQL (Workbench): 127.0.0.1 porta $DbPort, root / senai@123" -ForegroundColor Green
Write-Host "  Parar:  docker compose down"               -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Start-Process "http://localhost:3000"
exit 0

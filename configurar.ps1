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
# Remove containers do Valit criados a partir de outra pasta (evita "name already in use")
foreach ($n in "valit-db", "valit-backend", "valit-frontend") {
  docker rm -f $n 2>&1 | Out-File $Log -Append -Encoding utf8
}

# 4. Portas livres?
function Dono-Porta($p) {
  try {
    $c = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction Stop | Select-Object -First 1
    $proc = (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).ProcessName
    return "'$proc' (PID $($c.OwningProcess))"
  } catch { return $null }
}

$script:PortasEscolhidas = @()

# Usa a primeira porta livre da lista (pode haver outro container, WSL ou MySQL usando a padrao)
function Escolher-Porta($nome, $candidatas) {
  foreach ($p in $candidatas) {
    if ($script:PortasEscolhidas -contains $p) { continue }
    $dono = Dono-Porta $p
    if ($dono) {
      $container = (docker ps --filter "publish=$p" --format "{{.Names}}" 2>$null | Select-Object -First 1)
      if ($container) { $dono = "$dono - container '$container'" }
      Aviso "$nome`: porta $p ja usada por $dono - tentando outra"
    } else {
      $script:PortasEscolhidas += $p
      return $p
    }
  }
  Falhar "Nenhuma porta livre para $nome. Feche outros containers ou programas e rode de novo."
}

Passo "Escolhendo portas livres"
$WebPort = Escolher-Porta "Site"  @(3000, 3001, 3002, 3003, 3005, 3080, 8080, 8081)
$ApiPort = Escolher-Porta "API"   @(3309, 3319, 3329, 3339, 4000, 4001, 8090)
$DbPort  = Escolher-Porta "MySQL" @(3307, 3308, 3310, 3311, 3312, 33060, 33061)
$env:WEB_PORT = "$WebPort"; $env:API_PORT = "$ApiPort"; $env:DB_HOST_PORT = "$DbPort"
# Salva as portas: o docker compose le este .env (usado tambem pelo rodar.bat)
@("WEB_PORT=$WebPort", "API_PORT=$ApiPort", "DB_HOST_PORT=$DbPort") |
  Out-File -FilePath (Join-Path $PSScriptRoot ".env") -Encoding ascii
$SiteUrl = "http://localhost:$WebPort"
$ApiUrl  = "http://localhost:$ApiPort/api"
Ok "Site $WebPort, API $ApiPort, MySQL do Docker $DbPort"

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
Ok "Banco db_valit pronto"

# 7. API e site respondendo?
Passo "Testando a API"
if (-not (Esperar-Url "$ApiUrl/health" 90)) { Falhar "A API nao respondeu em $ApiUrl" }
try {
  $body = '{"usuario":"teste@email.com","senha":"123456"}'
  $r = Invoke-RestMethod -Uri "$ApiUrl/auth/login" -Method Post -ContentType "application/json" -Body $body
  if (-not $r.token) { throw "sem token" }
  Ok "API e login funcionando"
} catch {
  Falhar "A API subiu, mas o login de teste falhou: $($_.Exception.Message)"
}

Passo "Testando o site"
if (-not (Esperar-Url $SiteUrl 120)) { Falhar "O frontend nao respondeu em $SiteUrl" }
Ok "Site no ar"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  TUDO PRONTO!"                              -ForegroundColor Green
Write-Host "  Site:   $SiteUrl"                         -ForegroundColor Green
Write-Host "  Administrador: admin@valit.com / admin123"  -ForegroundColor Green
Write-Host "  Funcionario:   teste@email.com / 123456"   -ForegroundColor Green
Write-Host "  MySQL (Workbench): 127.0.0.1 porta $DbPort, root / senai@123" -ForegroundColor Green
Write-Host "  Proximas vezes: rodar.bat  |  Desligar: parar.bat" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Start-Process $SiteUrl
exit 0

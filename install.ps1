# Paseo_Aranjuez - Instalación Automatizada (PowerShell)

# Verificar Docker primero
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Instalación Paseo_Aranjuez" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/6] Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "Docker instalado: $dockerVersion" -ForegroundColor Green

    Write-Host "`nEstado actual de los contenedores:" -ForegroundColor Yellow
    docker compose -f infra/docker-compose.yml ps
} catch {
    Write-Host "ERROR: Docker no está instalado" -ForegroundColor Red
    Write-Host "Por favor instala Docker Desktop desde https://www.docker.com/products/docker-desktop"
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host ""

# Instalar Flutter si no está instalado
Write-Host "[2/6] Verificando Flutter..." -ForegroundColor Yellow
$flutterInstalled = flutter --version 2>&1 | Out-String
if ($flutterInstalled -match "Flutter version") {
    Write-Host "Flutter instalado: $flutterInstalled" -ForegroundColor Green
} else {
    Write-Host "Flutter no está instalado" -ForegroundColor Red
    Write-Host "Procediendo a descargar Flutter SDK..." -ForegroundColor Yellow

    $flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.27.1-stable.zip"
    $flutterZip = "flutter_windows.zip"

    Write-Host "Descargando Flutter (aprox. 1GB)..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -TimeoutSec 600 -UseBasicParsing
        Write-Host "Descarga completada" -ForegroundColor Green

        Write-Host "Descomprimiendo..." -ForegroundColor Yellow
        $extractPath = "C:\src"
        if (!(Test-Path $extractPath)) {
            New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        }
        Expand-Archive -Path $flutterZip -DestinationPath $extractPath -Force
        Write-Host "Descompresión completada" -ForegroundColor Green

        Remove-Item $flutterZip -Force

        Write-Host "`nAGREGAR AL PATH:" -ForegroundColor Yellow
        Write-Host "Agrega '$extractPath\flutter\bin' a tu PATH de entorno"
        Write-Host "Ejecuta: setx PATH '$env:PATH;$extractPath\flutter\bin'"
        Write-Host "Reinicia la terminal para aplicar cambios"

        $addPath = Read-Host "`n¿Deseas agregarlo al PATH ahora? (y/n)"
        if ($addPath -eq "y") {
            [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$extractPath\flutter\bin", "User")
            Write-Host "PATH actualizado. Reinicia la terminal." -ForegroundColor Green
        }
    } catch {
        Write-Host "ERROR: No se pudo descargar Flutter" -ForegroundColor Red
        Write-Host "Por favor descárgalo manualmente desde https://docs.flutter.dev/get-started/install/windows"
        Read-Host "Presiona Enter para salir"
        exit 1
    }
}

Write-Host ""

# Instalar FVM
Write-Host "[3/6] Verificando FVM..." -ForegroundColor Yellow
$npm = "npm -g fvm" 2>&1
$fvmInstalled = npm list -g fvm 2>&1
if ($fvmInstalled -match "fvm") {
    Write-Host "FVM instalado" -ForegroundColor Green
} else {
    Write-Host "Instalando FVM..." -ForegroundColor Yellow
    npm install -g fvm
    if ($LASTEXITCODE -eq 0) {
        Write-Host "FVM instalado correctamente" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Fallo al instalar FVM" -ForegroundColor Red
        Read-Host "Presiona Enter para salir"
        exit 1
    }
}

Write-Host ""

# Instalar dependencias
Write-Host "[4/6] Instalando dependencias de Flutter..." -ForegroundColor Yellow
try {
    fvm flutter pub get
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Dependencias instaladas correctamente" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Algunas dependencias fallaron" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Fallo al instalar dependencias" -ForegroundColor Red
}

Write-Host ""

# Verificar .env
Write-Host "[5/6] Verificando .env..." -ForegroundColor Yellow
if (Test-Path "infra\.env") {
    Write-Host ".env existe" -ForegroundColor Green
    Write-Host "Recuerda editar con credenciales reales antes de producción" -ForegroundColor Yellow
} else {
    Write-Host "ERROR: El archivo infra\.env no existe" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host ""

# Levantar stack Docker
Write-Host "[6/6] Levantando stack Docker..." -ForegroundColor Yellow
try {
    docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Stack Docker levantada" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Fallo al levantar Docker Compose" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Fallo al levantar Docker Compose" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Instalación completada!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. Editar infra\.env con credenciales reales"
Write-Host "2. Ejecutar `fvm flutter pub get` en cada paquete"
Write-Host "3. Verificar migraciones: docker compose -f infra/docker-compose.yml run --rm migrate info"
Write-Host "4. Ejecutar tests: fvm dart test && fvm flutter test"
Write-Host ""
Write-Host "Para más información, consulta:" -ForegroundColor Yellow
Write-Host "  - INSTALLATION.md"
Write-Host "  - VERIFICATION.md"
Write-Host "  - AGENTS.md"
Write-Host ""

Read-Host "Presiona Enter para salir"

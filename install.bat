@echo off
REM Script de instalación automática de Paseo_Aranjuez
REM Ejecutar como Administrador si es necesario

echo ====================================
echo Instalacion Paseo_Aranjuez
echo ====================================
echo.

REM 1. Verificar Docker
echo [1/6] Verificando Docker...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker no esta instalado. Por favor instala Docker Desktop primero.
    pause
    exit /b 1
)
echo Docker esta instalado.
docker compose -f infra/docker-compose.yml ps
echo.

REM 2. Instalar Flutter si no esta instalado
echo [2/6] Verificando Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Flutter no esta instalado.
    echo Procediendo a instalar Flutter SDK...
    echo Descargando Flutter 3.27.1-stable (aprox. 1GB)...
    powershell -Command "Invoke-WebRequest -Uri 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.27.1-stable.zip' -OutFile 'flutter_windows.zip' -TimeoutSec 600"
    if exist flutter_windows.zip (
        echo Descomprimiendo Flutter...
        powershell -Command "Expand-Archive -Path 'flutter_windows.zip' -DestinationPath 'C:\src' -Force"
        echo.
        echo Asegurate de agregar 'C:\src\flutter\bin' a tu PATH
        set /p ADD_PATH="¿Deseas agregarlo al PATH ahora? (y/n): "
        if /i "%ADD_PATH%"=="y" (
            setx PATH "%PATH%;C:\src\flutter\bin"
            echo PATH actualizado. Reinicia la terminal.
        )
    ) else (
        echo ERROR: No se pudo descargar Flutter. Por favor descargalo manualmente desde https://docs.flutter.dev/get-started/install/windows
        pause
        exit /b 1
    )
) else (
    echo Flutter esta instalado: %flutter_version%
)
echo.

REM 3. Instalar FVM
echo [3/6] Verificando FVM...
npm -g fvm >nul 2>&1
if %errorlevel% neq 0 (
    echo FVM no esta instalado. Instalando FVM...
    npm install -g fvm
) else (
    echo FVM esta instalado.
)
echo.

REM 4. Instalar dependencias del proyecto
echo [4/6] Instalando dependencias...
fvm flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Fallo al instalar dependencias de Flutter
    pause
    exit /b 1
)
echo.

REM 5. Verificar .env
echo [5/6] Verificando configuracion .env...
if not exist infra\.env (
    echo ERROR: El archivo infra\.env no existe
    pause
    exit /b 1
)
echo .env existe.
echo.

REM 6. Levantar stack Docker
echo [6/6] Levantando stack Docker...
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d
if %errorlevel% neq 0 (
    echo ERROR: Fallo al levantar Docker Compose
    pause
    exit /b 1
)
echo Stack Docker levantada.
echo.

echo ====================================
echo Instalacion completada!
echo ====================================
echo.
echo Pasos siguientes:
echo 1. Editar infra\.env con credenciales reales
echo 2. Ejecutar 'fvm flutter pub get' en cada paquete
echo 3. Verificar migraciones: docker compose -f infra/docker-compose.yml run --rm migrate info
echo 4. Ejecutar tests: fvm dart test && fvm flutter test
echo.
pause

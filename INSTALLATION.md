# Paseo_Aranjuez - Instalación Completa

## ✅ Lo que ya está listo
- Estructura del repositorio monorepo
- Docker Compose configurado (DB corriendo)
- Archivos de configuración (`.fvmrc`, `pubspec.yaml`, etc.)
- Estructura básica del proyecto (`apps/api/lib/` con arquitectura hexagonal)
- `.env` configurado con valores de ejemplo
- Migraciones y scripts de inicialización de BD

## ❌ Lo que falta (requiere instalación manual)

### 1. Flutter SDK (requiere ~1GB, conexión a internet estable)

#### Opción A - Manual (recomendado para mejores resultados)
```powershell
# 1. Descargar Flutter SDK desde la página oficial
# https://docs.flutter.dev/get-started/install/windows
# Descargar: flutter_windows_3.27.1-stable.zip

# 2. Extraer en: C:\src\flutter
# 3. Agregar a PATH: C:\src\flutter\bin

# 4. Instalar dependencias del SDK
flutter doctor
```

#### Opción B - Usar winget (más rápido si está disponible)
```powershell
winget install Google.Flutter --accept-package-agreements --accept-source-agreements
```

### 2. FVM (Flutter Version Manager)

```powershell
# Usar npm globalmente
npm install -g fvm

# Instalar Flutter 3.47.6 (versión del .fvmrc)
fvm install 3.47.6

# Usar este versión para el proyecto
fvm use 3.47.6
```

**Nota:** Si Flutter 3.47.6 no existe, usar la versión más reciente estable:
```powershell
fvm install stable
fvm use stable
```

### 3. Actualizar .fvmrc con la versión correcta

Si usaste Flutter 3.47.6:
```json
{
  "flutter": "3.47.6"
}
```

Si usaste una versión diferente, actualizar el archivo:
```json
{
  "flutter": "X.Y.Z"
}
```

### 4. Instalar dependencias del proyecto

```powershell
# Instalar todas las dependencias
fvm flutter pub get

# Ir a cada paquete
cd apps/api
fvm flutter pub get
cd ../..

cd apps/mobile
fvm flutter pub get
cd ../..

cd packages/paseo_shared
fvm flutter pub get
cd ../..
```

### 5. Verificar Docker Compose

```bash
# Asegurarse de que la BD está corriendo
docker compose -f infra/docker-compose.yml ps

# Levantar stack completo en modo desarrollo
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d
```

### 6. Ejecutar migraciones

```bash
# Verificar estado
docker compose -f infra/docker-compose.yml run --rm migrate info

# Validar migraciones
docker compose -f infra/docker-compose.yml run --rm migrate validate
```

## 🚀 Proceso de prueba (después de completar instalación)

```bash
# 1. Formatear el código
fvm dart format --set-exit-if-changed .

# 2. Analizar código
fvm dart analyze

# 3. Ejecutar tests
fvm dart test
fvm flutter test
```

## 🐛 Solución de problemas comunes

### "flutter no está reconocido"
- Asegúrate de que Flutter SDK esté instalado
- Verifica que el directorio bin de Flutter esté en tu PATH
- Reinicia la terminal después de instalar

### "fvm no está reconocido"
- Asegúrate de haber instalado FVM globalmente (`npm install -g fvm`)
- Revisa que Node.js esté instalado en tu sistema

### "Las migraciones fallan"
- Verifica que el .env tenga las credenciales correctas
- Ejecuta: `docker compose -f infra/docker-compose.yml logs db` para ver errores

### "El puerto 5432 está en uso"
- Detén el contenedor: `docker compose -f infra/docker-compose.yml down`
- Verifica qué proceso está usando el puerto: `netstat -ano | findstr :5432`
- Matar el proceso si es necesario: `taskkill /PID <PID> /F`

## 📝 Notas importantes

1. **El .env ya está creado** con valores de ejemplo. Edita los passwords y tokens antes de usar en producción.
2. **Flutter 3.47.6** es la versión específica requerida por el proyecto. Si esa versión no existe, usa la más reciente estable (3.27.1).
3. **Docker Compose** debe levantarse en modo desarrollo (`docker-compose.dev.yml`) para ver los logs de OTP y correos en consola.
4. **NUNCA commitees el archivo `.env`** - ya está en .gitignore.

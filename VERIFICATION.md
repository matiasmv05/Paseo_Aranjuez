# Paseo_Aranjuez - Verificación de Instalación

Este script verifica que todos los componentes estén correctamente instalados y configurados.

## Estado Actual

### ✅ Componentes listos

| Componente | Estado | Notas |
|------------|--------|-------|
| Estructura del repositorio | ✅ | Monorepo con apps/api, apps/mobile, packages/paseo_shared |
| Docker Compose | ✅ | Archivos definidos |
| Base de datos | ✅ | PostgreSQL 18-alpine corriendo (healthy) |
| Imágenes Docker | ✅ | postgres:18-alpine, flyway:13.9.0, caddy:2.11.6-alpine |
| Configuración base | ✅ | .fvmrc, pubspec.yaml, analysis_options.yaml, CLAUDE.md |
| Estructura hexagonal API | ✅ | domain, application, adapters/in, adapters/out creados |
| Archivo .env | ✅ | Creado con valores de ejemplo |
| Migraciones | ✅ | V001__baseline_extensions_y_esquema.sql presente |
| Script inicialización BD | ✅ | 01-roles.sh presente |
| Semillas dev | ✅ | R__seed_dev.sql presente |
| Script backup | ✅ | backup.sh presente |
| Documentación | ✅ | AGENTS.md, INFRASTRUCTURE.md, INSTALLATION.md |

### ❌ Componentes pendientes

| Componente | Estado | Problema | Solución |
|------------|--------|----------|----------|
| Flutter SDK | ❌ | No instalado | Sigue INSTALATION.md |
| Dart SDK | ❌ | No instalado | Sigue INSTALATION.md |
| FVM | ❌ | No instalado | Sigue INSTALATION.md |
| Dependencias pub | ❌ | No instaladas | `fvm flutter pub get` |
| Rutas API | ❌ | No implementadas | Pendiente de specs/features |
| Web builds | ❌ | No existen | Pendiente de implementación |
| Migraciones V002-V010 | ❌ | Faltan | Pendiente de specs/features |
| Configuración real .env | ⚠️ | Solo valores ejemplo | Editar antes de producción |

## Instrucciones de instalación

### Paso 1: Instalar Flutter SDK (requiere ~1GB)

```powershell
# Opción A - Manual (recomendado)
# Descargar de: https://docs.flutter.dev/get-started/install/windows
# Flutter 3.27.1-stable.zip

# Opción B - winget
winget install Google.Flutter --accept-package-agreements --accept-source-agreements
```

### Paso 2: Instalar FVM

```powershell
npm install -g fvm
fvm install stable
fvm use stable
```

### Paso 3: Actualizar .fvmrc

```json
{
  "flutter": "3.27.1"
}
```

### Paso 4: Instalar dependencias

```powershell
fvm flutter pub get
cd apps/api && fvm flutter pub get && cd ..
cd apps/mobile && fvm flutter pub get && cd ..
cd packages/paseo_shared && fvm flutter pub get && cd ..
```

### Paso 5: Levantar stack Docker

```bash
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d
```

### Paso 6: Verificar migraciones

```bash
docker compose -f infra/docker-compose.yml run --rm migrate info
```

## Comandos de verificación rápidos

```bash
# Estado de Docker
docker compose -f infra/docker-compose.yml ps

# Si Flutter está instalado:
flutter --version
fvm list

# Si Dart está instalado:
dart --version

# Dependencias:
fvm flutter pub get
```

## Próximos pasos

1. **Instalar Flutter y FVM** (sigue INSTALATION.md)
2. **Editar .env** con credenciales reales
3. **Ejecutar `fvm flutter pub get`** en todos los paquetes
4. **Levantar stack Docker** completo
5. **Crear specs/features** para implementar rutas
6. **Implementar arquitectura hexagonal** en apps/api/lib
7. **Ejecutar tests** para verificar el código

## Soporte

Para más detalles, consulta:
- `INSTALLATION.md` - Instrucciones completas
- `AGENTS.md` - Reglas y convenciones del proyecto
- `INFRASTRUCTURE.md` - Infraestructura técnica
- `docs/agent-audit.md` - Auditoría del repositorio

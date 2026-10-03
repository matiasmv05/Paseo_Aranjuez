# Research: librerÃ­a Argon2id para la API (T004)

Fecha: 03/10/2026 Â· Ejecutado en Windows 11, Dart SDK 3.13.5 (FVM 3.47.6).
Banco de pruebas: `C:\Users\matia\AppData\Local\Temp\opencode\argon2-bench\` (proyecto temporal, fuera del repo).

## 1. Candidatos

| Criterio | `cryptography` 2.9.0 | `argon2_ffi` 1.0.0+2 | `argon2` 1.0.1 |
|---|---|---|---|
| Publicado | 21/11/2025 | 11/08/2025 | 18/06/2021 |
| Constraint SDK | >=3.3.0 <4.0.0 âœ… | (Flutter plugin) | >=2.12.0 <3.0.0 âŒ incompatible con Dart 3.13 |
| Publisher | dint.dev (verificado) | codeux.design (verificado, AuthPass) | â€” |
| Descargas/semana | ~855k | ~21 | â€” |
| ImplementaciÃ³n | Dart puro | FFI sobre libargon2 C (plugin Flutter) | â€” |
| Dependencia del SDK Flutter | No | **SÃ­** (plugin Flutter, requiere toolchain Flutter para el binario nativo) | â€” |
| Vector PHC de referencia | **MATCH âœ…** | No probado: en Windows puro falla al cargar `argon2_ffi_plugin.dll` (no se distribuye precompilada) | â€” |
| PHC construible | SÃ­ (el paquete devuelve el hash crudo; la cadena `$argon2id$v=19$...` se arma manualmente, ~5 lÃ­neas) | El C nativo sÃ­ devuelve PHC en su API `encoded`, pero el binding Dart expone solo el hash crudo; tambiÃ©n habrÃ­a que armar el PHC | â€” |
| Aislamiento (Isolate) | SÃ­, verificado (mismo resultado en Isolate y en hilo principal) | SÃ­ en teorÃ­a | â€” |
| Imagen final `scratch` (`api.Dockerfile`) | **Cero impacto** (Dart AOT estÃ¡tico) | **Impacto alto**: habrÃ­a que compilar el `.so` (CMake + fuentes C empaquetadas) y coexistir con `scratch` sin libc del ejecutable FFI â†’ probablemente exigirÃ­a cambiar la imagen final a una base con libc | â€” |

## 2. VerificaciÃ³n contra vector de referencia (PHC)

Referencia generada con la implementaciÃ³n C oficial de Argon2 (`P-H-C/phc-winner-argon2`, paquete `argon2` de Alpine, en contenedor Docker):

```
echo -n password | argon2 somesalt -id -t 2 -m 16 -p 4 -l 32 -e
=> $argon2id$v=19$m=65536,t=2,p=4$c29tZXNhbHQ$GpZ3sK/oH9p7VIiV56G/64Zo/8GaUw434IimaPqxwCo
```

`cryptography` (Dart puro) con los mismos parÃ¡metros produce **la misma cadena PHC byte a byte**:

```
referencia : $argon2id$v=19$m=65536,t=2,p=4$c29tZXNhbHQ$GpZ3sK/oH9p7VIiV56G/64Zo/8GaUw434IimaPqxwCo
cryptography: $argon2id$v=19$m=65536,t=2,p=4$c29tZXNhbHQ$GpZ3sK/oH9p7VIiV56G/64Zo/8GaUw434IimaPqxwCo
MATCH (PHC completo): true
```

â†’ Interoperabilidad PHC confirmada: los hashes generados serÃ­an verificables por cualquier otra implementaciÃ³n estÃ¡ndar (Go, Python argon2-cffi, Node argon2â€¦), y viceversa.

## 3. Benchmark

MÃ¡quina de dev (Windows x64), parÃ¡metros OWASP mÃ­nimos (AGENTS.md Â§6): m=19456 KiB, t=2, p=1, salt 16 B, hash 32 B.

| Caso | Latencia |
|---|---|
| `cryptography` en `Isolate.run` (5 rep.) | 194 / 186 / 195 / 181 / 190 ms (mediana ~190 ms) |
| `cryptography` en hilo principal | 177 ms |

Dentro del rango objetivo (100â€“300 ms). En `Isolate` no bloquea el event loop de la API (requisito Â§6: fuera del hilo principal). Los cinco resultados son idÃ©nticos (mismo salt) â†’ determinismo correcto.

Nota: los tests internos del paquete (`test/algorithms/argon2_test.dart`) validan sus vectores propios (con `secret` y `associatedData`); la validaciÃ³n cruzada hecha aquÃ­ contra el binario C de referencia es la evidencia de interop.

## 4. AnÃ¡lisis de deploy (Dockerfile)

- `infra/api.Dockerfile`: build en `dart:3.13.5`, `dart compile exe`, imagen final **`scratch`** sin libc del usuario.
- **`cryptography`**: Dart puro, arborescencia podable; compila dentro del AOT sin cambios. Zero riesgos de deploy (tambiÃ©n funciona en Windows dev, macOS, Linux, web admin si algÃºn dÃ­a se necesitara).
- **`argon2_ffi`**: es un **plugin Flutter**, no un paquete Dart de servidor. En dev Windows no funciona sin compilar la DLL (confirmado: `Failed to load dynamic library 'argon2_ffi_plugin.dll'`). En la imagen Docker habrÃ­a que compilar `libargon2_ffi_plugin.so` desde las fuentes empaquetadas con CMake y copiarla a una imagen final que admita ese `.so` â€” incompatidad directa con `scratch`. Beneficio real: potencialmente 2â€“4Ã— mÃ¡s rÃ¡pido que Dart puro, pero no necesario a ~190 ms.

## 5. Riesgos

- **PHC manual**: `cryptography` devuelve el hash crudo; el formato `$argon2id$v=19$m=â€¦,t=â€¦,p=â€¦$salt$hash` se construye en un adaptador propio (`JwtArgon2PasswordHasher` â†’ `adapters/out/`). Riesgo mitigado: el vector de arriba ya valida la construcciÃ³n; se fijarÃ¡ como test unitario contra esa cadena exacta.
- **Salt aleatorio**: el paquete no genera la cadena PHC ni el salt; generarlo con `SecureRandom` del mismo paquete o `Random.secure()` (â‰¥16 bytes).
- **Aislamiento**: ejecutar siempre en `Isolate.run` (verificado); si en producciÃ³n sube el volumen de logins, aÃ±adir pool de workers.
- **Rendimiento pure-Dart vs nativo**: acceptable en dev; si en producciÃ³n supera el presupuesto de CPU, el camino es aÃ±adir `parallelism` real o migrar a una implementaciÃ³n FFI compilada dentro del Dockerfile â€” decisiÃ³n futura, no bloquea.
- `argon2_ffi` queda descartado: sin binario precompilado para server-side, rompe la imagen `scratch`, y el equipo agregarÃ­a coste de compilaciÃ³n de C por poca ganancia.
- `argon2` 1.0.1 descartado: incompatible con Dart 3 (sdk <3.0.0), salvo fork â€” no aplica.

## 6. ConclusiÃ³n

**RecomendaciÃ³n**: `cryptography` (2.9.0), ejecutada en `Isolate.run`, con adaptador propio que emita/parseÃ© el formato PHC fijando como test el vector verificado contra el binario C oficial.

**DecisiÃ³n humana**: PENDIENTE

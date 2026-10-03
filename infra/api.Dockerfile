# Imagen de la API y el worker de Paseo Points (misma imagen, distinto binario).
# Base fijada tras verificación con `docker pull` (03/10/2026). INFRASTRUCTURE.md §2/§14.

FROM dart:3.13.5 AS build

# dart_frog_cli fijado: 1.2.14 (última versión activada con
# `dart pub global activate dart_frog_cli` el 03/10/2026). Nunca sin versión.
RUN dart pub global activate dart_frog_cli 1.2.14
ENV PATH="$PATH:/root/.pub-cache/bin"

WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
COPY packages/paseo_shared ./packages/paseo_shared
COPY apps/api ./apps/api

# El workspace raíz (pubspec.yaml) declara apps/mobile, que depende del SDK de
# Flutter y no es resoluble en esta imagen solo-Dart. Se recorta la entrada del
# workspace solo dentro del build (el repo no se toca). Guards: el build falla
# en el punto real si la línea no está en su forma esperada o si el recorte no
# surte efecto.
RUN grep -qE '^\s*-\s*apps/mobile' pubspec.yaml && \
    sed -i '/- apps\/mobile/d' pubspec.yaml && \
    ! grep -q apps/mobile pubspec.yaml

# Guarda del lockfile (sustituto hermético de --enforce-lockfile, que no se
# puede usar porque el pubspec editado y el lockfile difieren deliberadamente).
# Verificado 03/10/2026: al excluir apps/mobile, pub solo ELIMINA del lockfile
# las entradas exclusivas de Flutter (flutter, flutter_test, sky_engine,
# leak_tracker*, material_color_utilities, vector_math y el sdk constraint);
# ninguna dependencia real de la API cambia. La guarda exige exactamente eso:
# el lockfile resuelto en el contenedor debe ser una subsecuencia estricta del
# versionado (diff sin líneas '<', es decir, cero entradas nuevas ni
# modificadas). Si pub resolviera cualquier versión distinta de la versionada,
# el build falla aquí.
RUN cp pubspec.lock pubspec.lock.orig
WORKDIR /src/apps/api
RUN dart pub get
WORKDIR /src
RUN ! diff pubspec.lock pubspec.lock.orig | grep -q '^<' && rm pubspec.lock.orig
WORKDIR /src/apps/api

# Build de Dart Frog (genera build/bin/server.dart) y compilación AOT de los
# tres binarios: servidor real, worker y healthcheck.
RUN mkdir /out && dart_frog build && \
    dart compile exe build/bin/server.dart -o /out/server && \
    dart compile exe bin/worker.dart -o /out/worker && \
    dart compile exe bin/healthcheck.dart -o /out/healthcheck

FROM scratch AS runtime
# Los ejecutables AOT de Dart enlazan contra glibc: se copian las bibliotecas
# mínimas (verificadas con `ldd` sobre /app/server, 03/10/2026) para poder
# mantener scratch sin shell.
COPY --from=build /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2
COPY --from=build /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0
COPY --from=build /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=build /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=build /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=build /out/server /app/server
COPY --from=build /out/worker /app/worker
COPY --from=build /out/healthcheck /app/healthcheck
USER 10001:10001
EXPOSE 8080
# Nota: la imagen scratch no trae shell ni wget/curl; el healthcheck del compose
# usa el binario compilado /app/healthcheck en forma exec (test: ["CMD", ...]).
ENTRYPOINT ["/app/server"]

# Auto-verificación en build: ejecuta el worker (binario AOT) dentro de la propia
# imagen scratch. Si faltara alguna biblioteca glibc copiada, el loader fallaría
# y el build se rompería aquí, no en producción. No se puede auto-verificar
# /app/server ni /app/healthcheck (necesitan la red del contenedor en ejecución);
# el worker ejercita el mismo runtime y set de libs. La imagen resultante es
# idéntica a la del stage runtime (este stage no añade capas de contenido).
FROM runtime AS verify
RUN ["/app/worker"]

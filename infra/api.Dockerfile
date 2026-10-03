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
# workspace solo dentro del build (el repo no se toca). Por eso no se usa
# --enforce-lockfile: el pubspec editado y el lockfile sin entradas Flutter
# difieren deliberadamente.
RUN sed -i '/- apps\/mobile/d' pubspec.yaml

WORKDIR /src/apps/api
RUN dart pub get

# Build de Dart Frog (genera build/bin/server.dart) y compilación AOT de los
# tres binarios: servidor real, worker y healthcheck.
RUN mkdir /out && dart_frog build && \
    dart compile exe build/bin/server.dart -o /out/server && \
    dart compile exe bin/worker.dart -o /out/worker && \
    dart compile exe bin/healthcheck.dart -o /out/healthcheck

FROM scratch
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

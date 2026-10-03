# Imagen de la API y el worker de Paseo Points (misma imagen, distinto binario).
# Base fijada tras verificación con `docker pull` (03/10/2026). INFRASTRUCTURE.md §2/§14.

FROM dart:3.13.5 AS build

# Build del workspace completo: la API depende de packages/paseo_shared.
WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
COPY packages/paseo_shared ./packages/paseo_shared
COPY apps/api ./apps/api

WORKDIR /src/apps/api
RUN dart pub get --enforce-lockfile

# Compilación AOT de los dos puntos de entrada.
RUN dart compile exe bin/server.dart -o /out/server && \
    dart compile exe bin/worker.dart -o /out/worker && \
    printf '#!/bin/sh\nexec wget -q -O- http://127.0.0.1:8080/health | grep -q ok\n' > /out/healthcheck && \
    chmod +x /out/healthcheck

FROM scratch
COPY --from=build /out/server /app/server
COPY --from=build /out/worker /app/worker
COPY --from=build /out/healthcheck /app/healthcheck
USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["/app/server"]

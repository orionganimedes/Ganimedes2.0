# =============================================================================
# Ganimedes Backend — PocketBase v0.25.9
#
# Imagen mínima basada en Alpine Linux. El binario de PocketBase es un
# ejecutable Go estático (CGO_ENABLED=0), por lo que corre sin glibc.
# =============================================================================
FROM alpine:3.20

# Certificados TLS + zona horaria + curl (para el healthcheck)
RUN apk add --no-cache ca-certificates tzdata curl

# Usuario sin privilegios (buena práctica: no correr como root)
RUN addgroup -S pb && adduser -S pb -G pb

WORKDIR /app

# 1) Binario precompilado (estático, x86-64)
COPY pocketbase /app/pocketbase

# 2) Migraciones de esquema (se aplican automáticamente al arrancar)
COPY pb_migrations /app/pb_migrations

# 3) Hooks JS (lógica de negocio) y archivos estáticos públicos
COPY pb_hooks /app/pb_hooks
COPY pb_public /app/pb_public

# 4) Script de arranque
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /app/pocketbase /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p /app/pb_data \
    && chown -R pb:pb /app

USER pb
EXPOSE 8090

# El directorio de datos se persiste vía volumen (queda fuera de la imagen)
VOLUME ["/app/pb_data"]

# Healthcheck usando el endpoint nativo de PocketBase
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8090/api/health || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

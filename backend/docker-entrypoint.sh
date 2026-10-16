#!/bin/sh
set -e

# -----------------------------------------------------------------------------
# Entrypoint del contenedor Ganimedes Backend (PocketBase)
#   1) Aplica migraciones pendientes (idempotente; inicializa una BD nueva)
#   2) Crea/actualiza el superusuario a partir de variables de entorno
#   3) Arranca el servidor
# -----------------------------------------------------------------------------

echo "[entrypoint] Aplicando migraciones pendientes..."
/app/pocketbase migrate up

# Bootstrap del superusuario (opcional, vía variables de entorno).
# NOTA: 'upsert' aplica el password en CADA arranque; si cambias la clave
# desde el panel admin, actualiza también el .env para que no se revierta.
if [ -n "$PB_ADMIN_EMAIL" ] && [ -n "$PB_ADMIN_PASSWORD" ]; then
  echo "[entrypoint] Configurando superusuario: ${PB_ADMIN_EMAIL}"
  /app/pocketbase superuser upsert "$PB_ADMIN_EMAIL" "$PB_ADMIN_PASSWORD"
fi

SERVE_ARGS="--http=0.0.0.0:8090"

# Cifrado de configuraciones sensibles (opcional, producción)
if [ -n "$PB_ENCRYPTION_KEY" ]; then
  SERVE_ARGS="$SERVE_ARGS --encryptionEnv=PB_ENCRYPTION_KEY"
fi

echo "[entrypoint] Iniciando PocketBase en 0.0.0.0:8090"
exec /app/pocketbase serve $SERVE_ARGS

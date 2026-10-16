#!/usr/bin/env bash
# Arranque de Ganimedes POS para panel PC.
#
#   1. Comprueba si PocketBase responde (opcional: la app funciona sin él).
#   2. Compila en modo release sólo si hace falta.
#   3. Lanza el binario nativo.
#
# Uso:  ./start.sh          (o)  POCKETBASE_URL=http://otro:8090 ./start.sh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$PROJECT_DIR/target/release/ganimedes-pos"
POCKETBASE_URL="${POCKETBASE_URL:-http://localhost:8090}"

cd "$PROJECT_DIR"

echo "==> Ganimedes POS"

# --- Backend opcional ------------------------------------------------------
if curl -sf --max-time 2 "$POCKETBASE_URL/api/health" >/dev/null 2>&1; then
    echo "==> PocketBase disponible en $POCKETBASE_URL"
else
    echo "==> PocketBase no responde en $POCKETBASE_URL (se continúa en modo local)"
fi

# --- Compilación bajo demanda ---------------------------------------------
necesita_build=0
if [ ! -x "$BIN" ]; then
    necesita_build=1
elif [ -n "$(find src Cargo.toml Cargo.lock -newer "$BIN" -print -quit 2>/dev/null)" ]; then
    necesita_build=1
fi

if [ "$necesita_build" -eq 1 ]; then
    echo "==> Compilando en modo release..."
    cargo build --release
fi

echo "==> Lanzando $BIN"
exec "$BIN" "$@"

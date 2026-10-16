#!/usr/bin/env bash
# Vista previa de la pantalla de acceso (src/ui/screens/login.rs).
#
# Uso, desde cualquier sitio:
#     bash crates/login-preview/run.sh
#
# Es un miembro del workspace, así que comparte Cargo.lock y target/ con el
# binario principal. Se puede forzar otro destino de compilación:
#     CARGO_TARGET_DIR=/tmp/prueba bash crates/login-preview/run.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
proyecto="$(cd "$here/../.." && pwd)"

cd "$proyecto"
echo "→ Vista previa del login (workspace: $proyecto)"
exec cargo run -p ganimedes-login-preview "$@"

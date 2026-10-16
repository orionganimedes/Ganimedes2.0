# Compilación y distribución

## Requisitos

- Rust 1.75+ (`rustup`). Comprobar con `rustc --version`.
- Linux: servidor gráfico X11 o Wayland.
- Windows: 10/11 x86_64.

Dependencias de sistema en Fedora:

```bash
sudo dnf install libxkbcommon wayland-devel mesa-libGL
```

En Debian/Ubuntu:

```bash
sudo apt install libxkbcommon-dev libwayland-dev libgl1-mesa-dev
```

## Comandos

| Objetivo | Comando |
|----------|---------|
| Desarrollo | `cargo run` |
| Producción | `cargo build --release` |
| Ejecutar el binario | `./target/release/ganimedes-pos` |
| Pruebas | `cargo test --workspace` |
| Comprobar sin compilar | `cargo check --workspace` |
| Vista previa del login | `cargo run -p ganimedes-login-preview` |
| Arranque del panel | `./start.sh` |

## Perfiles

`Cargo.toml` define dos perfiles:

- **`release`**: `opt-level = 3`, `lto = true`, `codegen-units = 1`,
  `panic = "abort"` y `strip = true`. Produce un binario de unos **7 MB** sin
  símbolos.
- **`dev`**: sin optimizar el crate propio, pero con
  `[profile.dev.package."*"] opt-level = 2` para que `egui`/`eframe` no vayan a
  tirones durante el desarrollo.

La compilación de release tarda alrededor de 40 s en un equipo de escritorio
moderno (la primera vez más, porque compila todas las dependencias).

## Variables de entorno

| Variable | Efecto |
|----------|--------|
| `GANIMEDES_AUTOLOGIN` | Modo kiosco. Con `1`/`true`/`yes` entra como `admin`; con un nombre de usuario (p. ej. `cajero`) entra como ése; con `0`/`false`/`no` o sin definir, muestra el acceso. Pensado para terminales dedicados. |
| `POCKETBASE_URL` | URL del backend. La usa `start.sh` para comprobar disponibilidad. |
| `RUST_LOG` | Nivel de trazas (pendiente de inicializar un logger). |

Ejemplo de arranque en kiosco:

```bash
# Acceso normal
./start.sh

# Terminal de caja: entra solo como cajero
GANIMEDES_AUTOLOGIN=cajero POCKETBASE_URL=http://10.0.0.5:8090 ./start.sh
```

## Distribución

El binario es autocontenido salvo por las bibliotecas gráficas del sistema:

```bash
cargo build --release
install -Dm755 target/release/ganimedes-pos /usr/local/bin/ganimedes-pos
```

Para empaquetar, copiar junto al binario:

1. `ganimedes-pos`
2. `.env` (a partir de `.env.example`)
3. Opcionalmente `start.sh`

El directorio `dist/` está reservado para artefactos de empaquetado y está
ignorado por git.

### Compilación cruzada a Windows desde Linux

```bash
rustup target add x86_64-pc-windows-gnu
cargo build --target x86_64-pc-windows-gnu --release
```

El binario resultante es `target/x86_64-pc-windows-gnu/release/ganimedes-pos.exe`.

## Notas

- Las fuentes Inter están **embebidas** en el binario mediante
  `include_bytes!` desde `assets/fonts/`. Si se mueven, hay que actualizar las
  rutas de `src/ui/theme.rs`; el compilador falla si no existen, así que no
  puede pasar desapercibido.
- `target/` puede borrarse sin miedo: se regenera con `cargo build`.
- El workspace comparte un único `Cargo.lock`; conviene versionarlo para que las
  compilaciones sean reproducibles.

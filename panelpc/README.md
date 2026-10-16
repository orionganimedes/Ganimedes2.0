# Ganimedes POS — Panel PC

Punto de venta nativo para **panel PC** y terminales táctiles, escrito
íntegramente en **Rust** sobre [`eframe`/`egui`](https://github.com/emilk/egui).

Binario único, sin runtime ni dependencias de sistema más allá de las gráficas:
arranque casi instantáneo, unos 7 MB de ejecutable y sin intérprete embebido.

> Este repositorio **ya no contiene Flutter**. Se eliminaron las plataformas
> Android/iOS/Linux/macOS/Web/Windows de Flutter, `pubspec.*`, `lib/`, `test/`
> y todos sus artefactos de compilación. El proyecto es Rust puro.

---

## Estado actual

| Área | Estado |
|------|--------|
| Pantalla de acceso (`ui/screens/login.rs`) | Funcional, con validación local |
| Usuarios y roles (`core/user.rs`) | Funcional, 3 cuentas de prueba |
| Enrutado acceso → POS (`app/main_screen.rs`) | Funcional, con cierre de sesión |
| Catálogo + buscador + filtros por categoría | Funcional, 12 productos sembrados |
| Carrito (añadir, incrementar, decrementar, vaciar) | Funcional |
| Descuento porcentual y totales | Funcional |
| Modal de cobro y métodos de pago | Funcional |
| Persistencia local del catálogo (SQLite) | Funcional (en memoria, se siembra al abrir) |
| Cliente de PocketBase (`infra/backend.rs`) | Escrito, **pendiente de conectar a la UI** |

El punto de integración con el backend está aislado y documentado en
[`docs/BACKEND.md`](docs/BACKEND.md).

---

## Requisitos

- Toolchain de Rust 1.75 o superior (`rustup`).
- Linux con X11 o Wayland, o Windows 10/11.
- Bibliotecas gráficas habituales de `egui` (en Fedora: `libxkbcommon`,
  `wayland-devel`, `mesa-libGL`).

---

## Compilar y ejecutar

```bash
# Desarrollo (perfil dev, dependencias optimizadas)
cargo run

# Modo kiosco: entra directamente al POS (como admin).
# También admite elegir cuenta: GANIMEDES_AUTOLOGIN=cajero
GANIMEDES_AUTOLOGIN=1 cargo run

# Producción
cargo build --release
./target/release/ganimedes-pos
```

Atajo que compila sólo si hace falta y comprueba el backend:

```bash
./start.sh
```

### Usuarios de prueba

Mientras no haya backend conectado, el acceso valida contra el catálogo de
demostración de [`src/core/user.rs`](src/core/user.rs). Son **credenciales de
desarrollo**: hay que eliminarlas antes de desplegar.

| Usuario | Contraseña | Rol | Notas |
|---------|-----------|-----|-------|
| `admin` | `admin` | Administrador | También válido su correo `admin@ganimedes.pos` |
| `cajero` | `cajero` | Cajero | `cajero@ganimedes.pos` |
| `barbero` | `barbero` | Barbero | `barbero@ganimedes.pos`, silla `S-03` |

Se puede entrar indistintamente con el **usuario o el correo**, sin distinguir
mayúsculas. La pantalla de acceso muestra estas cuentas en una fila pulsable:
al hacer clic en una, el formulario se rellena solo, para poder verificar la
interfaz sin teclear.

El usuario con el que se entra se refleja en la barra superior del POS
(nombre, rol y silla), y el cierre de sesión devuelve al acceso olvidando la
sesión.

---

## Pruebas

```bash
cargo test --workspace
```

Cubren el enrutado de pantallas, la validación de cada usuario de prueba y sus
roles, el carrito y sus totales, el sembrado del catálogo, el sistema de
diseño, el dibujo de iconos y el presupuesto vertical del formulario de acceso.

---

## Estructura del proyecto

```
panelpc/
├── Cargo.toml                  Manifiesto y workspace (raíz + crates/*)
├── Cargo.lock                  Versiones fijadas (compartido por el workspace)
├── start.sh                    Arranque para el panel PC
├── .env.example                Plantilla de configuración de PocketBase
│
├── src/
│   ├── main.rs                 Entrada del binario: sólo abre la ventana
│   ├── lib.rs                  Raíz de la biblioteca y reglas de dependencia
│   │
│   ├── app/                    Aplicación: arranque y enrutado
│   │   ├── mod.rs
│   │   └── main_screen.rs      PosApp: acceso ⇄ POS, autologin, sesión
│   │
│   ├── core/                   Dominio puro (sin egui, sin I/O)
│   │   ├── mod.rs
│   │   ├── models.rs           Product, CartItem, PaymentMethod
│   │   ├── state.rs            PosState: catálogo, carrito, descuento, totales
│   │   └── user.rs             Usuario, Rol y las cuentas de prueba
│   │
│   ├── infra/                  Adaptadores externos
│   │   ├── mod.rs
│   │   ├── db.rs               SQLite local + sembrado del catálogo
│   │   └── backend.rs          Cliente REST de PocketBase
│   │
│   └── ui/                     Presentación (egui)
│       ├── mod.rs
│       ├── theme.rs            Tokens de DESIGN.md, Inter, ayudas de dibujo
│       ├── screens/            Pantallas completas
│       │   ├── mod.rs
│       │   ├── login.rs        Pantalla de acceso
│       │   └── pos.rs          Catálogo, carrito y modal de cobro
│       └── widgets/            Componentes de dibujo
│           ├── mod.rs
│           └── icons.rs        Iconos vectoriales (persona, candado, ojo…)
│
├── crates/
│   └── login-preview/          Herramienta de desarrollo (miembro del workspace)
│
├── assets/
│   └── fonts/                  Inter Regular/SemiBold/Bold + licencia
│
├── design/                     Referencias del sistema de diseño
│   ├── DESIGN.md               Especificación de color, tipografía y componentes
│   ├── code.html               Boceto original
│   └── *.png                   Capturas de referencia
│
└── docs/
    ├── ARCHITECTURE.md         Capas, reglas de dependencia y flujo de datos
    ├── BUILD.md                Compilación, perfiles y distribución
    └── BACKEND.md              Integración con PocketBase
```

### Regla de dependencias

El proyecto se organiza en capas con dependencias **unidireccionales**:

```
        app  ──────►  ui  ──────►  core
         │                          ▲
         └──────►  infra  ─────────┘
```

- `core` no conoce `egui`, ni SQLite, ni HTTP: es dominio puro y testeable.
- `infra` implementa los adaptadores externos.
- `ui` dibuja; no tiene lógica de negocio.
- `app` es la única capa que conoce a todas las demás y decide qué pantalla se ve.

Detalles en [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Vista previa del acceso

Herramienta para iterar sólo la pantalla de acceso sin navegar por el POS:

```bash
cargo run -p ganimedes-login-preview
```

Reutiliza los módulos reales de la biblioteca, así que no hay copias que se
desincronicen.

---

## Sistema de diseño

La interfaz sigue [`design/DESIGN.md`](design/DESIGN.md): lienzo azul marino
(`#0b1326`), acentos cian eléctricos (`#4cd6fb`), primario azul (`#1d4ed8`) y
tipografía **Inter** con cifras tabulares. Todos los tokens viven en
[`src/ui/theme.rs`](src/ui/theme.rs); no hay colores sueltos en las pantallas.

---

## Licencia

MIT.

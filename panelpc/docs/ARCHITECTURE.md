# Arquitectura

## Objetivo

Mantener el punto de venta dividido en capas con una única dirección de
dependencias, de forma que la lógica de negocio sea testeable sin abrir una
ventana y que cambiar el backend no obligue a tocar la interfaz.

## Capas

```
┌──────────────────────────────────────────────────────────────┐
│ app/            Arranque, enrutado y ciclo de vida            │
│  main_screen.rs → PosApp (Login ⇄ POS, sesión, autologin)     │
└───────────────┬──────────────────────────┬───────────────────┘
                │                          │
                ▼                          ▼
┌───────────────────────────────┐  ┌──────────────────────────┐
│ ui/            Presentación    │  │ infra/    Adaptadores    │
│  theme.rs     tokens + Inter   │  │  db.rs    SQLite local   │
│  screens/     login, pos       │  │  backend.rs  PocketBase  │
│  widgets/     icons            │  └────────────┬─────────────┘
└───────────────┬───────────────┘               │
                │                               │
                ▼                               ▼
        ┌───────────────────────────────────────────────┐
        │ core/   Dominio puro (sin egui, sin I/O)       │
        │  models.rs  Product, CartItem, PaymentMethod   │
        │  state.rs   PosState: catálogo, carrito…       │
        │  user.rs    Usuario, Rol, cuentas de prueba    │
        └───────────────────────────────────────────────┘
```

### Reglas

1. **`core` no depende de nada del proyecto.** No importa `eframe`, ni
   `rusqlite`, ni `reqwest`. Sus tests corren sin entorno gráfico.
2. **`ui` no contiene lógica de negocio.** Calcula totales leyendo `PosState`;
   no decide reglas de descuento ni de carrito.
3. **`infra` no conoce la interfaz.** Expone tipos de datos, nunca widgets.
4. **Sólo `app` conoce a todas las capas.** Las pantallas no se conocen entre
   sí: el paso de acceso a POS lo decide `PosApp`.

Estas reglas son verificables: `core` y `infra` no aparecen en ningún `use` de
`ui`, y `ui::screens::login` no menciona `pos`.

## Flujo de datos

```
  Usuario
     │  clic / tecla
     ▼
  ui/screens/pos.rs ──── muta ────► core/state.rs (PosState)
     │                                    │
     │                                    │ lee catálogo al arrancar
     │                                    ▼
     │                             infra/db.rs (SQLite)
     │
     └── dibuja ◄──── lee estado y totales calculados en core
```

El carrito vive **en memoria** dentro de `PosState`, porque es estado de sesión.
El catálogo sí se lee de SQLite al arrancar. Al confirmar una venta, el sitio
natural para persistir es PocketBase (ver [`BACKEND.md`](BACKEND.md)).

## Enrutado de pantallas

`app/main_screen.rs` define el único punto de decisión:

```rust
pub enum Screen { Login, Pos }
```

- `Screen::Login` dibuja `LoginScreen::ui()` dentro de un `CentralPanel`.
- Al devolver `LoginAction::Submit`, `PosApp::try_login()` valida y llama a
  `enter_pos()`.
- `PosScreen::ui()` recibe el usuario de sesión (`Option<&Usuario>`) y
  **devuelve `bool`**: `true` significa "el usuario pidió cerrar sesión", y
  `PosApp` vuelve al acceso.

Que la pantalla devuelva un valor en lugar de cambiar de estado ella misma es lo
que mantiene el desacoplamiento entre pantallas.

## Usuarios y sesión

`core/user.rs` define `Usuario` y `Rol` (Admin, Cajero, Barbero) junto al
catálogo `USUARIOS_DEMO`. `PosApp` guarda `sesion: Option<&'static Usuario>` y
se lo pasa al POS, que muestra nombre, rol y silla en la barra superior.

La validación se hace en el dominio, no en la pantalla:

```rust
pub fn autenticar(identificador: &str, password: &str) -> Option<&'static Usuario>
```

Admite usuario o correo, ignora mayúsculas y exige que la cuenta esté activa.
Los campos replican los de `UserRecord` del backend (`role`, `chair`, `shift`,
`branch_code`), así que al conectar PocketBase el tipo se sustituye sin cambiar
la interfaz.

## Punto de integración con PocketBase

`PosApp::try_login()` es el único sitio que hay que cambiar para autenticar
contra el backend. El cuerpo actual delega en el catálogo de demostración:

```rust
fn try_login(&mut self) -> bool {
    match user::autenticar(&self.login.username, &self.login.password) {
        Some(u) => { self.sesion = Some(u); true }
        None => false,
    }
}
```

Sustituirlo por `BackendClient::auth_with_password` requiere un runtime async;
ver las opciones en [`BACKEND.md`](BACKEND.md).

## Sistema de diseño

`ui/theme.rs` es la única fuente de color, tipografía y radios. Las pantallas
importan tokens con nombre (`ON_SURFACE`, `PRIMARY_CONTAINER`…) y nunca escriben
literales `Color32::from_rgb(...)`. Los valores provienen de
[`design/DESIGN.md`](../design/DESIGN.md).

`theme::install(&ctx)` se llama una sola vez en `PosApp::new` y deja
configurados los estilos globales y las fuentes Inter embebidas, de modo que el
acceso y el POS comparten exactamente el mismo aspecto.

## Workspace

```
panelpc/            crate principal: biblioteca + binario
crates/login-preview/   herramienta de desarrollo
```

Ambos comparten `Cargo.lock` y `target/`. El crate principal expone su
biblioteca (`ganimedes_pos`) para que la herramienta de vista previa reutilice
los módulos reales en lugar de copiarlos.

## Añadir una pantalla nueva

1. Crear `src/ui/screens/nueva.rs` con una struct que tenga `new()` y un método
   `ui(...)` que devuelva una acción (no que cambie el estado global).
2. Declararla en `src/ui/screens/mod.rs`.
3. Añadir la variante a `Screen` en `app/main_screen.rs` y su rama en `update`.
4. Mantener la lógica de negocio en `core`, no en la pantalla.

# Integración con PocketBase

## Situación

El cliente HTTP está **escrito y compila** en
[`src/infra/backend.rs`](../src/infra/backend.rs), pero **todavía no está
conectado a la interfaz**. La aplicación funciona hoy con:

- el catálogo sembrado en SQLite local (`src/infra/db.rs`), y
- una validación de credenciales local en `PosApp::try_login`.

Este documento describe qué hay ya hecho y qué falta para conectar el backend.

## El cliente actual

```rust
use crate::infra::backend::BackendClient;

let client = BackendClient::new("http://localhost:8090")?;
let auth = client.auth_with_password("admin@ejemplo.com", "secreto").await?;
let productos = client.get_products().await?;
```

Métodos disponibles:

| Área | Métodos |
|------|---------|
| Autenticación | `auth_with_password`, `auth_with_oauth2`, `set_auth_token` |
| Productos y servicios | `get_products`, `get_product_by_id`, `search_products` |
| Catálogo | `get_categories` |
| Ventas | `create_sale`, `create_sale_item`, `get_sales` |
| Sucursales | `get_branches`, `get_branch_by_code` |
| Sillas | `get_chairs`, `update_chair_status` |

Tipos de escritura: `SaleData`, `SaleItemData`, `CartItemData`. Las lecturas
genéricas devuelven `Record`, que aplana los campos en un `HashMap` de
`serde_json::Value`.

## El obstáculo: asincronía

Todos los métodos del cliente son `async` (usan `reqwest`), mientras que
`eframe::App::update` es **síncrono** y se ejecuta en cada fotograma. No se
puede hacer `.await` dentro del bucle de dibujo sin bloquear la interfaz.

Hay tres formas razonables de resolverlo, de menos a más invasiva.

### Opción A — Tarea en segundo plano con canal (recomendada)

Mantener un runtime de Tokio creado una sola vez y lanzar las peticiones desde
`update`, recogiendo el resultado por un `std::sync::mpsc`.

```rust
// En el estado de la aplicación:
runtime: tokio::runtime::Runtime,
rx: std::sync::mpsc::Receiver<MensajeBackend>,
```

En `update`, hacer `try_recv()` sin bloquear para aplicar lo que haya llegado, y
lanzar nuevas peticiones con `runtime.spawn(...)`. La interfaz nunca se congela
y se puede mostrar un indicador de "cargando".

Requiere añadir `tokio` a `Cargo.toml`:

```toml
tokio = { version = "1", features = ["rt-multi-thread", "macros"] }
```

### Opción B — Bloquear sólo en el arranque

Cargar catálogo y credenciales antes de abrir la ventana, usando
`runtime.block_on(...)`. Es lo más sencillo y aceptable si el backend es local:

```rust
fn main() -> eframe::Result<()> {
    let rt = tokio::runtime::Runtime::new().unwrap();
    let catalogo = rt.block_on(cargar_catalogo())?;
    // pasar `catalogo` a PosApp
    …
}
```

Contrapartida: si el servidor no responde, el arranque se queda esperando.

### Opción C — Cliente síncrono

Sustituir `reqwest` por `ureq` o usar `reqwest::blocking`. Elimina la
asincronía por completo, a costa de bloquear el hilo de la interfaz durante cada
petición.

## Dónde conectar cada cosa

| Necesidad | Punto de integración |
|-----------|----------------------|
| Autenticación | `PosApp::try_login` en [`src/app/main_screen.rs`](../src/app/main_screen.rs) — hoy delega en `core::user::autenticar` (catálogo `USUARIOS_DEMO`); es el único sitio a cambiar. |
| Cargar catálogo | `PosState::new` en [`src/core/state.rs`](../src/core/state.rs) — hoy llama a `LocalDatabase::get_all_products`. |
| Registrar la venta | `PosState::complete_sale` — hoy sólo vacía el carrito; debe crear la venta y sus líneas con `create_sale` / `create_sale_item`. |
| Estado de sillas | Sin uso todavía; `update_chair_status` está disponible. |

Conviene mantener el patrón actual: `core` define **qué** se necesita y `infra`
implementa **cómo** se obtiene. La interfaz no debería llamar nunca a
`BackendClient` directamente.

## Colecciones esperadas

| Colección | Contenido |
|-----------|-----------|
| `admins` | Usuarios con `role`, `pin`, `chair`, `shift` |
| `branches` | Sucursales |
| `categories` | Categorías de productos |
| `products_services` | Productos y servicios |
| `chairs` | Sillas de barbería y su estado |
| `cash_shifts` | Cortes de caja |
| `cash_movements` | Movimientos de efectivo |
| `sales` | Ventas y tickets |
| `sale_items` | Detalle de cada venta |

`UserRecord` ya refleja los campos `role`, `pin`, `chair`, `shift`,
`branch_code` e `is_active`.

## Poner en marcha el backend

```bash
cd ../backend
chmod +x pocketbase
./pocketbase serve          # API en :8090, panel de administración en :8090/_
```

Comprobar que responde:

```bash
curl -s http://localhost:8090/api/health
```

## Configuración

`.env.example` documenta las variables previstas:

```bash
POCKETBASE_URL=http://localhost:8090
POCKETBASE_EMAIL=admin@panelpc.local
POCKETBASE_PASSWORD=admin123456
DEFAULT_BRANCH_CODE=MAIN01
DEBUG_MODE=true
```

> **Nota:** la aplicación todavía **no lee** este archivo. `start.sh` sólo usa
> `POCKETBASE_URL` para comprobar si el servidor está vivo. Al conectar el
> cliente habrá que cargar el `.env` (por ejemplo con el crate `dotenvy`) o leer
> las variables del entorno directamente.

## Riesgos a tener en cuenta

- **Credenciales de demostración.** Las tres cuentas de `core/user.rs`
  (`admin`, `cajero`, `barbero`) y las de `.env.example` son valores de
  desarrollo: deben desaparecer antes de desplegar en producción. Además, la
  pantalla de acceso **las muestra en pantalla** a propósito para poder probar
  la interfaz; al conectar PocketBase hay que borrar `credenciales_de_prueba()`
  de `src/ui/screens/login.rs` y su llamada.
- **`panic = "abort"`.** El perfil de release aborta en lugar de desenrollar la
  pila, así que un `panic!` cierra la aplicación sin mensaje. Los errores del
  backend deben devolverse como `Result` y mostrarse en la interfaz.
- **Errores silenciosos.** Hoy `PosState::new` hace `.expect(...)`; si el
  catálogo remoto falla, la aplicación no arranca. Conviene degradar a un
  catálogo vacío con aviso visible.

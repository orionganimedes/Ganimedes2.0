# Panel - Punto de Venta

Sistema de punto de venta desarrollado en Rust con egui.

## Requisitos

- Rust y Cargo (instalados)
- Sistema operativo: Windows o Linux

## Compilación

```bash
cd panel
cargo build --release
```

## Ejecución

```bash
cargo run --release
```

## Credenciales de prueba

- Usuario: `admin`
- Contraseña: `1234`

## Estructura del proyecto

```
panel/
├── src/
│   ├── main.rs      # Punto de entrada de la aplicación
│   ├── login.rs     # Pantalla de inicio de sesión
│   └── home.rs      # Pantalla principal (Punto de Venta)
├── Cargo.toml       # Configuración del proyecto
└── README.md
```

## Características

- Sistema de login
- Interfaz de punto de venta
- Búsqueda de productos
- Categorías
- Carrito de compras

## Plataformas soportadas

- Windows
- Linux

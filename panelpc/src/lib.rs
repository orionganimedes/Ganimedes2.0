//! Ganimedes Panel POS — biblioteca de la aplicación.
//!
//! Organización por capas, de dentro hacia fuera:
//!
//! | Módulo   | Responsabilidad                                      |
//! |----------|------------------------------------------------------|
//! | [`core`] | Dominio puro: modelos y estado. Sin `egui`, sin I/O.  |
//! | [`infra`]| Adaptadores: SQLite local y cliente de PocketBase.    |
//! | [`ui`]   | Tema, componentes y pantallas de `egui`.              |
//! | [`app`]  | Arranque y enrutado entre pantallas.                  |
//!
//! La regla de dependencias es unidireccional: `app` → `ui` → `core`; `infra`
//! sólo es consumido por `core`/`app`. Ninguna capa interna conoce a una capa
//! superior.

pub mod app;
pub mod core;
pub mod infra;
pub mod ui;

pub use app::main_screen::PosApp;

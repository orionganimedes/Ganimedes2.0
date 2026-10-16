//! Núcleo del dominio: modelos de datos y estado de la aplicación.
//!
//! Esta capa no depende de `eframe`/`egui` ni de ningún detalle de
//! infraestructura. Es la parte más estable y la más fácil de testear.

pub mod models;
pub mod state;
pub mod user;

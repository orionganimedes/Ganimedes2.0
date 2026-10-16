//! Adaptadores de infraestructura: persistencia local y cliente de backend.
//!
//! Son los únicos módulos que hablan con el exterior (SQLite en memoria y la
//! API REST de PocketBase). El resto de la aplicación los consume a través de
//! sus tipos públicos, nunca al revés.

pub mod backend;
pub mod db;

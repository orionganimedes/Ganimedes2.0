//! Punto de entrada del binario.
//!
//! Sólo configura la ventana nativa y arranca [`ganimedes_pos::PosApp`]. Toda
//! la orquestación vive en la biblioteca (`src/lib.rs`), de modo que los tests
//! y las herramientas de `crates/` pueden reutilizar los mismos módulos.

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use eframe::egui::Vec2;
use ganimedes_pos::PosApp;

/// Tamaño inicial pensado para paneles táctiles de 10".
const VENTANA_INICIAL: Vec2 = Vec2::new(1280.0, 800.0);
const VENTANA_MINIMA: Vec2 = Vec2::new(1024.0, 720.0);
const TITULO: &str = "Ganimedes POS — Punto de Venta";

fn main() -> eframe::Result<()> {
    let options = eframe::NativeOptions {
        viewport: eframe::egui::ViewportBuilder::default()
            .with_inner_size(VENTANA_INICIAL)
            .with_min_inner_size(VENTANA_MINIMA)
            .with_title(TITULO),
        ..Default::default()
    };

    eframe::run_native(TITULO, options, Box::new(|cc| Ok(Box::new(PosApp::new(cc)))))
}

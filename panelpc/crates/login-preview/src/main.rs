//! Vista previa aislada de la pantalla de acceso.
//!
//! Consume la biblioteca real (`ganimedes-pos`), así que lo que se ve aquí es
//! exactamente el mismo código que usa la aplicación: no hay copias que se
//! puedan quedar desactualizadas.
//!
//! Ejecutar desde la raíz del proyecto:
//!
//! ```bash
//! cargo run -p ganimedes-login-preview
//! ```
//!
//! O mediante el atajo: `bash crates/login-preview/run.sh`

use eframe::egui::{self, Vec2};
use ganimedes_pos::ui::screens::login::{LoginAction, LoginScreen};
use ganimedes_pos::ui::theme;

struct Preview {
    login: LoginScreen,
}

impl eframe::App for Preview {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default()
            .frame(egui::Frame::NONE)
            .show(ctx, |ui| {
                if self.login.ui(ui) == LoginAction::Submit {
                    // Sin backend conectado sólo se comprueba el flujo visual:
                    // se limpia el formulario para poder repetirlo.
                    self.login.reset();
                }
            });
    }
}

fn main() -> eframe::Result<()> {
    let titulo = "Ganimedes POS — vista previa del acceso";
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size(Vec2::new(1440.0, 900.0))
            .with_min_inner_size(Vec2::new(1100.0, 720.0))
            .with_title(titulo),
        ..Default::default()
    };

    eframe::run_native(
        titulo,
        options,
        Box::new(|cc| {
            theme::install(&cc.egui_ctx);
            Ok(Box::new(Preview {
                login: LoginScreen::new(),
            }))
        }),
    )
}

//! Raíz de la aplicación: decide qué pantalla se muestra y las orquesta.
//!
//! Flujo de navegación:
//!
//! ```text
//!                 LoginAction::Submit (credenciales válidas)
//!     ┌──────────────┐ ─────────────────────────────────► ┌───────────────┐
//!     │ LoginScreen  │                                    │  PosScreen    │
//!     │ (ui/screens) │ ◄───────────────────────────────── │ (ui/screens)  │
//!     └──────────────┘        "Cerrar sesión"            └───────────────┘
//! ```
//!
//! La validación de credenciales vive en [`PosApp::try_login`] y hoy es local.
//! Para conectar PocketBase basta con sustituir el cuerpo de ese método por una
//! llamada a [`crate::infra::backend::BackendClient`]; el resto del flujo no
//! cambia.

use eframe::egui;

use crate::core::user::{self, Usuario};
use crate::ui::screens::login::{LoginAction, LoginScreen};
use crate::ui::screens::pos::PosScreen;
use crate::ui::theme;

/// Usuario que se usa en modo kiosco (`GANIMEDES_AUTOLOGIN`).
const USUARIO_KIOSCO: &str = "admin";

/// Pantalla activa en este momento.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Screen {
    Login,
    Pos,
}

/// Estado raíz de la aplicación. Es lo que `eframe` ejecuta en cada fotograma.
pub struct PosApp {
    screen: Screen,
    login: LoginScreen,
    /// El POS se crea una sola vez y conserva su carrito entre inicios y
    /// cierres de sesión.
    pos: PosScreen,
    /// Usuario que inició sesión, para mostrarlo en la barra superior.
    sesion: Option<&'static Usuario>,
}

impl PosApp {
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        // Instala Inter + la paleta de DESIGN.md una sola vez para toda la app.
        theme::install(&cc.egui_ctx);

        let mut app = Self {
            screen: Screen::Login,
            login: LoginScreen::new(),
            pos: PosScreen::new(),
            sesion: None,
        };

        // Modo kiosco: en un terminal dedicado no tiene sentido pedir las
        // credenciales en cada arranque.
        if let Some(usuario) = usuario_de_kiosco() {
            app.entrar_como_kiosco(&usuario);
        }

        app
    }

    /// Entra sin pasar por el formulario, como el usuario indicado.
    ///
    /// Si el usuario no existe en el catálogo no se entra y queda la pantalla
    /// de acceso, que es el comportamiento seguro.
    fn entrar_como_kiosco(&mut self, usuario: &str) {
        let Some(u) = user::USUARIOS_DEMO
            .iter()
            .find(|u| u.activo && u.usuario.eq_ignore_ascii_case(usuario))
        else {
            return;
        };
        self.sesion = Some(u);
        self.enter_pos();
    }

    /// Valida las credenciales del formulario contra el catálogo de usuarios.
    ///
    /// Punto de integración con PocketBase: aquí es donde debe ir la llamada
    /// real a `BackendClient::auth_with_password`; el resto del flujo no cambia.
    fn try_login(&mut self) -> bool {
        match user::autenticar(&self.login.username, &self.login.password) {
            Some(u) => {
                self.sesion = Some(u);
                true
            }
            None => false,
        }
    }

    fn enter_pos(&mut self) {
        self.screen = Screen::Pos;
        self.login.reset();
    }

    fn logout(&mut self) {
        self.screen = Screen::Login;
        self.sesion = None;
        self.login.reset();
    }
}

/// Usuario de kiosco pedido por `GANIMEDES_AUTOLOGIN`.
///
/// - Sin la variable, o con `0`/`false`/`no`/vacío: no hay autologin.
/// - Con `1`/`true`/`yes`: entra como [`USUARIO_KIOSCO`].
/// - Con cualquier otro valor: se interpreta como el nombre del usuario con el
///   que entrar (por ejemplo `GANIMEDES_AUTOLOGIN=cajero`).
fn usuario_de_kiosco() -> Option<String> {
    interpretar_autologin(std::env::var("GANIMEDES_AUTOLOGIN").ok().as_deref())
}

/// Parte pura de [`usuario_de_kiosco`], para poder probarla sin entorno.
fn interpretar_autologin(valor: Option<&str>) -> Option<String> {
    let valor = valor?.trim();

    match valor.to_ascii_lowercase().as_str() {
        "" | "0" | "false" | "no" => None,
        "1" | "true" | "yes" => Some(USUARIO_KIOSCO.to_string()),
        _ => Some(valor.to_string()),
    }
}

impl eframe::App for PosApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        match self.screen {
            Screen::Login => {
                egui::CentralPanel::default()
                    .frame(egui::Frame::NONE)
                    .show(ctx, |ui| {
                        if self.login.ui(ui) == LoginAction::Submit {
                            if self.try_login() {
                                self.enter_pos();
                            } else {
                                self.login.error = Some(
                                    "Usuario o contraseña incorrectos. Usa una de las cuentas de prueba."
                                        .to_string(),
                                );
                            }
                        }
                    });
            }
            Screen::Pos => {
                let sesion = self.sesion;
                if self.pos.ui(ctx, sesion) {
                    self.logout();
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Construye la app sin `CreationContext`, que requiere una ventana real.
    fn app_de_prueba() -> PosApp {
        PosApp {
            screen: Screen::Login,
            login: LoginScreen::new(),
            pos: PosScreen::new(),
            sesion: None,
        }
    }

    /// Simula rellenar el formulario y enviarlo.
    fn entrar(app: &mut PosApp, identificador: &str, password: &str) -> bool {
        app.login.username = identificador.to_string();
        app.login.password = password.to_string();

        if app.try_login() {
            app.enter_pos();
            true
        } else {
            false
        }
    }

    #[test]
    fn arranca_en_la_pantalla_de_acceso() {
        assert_eq!(app_de_prueba().screen, Screen::Login);
    }

    #[test]
    fn el_autologin_solo_se_activa_con_los_valores_esperados() {
        assert_eq!(interpretar_autologin(None), None);
        assert_eq!(interpretar_autologin(Some("")), None);
        assert_eq!(interpretar_autologin(Some("0")), None);
        assert_eq!(interpretar_autologin(Some("false")), None);
        assert_eq!(interpretar_autologin(Some("no")), None);

        for activo in ["1", "true", "yes", "TRUE", " 1 "] {
            assert_eq!(
                interpretar_autologin(Some(activo)).as_deref(),
                Some(USUARIO_KIOSCO),
                "«{activo}» debería activar el autologin"
            );
        }
    }

    #[test]
    fn el_autologin_admite_elegir_usuario() {
        assert_eq!(interpretar_autologin(Some("cajero")).as_deref(), Some("cajero"));
        assert_eq!(interpretar_autologin(Some(" barbero ")).as_deref(), Some("barbero"));
    }

    #[test]
    fn el_kiosco_entra_directamente_al_pos() {
        let mut app = app_de_prueba();
        app.entrar_como_kiosco("cajero");

        assert_eq!(app.screen, Screen::Pos);
        assert_eq!(app.sesion.map(|s| s.usuario), Some("cajero"));
    }

    #[test]
    fn el_kiosco_con_un_usuario_inexistente_deja_el_acceso() {
        let mut app = app_de_prueba();
        app.entrar_como_kiosco("no-existe");

        assert_eq!(app.screen, Screen::Login);
        assert!(app.sesion.is_none());
    }

    #[test]
    fn credenciales_correctas_abren_el_pos() {
        let mut app = app_de_prueba();
        assert!(entrar(&mut app, "admin", "admin"));

        assert_eq!(app.screen, Screen::Pos);
        // El formulario queda limpio para el siguiente inicio de sesión.
        assert!(app.login.username.is_empty());
    }

    #[test]
    fn todos_los_usuarios_de_prueba_pueden_entrar() {
        for u in user::USUARIOS_DEMO {
            let mut app = app_de_prueba();
            assert!(
                entrar(&mut app, u.usuario, u.password),
                "el usuario de prueba '{}' no pudo entrar",
                u.usuario
            );
            assert_eq!(app.sesion.map(|s| s.id), Some(u.id));
            assert_eq!(app.screen, Screen::Pos);
        }
    }

    #[test]
    fn se_puede_entrar_con_el_correo() {
        let mut app = app_de_prueba();
        assert!(entrar(&mut app, "cajero@ganimedes.pos", "cajero"));
        assert_eq!(app.sesion.map(|s| s.usuario), Some("cajero"));
    }

    #[test]
    fn la_sesion_conserva_el_rol_del_usuario() {
        let mut app = app_de_prueba();
        entrar(&mut app, "barbero", "barbero");

        let sesion = app.sesion.expect("debe haber sesión");
        assert_eq!(sesion.rol, user::Rol::Barbero);
        assert_eq!(sesion.silla, Some("S-03"));
    }

    #[test]
    fn credenciales_incorrectas_no_abren_el_pos() {
        let mut app = app_de_prueba();

        assert!(!entrar(&mut app, "admin", "incorrecta"));
        assert_eq!(app.screen, Screen::Login);
        assert!(app.sesion.is_none());
    }

    #[test]
    fn cerrar_sesion_vuelve_al_acceso_y_olvida_la_sesion() {
        let mut app = app_de_prueba();
        entrar(&mut app, "admin", "admin");

        app.logout();
        assert_eq!(app.screen, Screen::Login);
        assert!(app.sesion.is_none());
    }

    #[test]
    fn se_puede_cambiar_de_usuario_sin_reiniciar() {
        let mut app = app_de_prueba();
        entrar(&mut app, "admin", "admin");
        app.logout();
        entrar(&mut app, "cajero", "cajero");

        assert_eq!(app.sesion.map(|s| s.usuario), Some("cajero"));
        assert_eq!(app.screen, Screen::Pos);
    }
}

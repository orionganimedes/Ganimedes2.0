mod login;
mod home;

use eframe::egui;
use login::LoginScreen;
use home::HomeScreen;

struct AppState {
    logged_in: bool,
    username: String,
    login_screen: LoginScreen,
    home_screen: HomeScreen,
}

impl AppState {
    fn new(_cc: &eframe::CreationContext<'_>) -> Self {
        Self {
            logged_in: false,
            username: String::new(),
            login_screen: LoginScreen::default(),
            home_screen: HomeScreen::default(),
        }
    }
}

impl eframe::App for AppState {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        if !self.logged_in {
            self.login_screen.ui(ctx);
            
            if self.login_screen.is_logged_in() {
                self.logged_in = true;
                self.username = self.login_screen.get_username().to_string();
                self.login_screen.reset();
            }
        } else {
            self.home_screen.ui(ctx, &self.username);
        }
    }
}

fn main() -> eframe::Result {
    let native_options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_title("Panel - Punto de Venta")
            .with_inner_size([800.0, 600.0]),
        ..Default::default()
    };
    
    eframe::run_native(
        "Panel - Punto de Venta",
        native_options,
        Box::new(|cc| Ok(Box::new(AppState::new(cc)))),
    )
}

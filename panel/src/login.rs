use eframe::egui;

#[derive(Default)]
pub struct LoginScreen {
    username: String,
    password: String,
    error_message: String,
    is_logging_in: bool,
    logged_in: bool,
}

impl LoginScreen {
    pub fn ui(&mut self, ctx: &egui::Context) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.vertical_centered(|ui| {
                ui.heading("Panel - Punto de Venta");
                ui.add_space(20.0);
                
                ui.horizontal(|ui| {
                    ui.label("Usuario: ");
                    ui.text_edit_singleline(&mut self.username);
                });
                
                ui.add_space(10.0);
                
                ui.horizontal(|ui| {
                    ui.label("Contraseña: ");
                    ui.text_edit_singleline(&mut self.password);
                });
                
                ui.add_space(20.0);
                
                if self.error_message.is_empty() {
                    ui.label("");
                } else {
                    ui.label(egui::RichText::new(&self.error_message).color(egui::Color32::RED));
                }
                
                ui.add_space(10.0);
                
                if ui.button("Iniciar Sesión").clicked() {
                    self.login();
                }
                
                ui.add_space(10.0);
                ui.label("Sistema de Punto de Venta v1.0");
            });
        });
    }
    
    fn login(&mut self) {
        if self.username.is_empty() || self.password.is_empty() {
            self.error_message = "Por favor, complete todos los campos".to_string();
            return;
        }
        
        self.is_logging_in = true;
        
        // Simulación de autenticación
        // Aquí podrías agregar la lógica real de autenticación
        if self.username == "admin" && self.password == "1234" {
            self.logged_in = true;
            self.error_message = String::new();
        } else {
            self.error_message = "Usuario o contraseña incorrectos".to_string();
            self.password.clear();
        }
        
        self.is_logging_in = false;
    }
    
    pub fn is_logged_in(&self) -> bool {
        self.logged_in
    }
    
    pub fn get_username(&self) -> &str {
        &self.username
    }
    
    pub fn reset(&mut self) {
        self.username.clear();
        self.password.clear();
        self.error_message.clear();
        self.logged_in = false;
    }
}

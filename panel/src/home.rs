use eframe::egui;

#[derive(Default, Clone)]
pub struct Product {
    pub id: u32,
    pub name: String,
    pub price: f32,
    pub category: String,
}

#[derive(Default)]
pub struct HomeScreen {
    selected_category: usize,
    search_text: String,
    cart: Vec<(Product, u32)>, // (product, quantity)
}

impl HomeScreen {
    pub fn ui(&mut self, ctx: &egui::Context, username: &str) {
        // Top bar
        egui::TopBottomPanel::top(egui::Id::new("top_bar")).show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.heading("Panel - Punto de Venta");
                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                    ui.label(egui::RichText::new(format!("Usuario: {}", username)).color(egui::Color32::GRAY));
                    if ui.button("Cerrar Sesión").clicked() {
                        // Aquí se podría implementar el logout
                    }
                });
            });
        });
        
        // Search and categories panel
        egui::TopBottomPanel::top(egui::Id::new("search_categories"))
            .resizable(false)
            .min_height(80.0)
            .max_height(80.0)
            .show(ctx, |ui| {
                ui.horizontal(|ui| {
                    // Search bar
                    ui.horizontal(|ui| {
                        ui.label("🔍 ");
                        ui.text_edit_singleline(&mut self.search_text)
                            .hint_text("Buscar producto...");
                    });
                    
                    ui.spacing_mut().item_spacing.x = 15.0;
                    
                    // Categories buttons
                    ui.vertical(|ui| {
                        ui.label("Categorías:");
                        ui.horizontal(|ui| {
                            let categories = ["Todos", "Electrónica", "Ropa", "Alimentos", "Hogar", "Juguetes"];
                            for (i, cat) in categories.iter().enumerate() {
                                let is_selected = self.selected_category == i;
                                let mut button = ui.button(*cat);
                                
                                if is_selected {
                                    button = button.fill(egui::Color32::LIGHT_BLUE);
                                }
                                
                                if button.clicked() {
                                    self.selected_category = i;
                                }
                            }
                        });
                    });
                });
            });
        
        // Products and cart side by side
        egui::TopBottomPanel::top(egui::Id::new("products_cart"))
            .resizable(true)
            .min_height(300.0)
            .show(ctx, |ui| {
                ui.horizontal(|ui| {
                    // Products list
                    egui::Frame::none()
                        .show(ui, |ui| {
                            ui.heading("📦 Productos");
                            ui.separator();
                            
                            // Scrollable area for products
                            egui::ScrollArea::vertical()
                                .max_height(400.0)
                                .show(ui, |ui| {
                                    let products = self.get_products();
                                    
                                    for product in products {
                                        if self.matches_search(&product) && self.matches_category(&product) {
                                            ui.horizontal(|ui| {
                                                // Product image placeholder
                                                ui.add(
                                                    egui::Image::new(
                                                        egui::include_image!("../assets/icon_placeholder.png")
                                                    ).frame(egui::Frame::none().rounding(5.0)).size(egui::Vec2::new(60.0, 60.0))
                                                );
                                                
                                                ui.vertical(|ui| {
                                                    ui.label(egui::RichText::new(&product.name).size(14.0).strong());
                                                    ui.label(format!("${:.2}", product.price));
                                                    ui.label(product.category.clone());
                                                });
                                                
                                                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                                                    if ui.button("+").clicked() {
                                                        self.add_to_cart(product.clone(), 1);
                                                    }
                                                });
                                            });
                                            
                                            ui.separator();
                                        }
                                    }
                                });
                        });
                    
                    ui.spacing_mut().item_spacing.x = 10.0;
                    
                    // Cart
                    egui::Frame::none()
                        .show(ui, |ui| {
                            ui.heading("🛒 Carrito");
                            ui.separator();
                            
                            // Cart items
                            egui::ScrollArea::vertical()
                                .max_height(350.0)
                                .show(ui, |ui| {
                                    if self.cart.is_empty() {
                                        ui.label("El carrito está vacío");
                                    } else {
                                        for (i, (product, quantity)) in self.cart.iter().enumerate() {
                                            ui.horizontal(|ui| {
                                                ui.label(&product.name);
                                                ui.label(format!("x{}", quantity));
                                                ui.label(format!("${:.2}", product.price * *quantity as f32));
                                                
                                                if ui.button("❌").clicked() {
                                                    self.cart.remove(i);
                                                }
                                            });
                                        }
                                    }
                                });
                            
                            ui.separator();
                            
                            // Total calculation
                            let total: f32 = self.cart.iter()
                                .map(|(p, q)| p.price * *q as f32)
                                .sum();
                            
                            ui.horizontal(|ui| {
                                ui.label("Total:");
                                ui.label(egui::RichText::new(format!("${:.2}", total)).size(24.0).color(egui::Color32::GREEN));
                            });
                            
                            ui.add_space(10.0);
                            
                            // Payment buttons
                            if ui.button("💳 Procesar Pago").clicked() {
                                if !self.cart.is_empty() {
                                    // Aquí se implementaría el procesamiento del pago
                                    println!("Procesando pago de ${:.2}", total);
                                    self.cart.clear();
                                }
                            }
                            
                            if ui.button("🔄 Nuevo Pedido").clicked() {
                                self.cart.clear();
                            }
                        });
                });
            });
    }
    
    fn get_products(&self) -> Vec<Product> {
        vec![
            Product { id: 1, name: "Laptop Pro 15".to_string(), price: 1200.00, category: "Electrónica".to_string() },
            Product { id: 2, name: "Headphones Bluetooth".to_string(), price: 150.00, category: "Electrónica".to_string() },
            Product { id: 3, name: "Teclado Mecánico".to_string(), price: 80.00, category: "Electrónica".to_string() },
            Product { id: 4, name: "Mouse Inalámbrico".to_string(), price: 35.00, category: "Electrónica".to_string() },
            Product { id: 5, name: "Monitor 24\"".to_string(), price: 300.00, category: "Electrónica".to_string() },
            Product { id: 6, name: "Camara Web HD".to_string(), price: 60.00, category: "Electrónica".to_string() },
            Product { id: 7, name: "USB-C Hub".to_string(), price: 45.00, category: "Electrónica".to_string() },
            Product { id: 8, name: "Altavoces 2.1".to_string(), price: 70.00, category: "Electrónica".to_string() },
            Product { id: 9, name: "Smartphone 128GB".to_string(), price: 450.00, category: "Electrónica".to_string() },
            Product { id: 10, name: "Tablet 10\"".to_string(), price: 300.00, category: "Electrónica".to_string() },
            Product { id: 11, name: "Camiseta Básica".to_string(), price: 25.00, category: "Ropa".to_string() },
            Product { id: 12, name: "Jeans Clásicos".to_string(), price: 50.00, category: "Ropa".to_string() },
            Product { id: 13, name: "Jacket Invierno".to_string(), price: 85.00, category: "Ropa".to_string() },
            Product { id: 14, name: "Zapatillas Deportivas".to_string(), price: 75.00, category: "Ropa".to_string() },
            Product { id: 15, name: "Vestido Formal".to_string(), price: 65.00, category: "Ropa".to_string() },
            Product { id: 16, name: "Manzanas 1kg".to_string(), price: 3.50, category: "Alimentos".to_string() },
            Product { id: 17, name: "Pan Integral".to_string(), price: 2.50, category: "Alimentos".to_string() },
            Product { id: 18, name: "Leche 1L".to_string(), price: 1.80, category: "Alimentos".to_string() },
            Product { id: 19, name: "Huevos 12un".to_string(), price: 2.20, category: "Alimentos".to_string() },
            Product { id: 20, name: "Arroz 1kg".to_string(), price: 2.00, category: "Alimentos".to_string() },
            Product { id: 21, name: "Silla Ergonomica".to_string(), price: 150.00, category: "Hogar".to_string() },
            Product { id: 22, name: "Lámpara de Escritorio".to_string(), price: 35.00, category: "Hogar".to_string() },
            Product { id: 23, name: "Cojín Decorativo".to_string(), price: 15.00, category: "Hogar".to_string() },
            Product { id: 24, name: "Juego de Toallas".to_string(), price: 25.00, category: "Hogar".to_string() },
            Product { id: 25, name: "Juguetes Educativos".to_string(), price: 30.00, category: "Juguetes".to_string() },
            Product { id: 26, name: "Pelota Futbol".to_string(), price: 20.00, category: "Juguetes".to_string() },
            Product { id: 27, name: "Puzzle 500pc".to_string(), price: 12.00, category: "Juguetes".to_string() },
            Product { id: 28, name: "Peluche Gigante".to_string(), price: 25.00, category: "Juguetes".to_string() },
        ]
    }
    
    fn matches_search(&self, product: &Product) -> bool {
        if self.search_text.is_empty() {
            return true;
        }
        
        let search_lower = self.search_text.to_lowercase();
        product.name.to_lowercase().contains(&search_lower) ||
        product.category.to_lowercase().contains(&search_lower)
    }
    
    fn matches_category(&self, product: &Product) -> bool {
        if self.selected_category == 0 {
            return true;
        }
        
        let categories = ["Electrónica", "Ropa", "Alimentos", "Hogar", "Juguetes"];
        if let Some(&cat) = categories.get(self.selected_category - 1) {
            return product.category == cat;
        }
        
        true
    }
    
    fn add_to_cart(&mut self, product: Product, quantity: u32) {
        if let Some((_, qty)) = self.cart.iter_mut().find(|(p, _)| p.id == product.id) {
            *qty += quantity;
        } else {
            self.cart.push((product, quantity));
        }
    }
}

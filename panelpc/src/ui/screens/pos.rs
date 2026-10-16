use eframe::egui::{self, Align, Color32, CornerRadius, Layout, RichText, Stroke, Vec2};

use crate::core::models::{PaymentMethod, Product};
use crate::core::state::PosState;
use crate::core::user::Usuario;
use crate::ui::theme::{
    ERROR, MUTED, MUTED_DIM, ON_SURFACE, OUTLINE_VARIANT, PRIMARY_CONTAINER, PRIMARY_HOVER,
    SECONDARY, SUCCESS, SURFACE_CONTAINER_HIGH, SURFACE_CONTAINER_LOW,
};

// ========================================
// GEOMETRÍA Y RITMO (escala de 8 puntos de DESIGN.md)
// ========================================
const RADIUS_CARD: u8 = 12;
const RADIUS_CHIP: u8 = 255;
const RADIUS_CTRL: u8 = 8;

const SPACING_XSM: f32 = 4.0;
const SPACING_SM: f32 = 8.0;
const SPACING_MD: f32 = 16.0;
const SPACING_LG: f32 = 24.0;

/// Formatea un importe en euros.
///
/// Normaliza el `-0.00` que produce la aritmética de coma flotante cuando el
/// subtotal es cero, para que el ticket nunca muestre un importe negativo.
fn eur(importe: f64) -> String {
    let normalizado = if importe == 0.0 { 0.0 } else { importe };
    format!("{:.2} EUR", normalizado)
}

pub struct PosScreen {
    pub state: PosState,
}

impl Default for PosScreen {
    fn default() -> Self {
        Self::new()
    }
}

impl PosScreen {
    pub fn new() -> Self {
        Self {
            state: PosState::new(),
        }
    }

    /// Dibuja la pantalla completa del punto de venta.
    ///
    /// Devuelve `true` cuando el usuario pide cerrar sesión; el enrutado vive en
    /// [`crate::app::main_screen::PosApp`].
    pub fn ui(&mut self, ctx: &egui::Context, sesion: Option<&Usuario>) -> bool {
        let mut logout = false;

        // TOP NAVIGATION BAR
        egui::TopBottomPanel::top("top_bar").show(ctx, |ui| {
            ui.add_space(SPACING_SM);

            ui.horizontal(|ui| {
                ui.add_space(SPACING_LG);

                let status_frame = egui::Frame {
                    fill: SURFACE_CONTAINER_LOW,
                    corner_radius: CornerRadius::same(RADIUS_CTRL),
                    stroke: Stroke::NONE,
                    inner_margin: egui::Margin::symmetric(4, 4),
                    ..Default::default()
                };

                status_frame.show(ui, |ui| {
                    ui.horizontal(|ui| {
                        ui.label(RichText::new("*").size(10.0).color(SECONDARY));
                        ui.label(RichText::new("POS v2.0").size(11.0).color(ON_SURFACE).monospace().strong());
                        ui.label(" | ");
                        ui.label(RichText::new("RAM: 28MB").size(10.0).color(MUTED));
                        ui.label(" | ");
                        ui.label(RichText::new("SQLite: OK").size(10.0).color(SUCCESS));
                        if let Some(u) = sesion {
                            ui.label(" | ");
                            ui.label(
                                RichText::new(format!("{} · {}", u.nombre, u.rol.etiqueta()))
                                    .size(10.0)
                                    .color(SECONDARY),
                            );
                            if let Some(silla) = u.silla {
                                ui.label(" | ");
                                ui.label(
                                    RichText::new(format!("Silla {}", silla))
                                        .size(10.0)
                                        .color(MUTED),
                                );
                            }
                        }
                    });
                });

                ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                    let logout_btn = egui::Button::new(
                        RichText::new("Cerrar sesion").size(12.0).color(MUTED),
                    )
                    .fill(SURFACE_CONTAINER_LOW)
                    .corner_radius(CornerRadius::same(RADIUS_CTRL))
                    .min_size(Vec2::new(110.0, 28.0));

                    if ui.add(logout_btn).clicked() {
                        logout = true;
                    }

                    ui.add_space(SPACING_SM);

                    let clear_btn = egui::Button::new(
                        RichText::new("Clear").size(12.0).color(
                            if self.state.cart.is_empty() {
                                MUTED_DIM
                            } else {
                                ERROR
                            }
                        )
                    ).fill(SURFACE_CONTAINER_LOW)
                    .corner_radius(CornerRadius::same(RADIUS_CTRL))
                    .min_size(Vec2::new(80.0, 28.0));

                    if ui.add_enabled(!self.state.cart.is_empty(), clear_btn).clicked() {
                        self.state.clear_cart();
                    }
                });
            });

            ui.add_space(SPACING_XSM);
            ui.separator();
        });

        // Toast Message
        if let Some(msg) = self.state.get_active_toast().map(|s| s.to_string()) {
            egui::TopBottomPanel::top("toast_bar").show(ctx, |ui| {
                egui::Frame::NONE
                    .fill(SURFACE_CONTAINER_HIGH)
                    .corner_radius(CornerRadius::same(RADIUS_CTRL))
                    .inner_margin(egui::Margin::symmetric(16, 16))
                    .show(ui, |ui| {
                        ui.horizontal_centered(|ui| {
                            ui.label(RichText::new(format!("OK: {}", msg)).color(ON_SURFACE).strong().size(13.0));
                        });
                    });
            });
        }

        // BOTTOM SHORTCUTS
        egui::TopBottomPanel::bottom("quick_shortcuts").show(ctx, |ui| {
            ui.add_space(SPACING_SM);

            ui.horizontal(|ui| {
                ui.add_space(SPACING_MD);

                // F12 Pay Button
                let pay_btn = egui::Button::new(
                    RichText::new("F12 COBRAR").color(Color32::WHITE).strong().size(14.0)
                ).fill(
                    if self.state.cart.is_empty() {
                        MUTED_DIM
                    } else {
                        PRIMARY_CONTAINER
                    }
                ).corner_radius(CornerRadius::same(RADIUS_CARD))
                .min_size(Vec2::new(120.0, 48.0));

                if ui.add_enabled(!self.state.cart.is_empty(), pay_btn).clicked() {
                    self.state.show_checkout_dialog = true;
                }
            });

            ui.add_space(SPACING_XSM);
        });

        // RIGHT PANEL: CART
        egui::SidePanel::right("cart_panel")
            .min_width(360.0)
            .max_width(480.0)
            .resizable(false)
            .show(ctx, |ui| {
                ui.add_space(SPACING_MD);
                self.render_cart_panel(ui);
            });

        // CENTRAL PANEL: PRODUCTS
        egui::CentralPanel::default().show(ctx, |ui| {
            self.render_catalog_panel(ui);
        });

        // CHECKOUT MODAL
        if self.state.show_checkout_dialog {
            self.render_checkout_dialog(ctx);
        }

        logout
    }
}

impl PosScreen {
    fn render_catalog_panel(&mut self, ui: &mut egui::Ui) {
        ui.add_space(SPACING_MD);

        // SEARCH BAR
        let search_frame = egui::Frame {
            fill: SURFACE_CONTAINER_LOW,
            corner_radius: CornerRadius::same(RADIUS_CARD),
            stroke: Stroke::new(1.0_f32, OUTLINE_VARIANT),
            inner_margin: egui::Margin::symmetric(16, 16),
            ..Default::default()
        };

        search_frame.show(ui, |ui| {
            ui.horizontal(|ui| {
                ui.label(RichText::new("FIND").size(18.0).color(MUTED_DIM));

                let search_edit = egui::TextEdit::singleline(&mut self.state.search_query)
                    .hint_text("Buscar Productos")
                    .desired_width(ui.available_width() - 40.0)
                    .margin(egui::Margin::symmetric(8, 8));

                ui.add(search_edit);
            });
        });

        ui.add_space(SPACING_MD);

        // CATEGORY FILTERS
        ui.horizontal_wrapped(|ui| {
            ui.add_space(SPACING_MD);

            for (idx, cat) in self.state.categories.iter().enumerate() {
                let is_selected = idx == self.state.selected_category_index;
                let text = RichText::new(cat).size(13.0).color(
                    if is_selected { Color32::WHITE } else { MUTED }
                );

                let fill_color = if is_selected { PRIMARY_CONTAINER } else { SURFACE_CONTAINER_LOW };

                let btn = egui::Button::new(text)
                    .fill(fill_color)
                    .corner_radius(CornerRadius::same(RADIUS_CHIP))
                    .stroke(Stroke::NONE)
                    .min_size(Vec2::new(70.0, 32.0));

                if ui.add(btn).clicked() {
                    self.state.selected_category_index = idx;
                }
                ui.add_space(SPACING_XSM);
            }
        });

        ui.add_space(SPACING_MD);
        ui.separator();
        ui.add_space(SPACING_MD);

        // PRODUCTS GRID
        let filtered_products: Vec<Product> = self
            .state
            .get_filtered_products()
            .into_iter()
            .cloned()
            .collect();

        if filtered_products.is_empty() {
            ui.vertical_centered(|ui| {
                ui.add_space(100.0);
                ui.label(RichText::new("No products found").size(18.0).color(MUTED_DIM));
            });
        } else {
            egui::ScrollArea::vertical()
                .auto_shrink([false, false])
                .show(ui, |ui| {
                    for product in filtered_products {
                        self.render_product_card(ui, &product);
                    }
                });
        }
    }

    fn render_product_card(&mut self, ui: &mut egui::Ui, product: &Product) {
        let frame = egui::Frame {
            fill: SURFACE_CONTAINER_LOW,
            corner_radius: CornerRadius::same(RADIUS_CTRL),
            stroke: Stroke::new(1.0_f32, OUTLINE_VARIANT),
            inner_margin: egui::Margin::symmetric(12, 12),
            ..Default::default()
        };

        let response = frame.show(ui, |ui| {
            ui.horizontal(|ui| {
                let icon_frame = egui::Frame {
                    fill: PRIMARY_CONTAINER,
                    corner_radius: CornerRadius::same(RADIUS_CTRL),
                    inner_margin: egui::Margin::symmetric(10, 10),
                    ..Default::default()
                };

                icon_frame.show(ui, |ui| {
                    ui.label(RichText::new(&product.image).size(30.0).color(Color32::WHITE));
                });

                ui.add_space(SPACING_MD);

                ui.vertical(|ui| {
                    ui.label(RichText::new(&product.name).size(16.0).color(ON_SURFACE).strong());
                    ui.label(RichText::new(format!("{} - {}", product.category, eur(product.price)))
                        .color(MUTED).size(14.0));
                });

                ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                    let btn = egui::Button::new(
                        RichText::new("ADD").color(Color32::WHITE).strong().size(13.0),
                    )
                    .fill(SURFACE_CONTAINER_HIGH)
                    .corner_radius(CornerRadius::same(RADIUS_CTRL))
                    .min_size(Vec2::new(80.0, 36.0));

                    if ui.add(btn).clicked() {
                        self.state.add_to_cart(product);
                    }
                });
            });
        });

        if response.response.hovered() {
            ui.ctx().set_cursor_icon(egui::CursorIcon::PointingHand);
        }
    }

    fn render_cart_panel(&mut self, ui: &mut egui::Ui) {
        ui.add_space(SPACING_MD);

        ui.horizontal(|ui| {
            ui.label(RichText::new("Ventas").strong().size(16.0).color(ON_SURFACE));
            ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                ui.label(RichText::new(format!("{} items", self.state.total_items())).color(MUTED).size(12.0));
            });
        });

        ui.add_space(SPACING_XSM);
        ui.separator();
        ui.add_space(SPACING_MD);

        let mut inc_index = None;
        let mut dec_index = None;

        if self.state.cart.is_empty() {
            ui.vertical_centered(|ui| {
                ui.add_space(SPACING_LG);
                ui.label(RichText::new("Empty cart").color(MUTED_DIM).size(14.0));
            });
        } else {
            egui::ScrollArea::vertical()
                .id_salt("cart_scroll")
                .max_height(ui.available_height() - 280.0)
                .show(ui, |ui| {
                    for (index, item) in self.state.cart.iter().enumerate() {
                        let frame = egui::Frame {
                            fill: SURFACE_CONTAINER_LOW,
                            corner_radius: CornerRadius::same(RADIUS_CTRL),
                            stroke: Stroke::new(1.0_f32, OUTLINE_VARIANT),
                            inner_margin: egui::Margin::symmetric(8, 8),
                            ..Default::default()
                        };

                        frame.show(ui, |ui| {
                            ui.horizontal(|ui| {
                                ui.vertical(|ui| {
                                    ui.label(RichText::new(&item.product.name).strong().size(14.0).color(ON_SURFACE));
                                    let item_total = item.product.price * (item.quantity as f64);
                                    ui.label(RichText::new(eur(item_total)).color(MUTED).size(12.0));
                                    let commission = (item_total * 0.30).round() as i32;
                                    ui.label(RichText::new(format!("Comm: {} EUR", commission)).color(MUTED_DIM).size(10.0));
                                });

                                ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                                    if ui.button(RichText::new("+").size(12.0).color(ON_SURFACE)).clicked() {
                                        inc_index = Some(index);
                                    }

                                    ui.label(RichText::new(format!("{}", item.quantity)).strong().size(14.0).color(ON_SURFACE));

                                    if ui.button(RichText::new("-").size(12.0).color(MUTED)).clicked() {
                                        dec_index = Some(index);
                                    }
                                });
                            });
                        });
                        ui.add_space(SPACING_XSM);
                    }
                });
        }

        if let Some(idx) = inc_index {
            self.state.increment_cart_item(idx);
        }
        if let Some(idx) = dec_index {
            self.state.decrement_cart_item(idx);
        }

        // CART FOOTER
        ui.with_layout(Layout::bottom_up(Align::Min), |ui| {
            ui.add_space(SPACING_MD);

            let subtotal = self.state.calculate_subtotal();
            let discount_amount = self.state.calculate_discount_amount();
            let total = self.state.calculate_total();

            ui.horizontal(|ui| {
                ui.label(RichText::new("Subtotal").size(13.0).color(MUTED));
                ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                    ui.label(RichText::new(eur(subtotal)).color(ON_SURFACE).monospace());
                });
            });

            if self.state.discount > 0.0 {
                ui.horizontal(|ui| {
                    ui.label(RichText::new("Discount").size(13.0).color(MUTED));
                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                        ui.label(RichText::new(format!("-{}", eur(discount_amount))).color(ERROR).monospace());
                    });
                });
            }

            ui.add_space(SPACING_SM);
            let total_frame = egui::Frame {
                fill: PRIMARY_CONTAINER,
                inner_margin: egui::Margin::symmetric(16, 16),
                corner_radius: CornerRadius::same(RADIUS_CTRL),
                ..Default::default()
            };

            total_frame.show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.vertical(|ui| {
                        ui.label(RichText::new("Total").size(11.0).color(Color32::WHITE).strong());
                        let commission = (total * 0.30).round() as i32;
                        ui.label(RichText::new(format!("Gain: {} EUR", commission)).size(10.0).color(Color32::WHITE));
                    });
                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                        ui.label(RichText::new(eur(total)).color(Color32::WHITE).strong().size(24.0).monospace());
                    });
                });
            });

            ui.add_space(SPACING_MD);

            ui.horizontal(|ui| {
                ui.label(RichText::new("Discount (%):").size(12.0).color(MUTED));
                let discount_edit = egui::TextEdit::singleline(&mut self.state.discount_input)
                    .desired_width(70.0)
                    .hint_text("0");
                if ui.add(discount_edit).changed() {
                    self.state.set_discount_from_input();
                }
            });

            ui.add_space(SPACING_MD);
            ui.separator();
            ui.add_space(SPACING_MD);

            let is_cart_empty = self.state.cart.is_empty();
            let pay_btn = egui::Button::new(
                RichText::new("COBRAR").color(Color32::WHITE).strong().size(16.0),
            );

            let response = if is_cart_empty {
                ui.add_enabled(
                    false,
                    pay_btn
                        .fill(MUTED_DIM)
                        .corner_radius(CornerRadius::same(RADIUS_CARD))
                        .min_size(Vec2::new(ui.available_width(), 56.0)),
                )
            } else {
                let fill = if ui.rect_contains_pointer(ui.max_rect()) {
                    PRIMARY_HOVER
                } else {
                    PRIMARY_CONTAINER
                };
                ui.add(
                    pay_btn
                        .fill(fill)
                        .corner_radius(CornerRadius::same(RADIUS_CARD))
                        .min_size(Vec2::new(ui.available_width(), 56.0)),
                )
            };

            if response.clicked() {
                self.state.show_checkout_dialog = true;
            }
        });
    }

    fn render_checkout_dialog(&mut self, ctx: &egui::Context) {
        let mut close_dialog = false;
        let mut confirmed = false;

        let subtotal = self.state.calculate_subtotal();
        let discount_amount = self.state.calculate_discount_amount();
        let total = self.state.calculate_total();

        egui::Window::new("Confirm Payment")
            .collapsible(false)
            .resizable(false)
            .anchor(egui::Align2::CENTER_CENTER, Vec2::ZERO)
            .fixed_size(Vec2::new(420.0, 380.0))
            .show(ctx, |ui| {
                ui.add_space(SPACING_MD);
                ui.label(RichText::new("Ticket #884").color(MUTED).monospace().size(12.0));
                ui.add_space(SPACING_XSM);

                ui.horizontal(|ui| {
                    ui.label(RichText::new("Subtotal").size(14.0).color(MUTED));
                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                        ui.label(RichText::new(eur(subtotal)).color(ON_SURFACE).monospace());
                    });
                });

                if self.state.discount > 0.0 {
                    ui.horizontal(|ui| {
                        ui.label(RichText::new("Discount").size(14.0).color(MUTED));
                        ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                            ui.label(RichText::new(format!("-{}", eur(discount_amount))).color(ERROR).monospace());
                        });
                    });
                }

                ui.add_space(SPACING_XSM);
                ui.separator();
                ui.add_space(SPACING_XSM);

                ui.horizontal(|ui| {
                    ui.vertical(|ui| {
                        ui.label(RichText::new("Total").size(13.0).color(MUTED).strong());
                        let commission = (total * 0.30).round() as i32;
                        ui.label(RichText::new(format!("Gain: {} EUR", commission)).color(MUTED).size(11.0));
                    });
                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                        ui.label(RichText::new(eur(total)).color(ON_SURFACE).strong().size(32.0).monospace());
                    });
                });

                ui.add_space(SPACING_MD);
                ui.separator();
                ui.add_space(SPACING_MD);

                ui.label(RichText::new("Payment Method:").strong().size(14.0).color(ON_SURFACE));
                ui.add_space(SPACING_XSM);

                for method in PaymentMethod::ALL {
                    ui.radio_value(&mut self.state.selected_payment_method, method, method.as_str());
                }

                ui.add_space(SPACING_MD);
                ui.separator();
                ui.add_space(SPACING_MD);

                ui.horizontal(|ui| {
                    if ui.button(RichText::new("Cancel").size(13.0).color(MUTED)).clicked() {
                        close_dialog = true;
                    }

                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                        let confirm_btn = egui::Button::new(
                            RichText::new("Confirm").color(Color32::WHITE).strong().size(14.0),
                        )
                        .fill(SURFACE_CONTAINER_HIGH)
                        .corner_radius(CornerRadius::same(RADIUS_CTRL))
                        .min_size(Vec2::new(140.0, 40.0));

                        if ui.add(confirm_btn).clicked() {
                            confirmed = true;
                        }
                    });
                });
            });

        if confirmed {
            if self.state.complete_sale().is_ok() {
                let total = self.state.calculate_total();
                let method = self.state.selected_payment_method.as_str();
                self.state.show_toast(format!("Payment of {} via {}", eur(total), method));
            }
            self.state.show_checkout_dialog = false;
        } else if close_dialog {
            self.state.show_checkout_dialog = false;
        }
    }
}
//! Pantalla de acceso al ecosistema Ganimedes.
//!
//! Reproduce la maqueta `Iniciar Sesión`: tarjeta centrada de dos paneles, el
//! izquierdo de marca (degradado azul con vetas de luz) y el derecho con el
//! formulario. Toda la geometría se deriva del tamaño disponible y de un factor
//! de escala `k` calculado sobre los 1280 px de ancho de la maqueta, de modo que
//! el diseño se mantiene proporcionado en cualquier ventana.
//!
//! Este módulo sólo **dibuja y recoge datos**: devuelve [`LoginAction::Submit`]
//! y quien decide si las credenciales valen es
//! [`crate::app::main_screen::PosApp`], contrastándolas con
//! [`crate::core::user::USUARIOS_DEMO`]. Así la validación puede pasar a
//! PocketBase sin tocar la interfaz.

use eframe::egui::{
    self, Align, Color32, CornerRadius, CursorIcon, Layout, Margin, Pos2, Rect, Response, RichText,
    Sense, Stroke, StrokeKind, Ui, UiBuilder, Vec2,
};

use crate::core::user;
use crate::ui::widgets::icons;
use crate::ui::theme;
use crate::ui::theme::{
    regular, semibold, t_bold, t_regular, t_semibold, tracked, with_alpha, ERROR, FIELD_BG, MUTED,
    MUTED_DIM, ON_SURFACE, ON_SURFACE_VARIANT, OUTER_BG, OUTLINE, OUTLINE_VARIANT,
    PANEL_LEFT_BOTTOM, PANEL_LEFT_TOP, PANEL_RIGHT, PRIMARY_CONTAINER, PRIMARY_HOVER,
    PRIMARY_PRESSED, SECONDARY, SECONDARY_CONTAINER, SUCCESS,
};

/// Resultado de un fotograma de la pantalla de acceso.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LoginAction {
    /// El usuario sigue rellenando el formulario.
    None,
    /// Pulsó "Entrar al Sistema" o envió con Intro.
    Submit,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FieldIcon {
    Person,
    Lock,
}

/// Estado del formulario de acceso.
pub struct LoginScreen {
    pub username: String,
    pub password: String,
    /// Cuando es `false` la contraseña se muestra como puntos.
    pub show_password: bool,
    /// Motivo del último rechazo; vacío si no hay error que mostrar.
    pub error: Option<String>,
}

impl Default for LoginScreen {
    fn default() -> Self {
        Self::new()
    }
}

impl LoginScreen {
    pub fn new() -> Self {
        Self {
            username: String::new(),
            password: String::new(),
            show_password: false,
            error: None,
        }
    }

    /// Limpia el formulario y el error (al cerrar sesión, por ejemplo).
    pub fn reset(&mut self) {
        self.username.clear();
        self.password.clear();
        self.show_password = false;
        self.error = None;
    }

    pub fn ui(&mut self, ui: &mut Ui) -> LoginAction {
        let area = ui.max_rect();
        let painter = ui.painter().clone();
        painter.rect_filled(area, CornerRadius::ZERO, OUTER_BG);

        let card = card_rect(area);
        let scale = (card.width() / 1280.0).clamp(0.74, 1.18);

        let left_width = (card.width() * 0.42).round();
        let left = Rect::from_min_size(card.min, Vec2::new(left_width, card.height()));
        let right = Rect::from_min_max(
            Pos2::new(card.left() + left_width, card.top()),
            card.max,
        );

        self.paint_brand_panel(&painter, left, scale);
        painter.rect_filled(right, CornerRadius::ZERO, PANEL_RIGHT);

        // Esquinas redondeadas sobre rellenos que no admiten radio.
        theme::mask_corners(&painter, card, theme::CARD_RADIUS, OUTER_BG);
        painter.rect_stroke(
            card,
            CornerRadius::same(theme::CARD_RADIUS as u8),
            Stroke::new(1.0_f32, with_alpha(OUTLINE_VARIANT, 140)),
            StrokeKind::Inside,
        );

        self.left_pane(ui, left, scale);
        if self.right_pane(ui, right, scale) {
            LoginAction::Submit
        } else {
            LoginAction::None
        }
    }

    /// Degradado base y vetas diagonales del panel de marca.
    fn paint_brand_panel(&self, painter: &egui::Painter, pane: Rect, _scale: f32) {
        let clipped = painter.with_clip_rect(pane);

        theme::gradient_rect(&clipped, pane, PANEL_LEFT_TOP, PANEL_LEFT_BOTTOM, false);

        // Vetas de luz. Los colores se pre-mezclan (opacos) en vez de usar alfa
        // muy baja, que en egui se ve mucho más intensa de lo esperado.
        let base = theme::mix(PANEL_LEFT_TOP, PANEL_LEFT_BOTTOM, 0.42);
        let luz = |t: f32| theme::mix(base, Color32::WHITE, t);
        let cian = |t: f32| theme::mix(base, SECONDARY, t);

        theme::diagonal_band(&clipped, pane, 0.02, 0.26, 0.20, luz(0.09));
        theme::diagonal_band(&clipped, pane, 0.09, 0.32, 0.045, cian(0.32));
        theme::diagonal_band(&clipped, pane, 0.24, 0.58, 0.13, luz(0.045));
        theme::diagonal_band(&clipped, pane, 0.54, 0.84, 0.028, cian(0.20));
        theme::diagonal_band(&clipped, pane, 0.74, 1.06, 0.16, luz(0.035));
    }

    fn left_pane(&mut self, ui: &mut Ui, pane: Rect, scale: f32) {
        ui.spacing_mut().item_spacing = Vec2::ZERO;

        let pad_x = (pane.width() * 0.085).clamp(26.0, 54.0);
        let inner = Rect::from_min_max(
            Pos2::new(pane.left() + pad_x, pane.top()),
            Pos2::new(pane.right() - pad_x, pane.bottom()),
        );
        let content_w = inner.width();

        // ---- Cabecera: insignia + nombre del producto
        let header = Rect::from_min_size(
            Pos2::new(inner.left(), pane.top() + pane.height() * 0.070),
            Vec2::new(content_w, 54.0 * scale),
        );
        ui.scope_builder(UiBuilder::new().max_rect(header), |ui| {
            ui.spacing_mut().item_spacing = Vec2::ZERO;
            ui.horizontal(|ui| {
                let (badge_rect, _) =
                    ui.allocate_exact_size(Vec2::splat(52.0 * scale), Sense::hover());
                icons::badge(
                    ui.painter(),
                    badge_rect,
                    with_alpha(Color32::BLACK, 90),
                    with_alpha(Color32::WHITE, 22),
                    14.0 * scale,
                );
                icons::terminal(ui.painter(), badge_rect.shrink(13.0 * scale), ON_SURFACE);

                ui.add_space(14.0 * scale);

                ui.vertical(|ui| {
                    ui.spacing_mut().item_spacing = Vec2::ZERO;
                    ui.add_space(5.0 * scale);
                    ui.label(t_semibold(
                        tracked("ECOSISTEMA RETAIL"),
                        11.0 * scale,
                        ON_SURFACE_VARIANT,
                    ));
                    ui.add_space(2.0 * scale);
                    ui.label(t_regular("Terminal POS • v4.8", 13.0 * scale, ON_SURFACE));
                });
            });
        });

        // ---- Bloque central: píldora, título, descripción y estado
        let mid_y = pane.top() + pane.height() * 0.345;

        let pill_rect =
            Rect::from_min_size(Pos2::new(inner.left(), mid_y), Vec2::new(content_w, 34.0 * scale));
        ui.scope_builder(UiBuilder::new().max_rect(pill_rect), |ui| {
            ui.spacing_mut().item_spacing = Vec2::ZERO;
            ui.with_layout(Layout::left_to_right(Align::Center), |ui| {
                egui::Frame::NONE
                    .fill(with_alpha(Color32::BLACK, 70))
                    .stroke(Stroke::new(1.0_f32, with_alpha(SECONDARY, 150)))
                    .corner_radius(CornerRadius::same(255))
                    .inner_margin(Margin::symmetric(13, 7))
                    .show(ui, |ui| {
                        ui.spacing_mut().item_spacing = Vec2::ZERO;
                        ui.horizontal(|ui| {
                            let (dot_rect, _) =
                                ui.allocate_exact_size(Vec2::splat(9.0 * scale), Sense::hover());
                            icons::dot(
                                ui.painter(),
                                dot_rect.center(),
                                4.0 * scale,
                                SECONDARY,
                            );
                            ui.add_space(6.0 * scale);
                            ui.label(t_semibold(
                                "Ecosistema de Ventas",
                                12.0 * scale,
                                SECONDARY,
                            ));
                        });
                    });
            });
        });

        let title_rect = Rect::from_min_size(
            Pos2::new(inner.left(), mid_y + 76.0 * scale),
            Vec2::new(content_w, 62.0 * scale),
        );
        ui.scope_builder(UiBuilder::new().max_rect(title_rect), |ui| {
            ui.spacing_mut().item_spacing = Vec2::ZERO;
            ui.label(t_bold("GANIMEDES", 46.0 * scale, Color32::WHITE));
        });

        let desc_rect = Rect::from_min_size(
            Pos2::new(inner.left(), mid_y + 150.0 * scale),
            Vec2::new(content_w * 0.88, 86.0 * scale),
        );
        ui.scope_builder(UiBuilder::new().max_rect(desc_rect), |ui| {
            ui.spacing_mut().item_spacing = Vec2::ZERO;
            ui.label(t_regular(
                "Terminal de facturación y control en tiempo real. Gestión \
                 unificada de caja, inventarios y operaciones comerciales.",
                14.5 * scale,
                ON_SURFACE_VARIANT,
            ));
        });

        let chips_y = mid_y + 252.0 * scale;
        let chip_w = (content_w - 10.0 * scale) * 0.5;
        let chips = [
            ("Servidor", "Activo", SUCCESS),
            ("Sincronización", "Cloud", SECONDARY),
        ];
        for (index, (label, value, color)) in chips.into_iter().enumerate() {
            let chip_rect = Rect::from_min_size(
                Pos2::new(inner.left() + index as f32 * (chip_w + 10.0 * scale), chips_y),
                Vec2::new(chip_w, 46.0 * scale),
            );
            ui.scope_builder(UiBuilder::new().max_rect(chip_rect), |ui| {
                ui.spacing_mut().item_spacing = Vec2::ZERO;
                egui::Frame::NONE
                    .fill(with_alpha(Color32::BLACK, 80))
                    .corner_radius(CornerRadius::same(theme::TAB_RADIUS))
                    .inner_margin(Margin::symmetric(12, 9))
                    .show(ui, |ui| {
                        ui.spacing_mut().item_spacing = Vec2::ZERO;
                        // Ancho fijo e igual para las dos fichas, como en la maqueta.
                        ui.set_min_width(chip_w - 24.0 * scale);
                        ui.horizontal(|ui| {
                            let (dot_rect, _) =
                                ui.allocate_exact_size(Vec2::splat(10.0 * scale), Sense::hover());
                            icons::dot(ui.painter(), dot_rect.center(), 4.0 * scale, color);
                            ui.add_space(8.0 * scale);
                            ui.vertical(|ui| {
                                ui.spacing_mut().item_spacing = Vec2::ZERO;
                                ui.label(t_regular(label, 10.5 * scale, MUTED));
                                ui.label(t_semibold(value, 12.0 * scale, Color32::WHITE));
                            });
                        });
                    });
            });
        }

        // ---- Pie: separador, identificador y copyright
        let foot_y = pane.bottom() - 62.0 * scale;
        ui.painter().line_segment(
            [
                Pos2::new(inner.left(), foot_y),
                Pos2::new(inner.right(), foot_y),
            ],
            Stroke::new(1.0_f32, with_alpha(Color32::WHITE, 26)),
        );

        let foot_rect = Rect::from_min_size(
            Pos2::new(inner.left(), foot_y + 16.0 * scale),
            Vec2::new(content_w, 22.0 * scale),
        );
        ui.scope_builder(UiBuilder::new().max_rect(foot_rect), |ui| {
            ui.spacing_mut().item_spacing = Vec2::ZERO;
            ui.horizontal(|ui| {
                ui.label(t_regular("ID: POS-CENTRAL-01", 11.0 * scale, MUTED_DIM));
                ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                    ui.label(t_regular("© 2025 Ganimedes Tech", 11.0 * scale, MUTED_DIM));
                });
            });
        });
    }

    /// Devuelve `true` si el usuario pidió entrar.
    fn right_pane(&mut self, ui: &mut Ui, pane: Rect, scale: f32) -> bool {
        let content_w = (pane.width() * 0.76)
            .min(560.0 * scale)
            .max(300.0)
            .min(pane.width() - 32.0);
        let content_h = 470.0 * scale;
        let top = pane.top() + ((pane.height() - content_h) * 0.5).max(pane.height() * 0.10);
        let left = pane.left() + ((pane.width() - content_w) * 0.5).max(16.0);

        let rect = Rect::from_min_size(Pos2::new(left, top), Vec2::new(content_w, content_h));

        let mut submit = false;
        let mut enter_pressed = false;

        ui.scope_builder(
            UiBuilder::new()
                .max_rect(rect)
                .layout(Layout::top_down(Align::Min)),
            |ui| {
                ui.spacing_mut().item_spacing = Vec2::ZERO;

                ui.label(t_bold("Iniciar Sesión", 33.0 * scale, Color32::WHITE));
                ui.add_space(8.0 * scale);
                ui.label(t_regular(
                    "Ganimedes • Ecosistema de Ventas",
                    13.5 * scale,
                    MUTED,
                ));
                ui.add_space(34.0 * scale);

                // ---- Usuario o correo
                ui.label(t_semibold(
                    tracked("USUARIO O CORREO"),
                    10.5 * scale,
                    ON_SURFACE_VARIANT,
                ));
                ui.add_space(9.0 * scale);
                let user_response = text_field(
                    ui,
                    scale,
                    FieldIcon::Person,
                    "login-user",
                    &mut self.username,
                    "ej. admin@ganimedes.pos",
                    None,
                );

                ui.add_space(22.0 * scale);

                // ---- Contraseña o PIN
                ui.label(t_semibold(
                    tracked("CONTRASEÑA O PIN"),
                    10.5 * scale,
                    ON_SURFACE_VARIANT,
                ));
                ui.add_space(9.0 * scale);
                let pass_response = text_field(
                    ui,
                    scale,
                    FieldIcon::Lock,
                    "login-pass",
                    &mut self.password,
                    "Introduce tu contraseña o PIN",
                    Some(&mut self.show_password),
                );

                // ---- Error (vacío mientras no haya validación)
                if let Some(message) = self.error.clone() {
                    ui.add_space(12.0 * scale);
                    ui.label(t_regular(message, 12.0 * scale, ERROR));
                }

                // ---- Cuentas de prueba (pulsables: rellenan el formulario)
                // Van justo antes del botón para que el gesto sea natural:
                // pulsar una cuenta y luego confirmar.
                if let Some((usuario, clave)) = credenciales_de_prueba(ui, scale) {
                    self.username = usuario.to_string();
                    self.password = clave.to_string();
                    self.error = None;
                }

                ui.add_space(30.0 * scale);

                // ---- Botón principal
                let button_h = 54.0 * scale;
                let (button_rect, button_response) = ui.allocate_exact_size(
                    Vec2::new(ui.available_width(), button_h),
                    Sense::click(),
                );
                if button_response.hovered() {
                    ui.ctx().set_cursor_icon(CursorIcon::PointingHand);
                }
                paint_primary_button(ui, button_rect, button_response.hovered() || button_response.has_focus(), button_response.is_pointer_button_down_on(), scale);
                if button_response.clicked() {
                    submit = true;
                }

                ui.add_space(22.0 * scale);

                // ---- Separador y pie del formulario
                let (separator, _) = ui.allocate_exact_size(
                    Vec2::new(ui.available_width(), 1.0),
                    Sense::hover(),
                );
                ui.painter().rect_filled(
                    separator,
                    CornerRadius::ZERO,
                    with_alpha(OUTLINE_VARIANT, 160),
                );
                ui.add_space(18.0 * scale);

                ui.horizontal(|ui| {
                    let (dot_rect, _) =
                        ui.allocate_exact_size(Vec2::splat(9.0 * scale), Sense::hover());
                    icons::dot(ui.painter(), dot_rect.center(), 4.0 * scale, SUCCESS);
                    ui.add_space(6.0 * scale);
                    ui.label(t_regular("Modo Caja Habilitado", 12.0 * scale, MUTED));

                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                        let link = ui.add(
                            egui::Label::new(t_regular("Soporte Técnico", 12.0 * scale, MUTED))
                                .sense(Sense::click()),
                        );
                        if link.hovered() {
                            ui.ctx().set_cursor_icon(CursorIcon::PointingHand);
                        }
                    });
                });

                // ---- Envío con Intro
                enter_pressed = ui.input(|i| i.key_pressed(egui::Key::Enter));
                if enter_pressed
                    && (user_response.lost_focus() || pass_response.lost_focus())
                {
                    submit = true;
                }
            },
        );

        submit
    }
}

/// Cuentas de prueba disponibles, en una fila pulsable.
///
/// Al pulsar una, devuelve `(usuario, contraseña)` para que el formulario se
/// rellene solo. Es una ayuda de desarrollo: cuando el acceso se conecte a
/// PocketBase habrá que eliminar esta función y su llamada.
fn credenciales_de_prueba(ui: &mut Ui, scale: f32) -> Option<(&'static str, &'static str)> {
    let cuentas = user::credenciales_visibles();
    if cuentas.is_empty() {
        return None;
    }

    let mut elegida = None;

    egui::Frame::NONE
        .fill(FIELD_BG)
        .corner_radius(CornerRadius::same((8.0 * scale) as u8))
        .inner_margin(Margin::symmetric((10.0 * scale) as i8, (8.0 * scale) as i8))
        .show(ui, |ui| {
            ui.horizontal_wrapped(|ui| {
                ui.spacing_mut().item_spacing = Vec2::new(6.0 * scale, 4.0 * scale);
                ui.label(t_semibold(
                    tracked("PRUEBA"),
                    9.5 * scale,
                    ON_SURFACE_VARIANT,
                ));

                for (usuario, clave, rol) in cuentas {
                    let texto = format!("{} · {}", usuario, rol);
                    let respuesta = ui.add(
                        egui::Label::new(RichText::new(texto).size(11.0 * scale).color(SECONDARY))
                            .sense(Sense::click()),
                    );

                    if respuesta.hovered() {
                        ui.ctx().set_cursor_icon(CursorIcon::PointingHand);
                        respuesta.clone().on_hover_text(format!(
                            "Rellena el formulario con {} / {}",
                            usuario, clave
                        ));
                    }
                    if respuesta.clicked() {
                        elegida = Some((usuario, clave));
                    }
                }
            });
        });

    elegida
}

/// Campo de texto con icono, borde de foco y, opcionalmente, ojo de
/// mostrar/ocultar contraseña.
fn text_field(
    ui: &mut Ui,
    scale: f32,
    icon: FieldIcon,
    id_salt: &str,
    buffer: &mut String,
    hint: &str,
    reveal: Option<&mut bool>,
) -> Response {
    let height = 50.0 * scale;
    let width = ui.available_width();
    let (rect, _) = ui.allocate_exact_size(Vec2::new(width, height), Sense::hover());

    let id = ui.id().with(id_salt);
    let focused = ui.ctx().memory(|m| m.has_focus(id));
    let visible = reveal.as_ref().map(|v| **v).unwrap_or(false);

    let painter = ui.painter().clone();
    theme::paint_field(&painter, rect, focused, scale);

    // Icono guía
    let icon_center = Pos2::new(rect.left() + 23.0 * scale, rect.center().y);
    let icon_rect = Rect::from_center_size(icon_center, Vec2::splat(19.0 * scale));
    let icon_color = if focused { SECONDARY } else { OUTLINE };
    match icon {
        FieldIcon::Person => icons::person(&painter, icon_rect, icon_color),
        FieldIcon::Lock => icons::lock(&painter, icon_rect, icon_color),
    }

    // Área editable: deja sitio al icono y, si procede, al ojo.
    let mut inner = rect;
    inner.min.x += 46.0 * scale;
    inner.max.x -= if reveal.is_some() { 46.0 * scale } else { 16.0 * scale };

    let masked = reveal.is_some() && !visible;
    let edit = egui::TextEdit::singleline(buffer)
        .id(id)
        .frame(false)
        .password(masked)
        .hint_text(hint)
        .font(regular(14.0 * scale))
        .text_color(ON_SURFACE)
        .margin(Margin::symmetric(0, (14.5 * scale) as i8))
        .desired_width(f32::INFINITY);

    let mut response = ui.put(inner, edit);

    // Placeholder: el color por defecto del hint es demasiado tenue.
    if buffer.is_empty() && !focused {
        response.mark_changed();
    }

    // Ojo de mostrar/ocultar
    if let Some(visible) = reveal {
        let eye_rect = Rect::from_center_size(
            Pos2::new(rect.right() - 23.0 * scale, rect.center().y),
            Vec2::splat(30.0 * scale),
        );
        let eye_response = ui.interact(eye_rect, id.with("eye"), Sense::click());
        if eye_response.hovered() {
            ui.ctx().set_cursor_icon(CursorIcon::PointingHand);
        }
        let color = if eye_response.hovered() { ON_SURFACE } else { MUTED };
        icons::eye(
            ui.painter(),
            eye_rect.shrink(9.0 * scale),
            color,
            *visible,
        );
        if eye_response.clicked() {
            *visible = !*visible;
        }
    }

    response
}

/// Botón principal: degradado azul → cian, texto centrado y flecha.
fn paint_primary_button(ui: &Ui, rect: Rect, hovered: bool, pressed: bool, scale: f32) {
    let painter = ui.painter();
    let radius = CornerRadius::same((13.0 * scale) as u8);

    // Resplandor cian alrededor (egui no tiene desenfoque: se simula con capas).
    painter.rect_filled(
        rect.expand(7.0 * scale),
        CornerRadius::same((18.0 * scale) as u8),
        with_alpha(PRIMARY_CONTAINER, if hovered { 60 } else { 34 }),
    );

    let (from, to) = if pressed {
        (PRIMARY_PRESSED, PRIMARY_PRESSED)
    } else if hovered {
        (PRIMARY_HOVER, SECONDARY_CONTAINER)
    } else {
        (PRIMARY_CONTAINER, SECONDARY_CONTAINER)
    };
    theme::gradient_rect(painter, rect, from, to, true);

    painter.rect_stroke(
        rect,
        radius,
        Stroke::new(1.0_f32, with_alpha(Color32::WHITE, 26)),
        StrokeKind::Inside,
    );

    // Contenido centrado: texto + flecha.
    let font = semibold(15.5 * scale);
    let galley = painter.layout_no_wrap("Entrar al Sistema".to_owned(), font, Color32::WHITE);
    let text_size = galley.size();
    let arrow = 20.0 * scale;
    let gap = 10.0 * scale;
    let total = text_size.x + gap + arrow;
    let start_x = rect.center().x - total * 0.5;

    painter.galley(
        Pos2::new(start_x, rect.center().y - text_size.y * 0.5),
        galley,
        Color32::WHITE,
    );
    icons::arrow_right(
        painter,
        Rect::from_center_size(
            Pos2::new(start_x + total - arrow * 0.5, rect.center().y),
            Vec2::splat(arrow),
        ),
        Color32::WHITE,
    );
}

/// Tarjeta centrada: 80% del ancho y 90% del alto, con topes de la maqueta.
fn card_rect(area: Rect) -> Rect {
    let width = (area.width() * 0.80)
        .clamp(880.0, 1400.0)
        .min(area.width() - 24.0);
    let height = (area.height() * 0.90)
        .clamp(600.0, 860.0)
        .min(area.height() - 24.0);
    Rect::from_center_size(area.center(), Vec2::new(width, height))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn area(w: f32, h: f32) -> Rect {
        Rect::from_min_size(Pos2::ZERO, Vec2::new(w, h))
    }

    /// Alto aproximado que ocupa el formulario del panel derecho, en píxeles
    /// sin escalar.
    ///
    /// Suma los huecos fijos de `right_pane` y estima la altura de las líneas de
    /// texto. Es una **estimación deliberadamente conservadora y explícita**: si
    /// se añade un bloque al formulario, hay que subir esta cifra, y el test
    /// [`el_formulario_cabe_en_la_tarjeta_minima`] avisa si ya no cabe.
    const ALTO_FORMULARIO: f32 = 610.0;

    #[test]
    fn el_formulario_cabe_en_la_tarjeta_minima() {
        // Peor caso: la ventana mínima admite la tarjeta de 600 px de alto y el
        // factor de escala más pequeño (0.74).
        let a = area(1100.0, 720.0);
        let card = card_rect(a);
        let alto_tarjeta = card.height();
        let escala_minima = (card.width() / 1280.0).clamp(0.74, 1.18);

        let alto = ALTO_FORMULARIO * escala_minima;
        assert!(
            alto <= alto_tarjeta,
            "el formulario mide {alto:.0} px y la tarjeta sólo {alto_tarjeta:.0} px \
             (escala {escala_minima:.2}); reduce el formulario o agranda la tarjeta"
        );
    }

    #[test]
    fn el_formulario_cabe_tambien_a_escala_maxima() {
        // Peor caso por arriba: ventana grande, escala 1.18.
        let a = area(2400.0, 1400.0);
        let card = card_rect(a);
        let alto_tarjeta = card.height();
        let escala = (card.width() / 1280.0).clamp(0.74, 1.18);

        let alto = ALTO_FORMULARIO * escala;
        assert!(
            alto <= alto_tarjeta,
            "el formulario mide {alto:.0} px y la tarjeta {alto_tarjeta:.0} px (escala {escala:.2})"
        );
    }

    #[test]
    fn la_tarjeta_se_centra_y_no_desborda() {
        let a = area(1600.0, 900.0);
        let card = card_rect(a);
        assert!(a.contains_rect(card));
        assert!((card.width() - 1280.0).abs() < 1.0);
        assert!((card.center().x - a.center().x).abs() < 1e-3);
        assert!((card.center().y - a.center().y).abs() < 1e-3);
    }

    #[test]
    fn la_tarjeta_cabe_en_la_ventana_minima() {
        let a = area(1100.0, 720.0);
        let card = card_rect(a);
        assert!(a.contains_rect(card));
        assert!(card.width() <= a.width());
        assert!(card.height() <= a.height());
    }

    #[test]
    fn el_estado_inicial_esta_vacio() {
        let login = LoginScreen::new();
        assert!(login.username.is_empty());
        assert!(login.password.is_empty());
        assert!(!login.show_password);
        assert!(login.error.is_none());
    }

    #[test]
    fn reset_limpia_el_formulario() {
        let mut login = LoginScreen::new();
        login.username = "admin".to_owned();
        login.password = "1234".to_owned();
        login.show_password = true;
        login.error = Some("credenciales inválidas".to_owned());
        login.reset();
        assert!(login.username.is_empty());
        assert!(login.password.is_empty());
        assert!(!login.show_password);
        assert!(login.error.is_none());
    }
}

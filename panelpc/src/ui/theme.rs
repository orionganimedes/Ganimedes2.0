//! Sistema de diseño del ecosistema Ganimedes.
//!
//! Los colores salen de `stitch_ganimedes_barber_pos/DESIGN.md` (Material 3
//! sobre lienzo obsidiana) y de la maqueta de `Iniciar Sesión`.
//!
//! Regla que impone este módulo y que la pantalla del POS rompía: **el color
//! del texto nunca se deja al azar**. `install()` fija `override_text_color`
//! sobre el lienzo oscuro, así que cualquier `label` sin color explícito sigue
//! siendo legible. Si pintas texto sobre una superficie clara, pide el color a
//! mano (`ON_LIGHT`) en lugar de confiar en la herencia.

// El juego de tokens es intencionadamente completo: los que todavía no se usan
// pertenecen a pantallas pendientes de migrar (POS, tickets, arqueo de caja).
#![allow(dead_code)]

use eframe::egui::{
    self, Color32, Context, CornerRadius, FontData, FontDefinitions, FontFamily, FontId, Mesh,
    Painter, Pos2, Rect, RichText, Shape, Stroke, StrokeKind, Vec2,
};
use std::sync::Arc;

// ========================================
// COLORES — tokens de DESIGN.md
// ========================================

// Lienzos y superficies
pub const SURFACE: Color32 = Color32::from_rgb(0x0b, 0x13, 0x26);
pub const SURFACE_DIM: Color32 = Color32::from_rgb(0x06, 0x0e, 0x20);
pub const SURFACE_CONTAINER_LOWEST: Color32 = Color32::from_rgb(0x06, 0x0e, 0x20);
pub const SURFACE_CONTAINER_LOW: Color32 = Color32::from_rgb(0x13, 0x1b, 0x2e);
pub const SURFACE_CONTAINER: Color32 = Color32::from_rgb(0x17, 0x1f, 0x33);
pub const SURFACE_CONTAINER_HIGH: Color32 = Color32::from_rgb(0x22, 0x2a, 0x3d);
pub const SURFACE_CONTAINER_HIGHEST: Color32 = Color32::from_rgb(0x2d, 0x34, 0x49);

// Texto
pub const ON_SURFACE: Color32 = Color32::from_rgb(0xda, 0xe2, 0xfd);
pub const ON_SURFACE_VARIANT: Color32 = Color32::from_rgb(0xc4, 0xc5, 0xd7);
pub const MUTED: Color32 = Color32::from_rgb(0x94, 0xa3, 0xb8);
pub const MUTED_DIM: Color32 = Color32::from_rgb(0x64, 0x74, 0x8b);
pub const ON_LIGHT: Color32 = Color32::from_rgb(0x0f, 0x17, 0x2a);

// Bordes
pub const OUTLINE: Color32 = Color32::from_rgb(0x8e, 0x90, 0xa0);
pub const OUTLINE_VARIANT: Color32 = Color32::from_rgb(0x43, 0x46, 0x55);

// Acentos
pub const PRIMARY: Color32 = Color32::from_rgb(0xb7, 0xc4, 0xff);
pub const ON_PRIMARY: Color32 = Color32::from_rgb(0x00, 0x26, 0x82);
pub const PRIMARY_CONTAINER: Color32 = Color32::from_rgb(0x1d, 0x4e, 0xd8);
pub const PRIMARY_HOVER: Color32 = Color32::from_rgb(0x25, 0x63, 0xeb);
pub const PRIMARY_PRESSED: Color32 = Color32::from_rgb(0x1a, 0x44, 0xc0);
pub const SECONDARY: Color32 = Color32::from_rgb(0x4c, 0xd6, 0xfb);
pub const SECONDARY_CONTAINER: Color32 = Color32::from_rgb(0x00, 0xb2, 0xd6);

// Roles funcionales (DESIGN.md)
pub const SUCCESS: Color32 = Color32::from_rgb(0x10, 0xb9, 0x81);
pub const WARNING: Color32 = Color32::from_rgb(0xf5, 0x9e, 0x0b);
pub const ERROR: Color32 = Color32::from_rgb(0xef, 0x44, 0x44);

// Superficies propias de la pantalla de acceso
pub const OUTER_BG: Color32 = Color32::from_rgb(0x07, 0x0b, 0x16);
pub const PANEL_LEFT_TOP: Color32 = Color32::from_rgb(0x16, 0x33, 0x64);
pub const PANEL_LEFT_BOTTOM: Color32 = Color32::from_rgb(0x08, 0x12, 0x27);
pub const PANEL_RIGHT: Color32 = Color32::from_rgb(0x0d, 0x15, 0x26);
pub const FIELD_BG: Color32 = Color32::from_rgb(0x11, 0x1a, 0x2e);
pub const FIELD_BG_FOCUS: Color32 = Color32::from_rgb(0x14, 0x1e, 0x35);
pub const FIELD_BORDER: Color32 = Color32::from_rgb(0x2d, 0x34, 0x49);

// Radios y medidas base (escala de la maqueta a 1280 px de ancho de tarjeta)
pub const CARD_RADIUS: f32 = 18.0;
pub const FIELD_RADIUS: f32 = 12.0;
pub const TAB_RADIUS: u8 = 10;

// ========================================
// TIPOGRAFÍA — Inter embebida
// ========================================

const FAMILY_SEMIBOLD: &str = "inter-semibold";
const FAMILY_BOLD: &str = "inter-bold";

pub const FONT_REGULAR: &[u8] = include_bytes!("../../assets/fonts/Inter-Regular.ttf");
pub const FONT_SEMIBOLD: &[u8] = include_bytes!("../../assets/fonts/Inter-SemiBold.ttf");
pub const FONT_BOLD: &[u8] = include_bytes!("../../assets/fonts/Inter-Bold.ttf");

pub fn regular(size: f32) -> FontId {
    FontId::new(size, FontFamily::Proportional)
}

pub fn semibold(size: f32) -> FontId {
    FontId::new(size, FontFamily::Name(FAMILY_SEMIBOLD.into()))
}

pub fn bold(size: f32) -> FontId {
    FontId::new(size, FontFamily::Name(FAMILY_BOLD.into()))
}

pub fn t_regular(text: impl Into<String>, size: f32, color: Color32) -> RichText {
    RichText::new(text).font(regular(size)).color(color)
}

pub fn t_semibold(text: impl Into<String>, size: f32, color: Color32) -> RichText {
    RichText::new(text).font(semibold(size)).color(color)
}

pub fn t_bold(text: impl Into<String>, size: f32, color: Color32) -> RichText {
    RichText::new(text).font(bold(size)).color(color)
}

/// Aproxima el *letter-spacing* de las micro-etiquetas del diseño insertando
/// espacios finos (U+2009) entre caracteres. egui no soporta tracking real.
pub fn tracked(text: &str) -> String {
    text.chars()
        .map(|c| c.to_string())
        .collect::<Vec<_>>()
        .join("\u{2009}")
}

/// Aplica transparencia a un color de la paleta (evita depender de `const fn`
/// de color con alfa, que cambia entre versiones de egui).
pub fn with_alpha(color: Color32, alpha: u8) -> Color32 {
    Color32::from_rgba_unmultiplied(color.r(), color.g(), color.b(), alpha)
}

/// Mezcla **opaca** de dos colores, interpolando canal a canal.
///
/// Se usa para las vetas de luz en lugar de alfa: egui guarda `Color32` con el
/// alfa premultiplicado en espacio lineal, así que un blanco con alfa 12 no se
/// ve como un 5% de blanco sino bastante más intenso. Mezclar aquí el color
/// final hace que el resultado sea el esperado y no dependa del backend.
pub fn mix(from: Color32, to: Color32, t: f32) -> Color32 {
    let t = t.clamp(0.0, 1.0);
    let lerp = |a: u8, b: u8| (a as f32 + (b as f32 - a as f32) * t).round() as u8;
    Color32::from_rgb(
        lerp(from.r(), to.r()),
        lerp(from.g(), to.g()),
        lerp(from.b(), to.b()),
    )
}

// ========================================
// INSTALACIÓN DE ESTILOS
// ========================================

pub fn install(ctx: &Context) {
    install_fonts(ctx);

    let mut style = (*ctx.style()).clone();
    let mut v = egui::Visuals::dark();

    // Clave contra el bug de contraste: todo texto sin color explícito es claro.
    v.override_text_color = Some(ON_SURFACE);

    v.panel_fill = SURFACE;
    v.window_fill = SURFACE_CONTAINER;
    v.extreme_bg_color = FIELD_BG;
    v.window_stroke = Stroke::new(1.0_f32, OUTLINE_VARIANT);
    v.window_corner_radius = CornerRadius::same(14);
    v.window_shadow = egui::epaint::Shadow::NONE;
    v.popup_shadow = egui::epaint::Shadow::NONE;

    v.selection.bg_fill = with_alpha(SECONDARY, 70);
    v.selection.stroke = Stroke::new(1.0_f32, ON_SURFACE);

    v.widgets.noninteractive.bg_fill = SURFACE_CONTAINER_LOW;
    v.widgets.noninteractive.bg_stroke = Stroke::new(1.0_f32, OUTLINE_VARIANT);
    v.widgets.noninteractive.fg_stroke = Stroke::new(1.0_f32, ON_SURFACE_VARIANT);
    v.widgets.noninteractive.corner_radius = CornerRadius::same(TAB_RADIUS);

    v.widgets.inactive.bg_fill = SURFACE_CONTAINER_HIGH;
    v.widgets.inactive.weak_bg_fill = SURFACE_CONTAINER_LOW;
    v.widgets.inactive.fg_stroke = Stroke::new(1.0_f32, ON_SURFACE);
    v.widgets.inactive.corner_radius = CornerRadius::same(TAB_RADIUS);

    v.widgets.hovered.bg_fill = SURFACE_CONTAINER_HIGHEST;
    v.widgets.hovered.weak_bg_fill = SURFACE_CONTAINER_HIGH;
    v.widgets.hovered.fg_stroke = Stroke::new(1.0_f32, Color32::WHITE);
    v.widgets.hovered.corner_radius = CornerRadius::same(TAB_RADIUS);

    v.widgets.active.bg_fill = PRIMARY_CONTAINER;
    v.widgets.active.weak_bg_fill = PRIMARY_CONTAINER;
    v.widgets.active.fg_stroke = Stroke::new(1.0_f32, Color32::WHITE);
    v.widgets.active.corner_radius = CornerRadius::same(TAB_RADIUS);

    v.widgets.open.bg_fill = SURFACE_CONTAINER_LOW;
    v.widgets.open.fg_stroke = Stroke::new(1.0_f32, ON_SURFACE);
    v.widgets.open.corner_radius = CornerRadius::same(TAB_RADIUS);

    style.visuals = v;
    style.spacing.item_spacing = Vec2::new(8.0, 8.0);
    style.spacing.button_padding = Vec2::new(12.0, 6.0);
    style.spacing.interact_size.y = 28.0;

    ctx.set_style(style);
}

fn install_fonts(ctx: &Context) {
    let mut fonts = FontDefinitions::default();

    fonts.font_data.insert(
        "inter-regular".to_owned(),
        Arc::new(FontData::from_static(FONT_REGULAR)),
    );
    fonts.font_data.insert(
        "inter-semibold".to_owned(),
        Arc::new(FontData::from_static(FONT_SEMIBOLD)),
    );
    fonts.font_data.insert(
        "inter-bold".to_owned(),
        Arc::new(FontData::from_static(FONT_BOLD)),
    );

    // Inter pasa a ser la fuente proporcional por defecto.
    fonts
        .families
        .entry(FontFamily::Proportional)
        .or_default()
        .insert(0, "inter-regular".to_owned());

    // Y exponemos los pesos como familias con nombre para poder pedirlos.
    fonts.families.insert(
        FontFamily::Name(FAMILY_SEMIBOLD.into()),
        vec!["inter-semibold".to_owned()],
    );
    fonts.families.insert(
        FontFamily::Name(FAMILY_BOLD.into()),
        vec!["inter-bold".to_owned()],
    );

    ctx.set_fonts(fonts);
}

// ========================================
// AYUDAS DE DIBUJO
// ========================================

/// Relleno degradado de un rectángulo (vertical u horizontal).
pub fn gradient_rect(
    painter: &Painter,
    rect: Rect,
    from: Color32,
    to: Color32,
    horizontal: bool,
) {
    let (tl, tr, bl, br) = if horizontal {
        (from, to, from, to)
    } else {
        (from, from, to, to)
    };

    let mut mesh = Mesh::default();
    mesh.colored_vertex(rect.left_top(), tl);
    mesh.colored_vertex(rect.right_top(), tr);
    mesh.colored_vertex(rect.left_bottom(), bl);
    mesh.colored_vertex(rect.right_bottom(), br);
    mesh.add_triangle(0, 1, 2);
    mesh.add_triangle(2, 1, 3);
    painter.add(Shape::mesh(mesh));
}

/// Banda diagonal translúcida: las "vetas" de luz del panel de marca.
/// `top_x`/`bottom_x` son fracciones del ancho donde la banda cruza el borde
/// superior e inferior; `width` es su grosor como fracción del ancho.
pub fn diagonal_band(
    painter: &Painter,
    rect: Rect,
    top_x: f32,
    bottom_x: f32,
    width: f32,
    color: Color32,
) {
    let w = rect.width();
    let band = width * w;
    let points = vec![
        Pos2::new(rect.left() + top_x * w, rect.top()),
        Pos2::new(rect.left() + top_x * w + band, rect.top()),
        Pos2::new(rect.left() + bottom_x * w + band, rect.bottom()),
        Pos2::new(rect.left() + bottom_x * w, rect.bottom()),
    ];
    painter.add(Shape::convex_polygon(points, color, Stroke::NONE));
}

/// Tapa las cuatro esquinas con el color del fondo para simular un rectángulo
/// redondeado sobre rellenos que no admiten radio (degradados, mallas).
pub fn mask_corners(painter: &Painter, rect: Rect, radius: f32, mask: Color32) {
    mask_corner(painter, rect, radius, mask, Corner::TopLeft);
    mask_corner(painter, rect, radius, mask, Corner::TopRight);
    mask_corner(painter, rect, radius, mask, Corner::BottomLeft);
    mask_corner(painter, rect, radius, mask, Corner::BottomRight);
}

#[derive(Clone, Copy, Debug)]
enum Corner {
    TopLeft,
    TopRight,
    BottomLeft,
    BottomRight,
}

fn mask_corner(painter: &Painter, rect: Rect, radius: f32, mask: Color32, corner: Corner) {
    let r = radius.min(rect.width() * 0.5).min(rect.height() * 0.5);
    if r <= 0.0 {
        return;
    }

    let (center, corner_pt, start_deg) = corner_geometry(rect, r, corner);
    let points = corner_mask_points(center, corner_pt, r, start_deg);

    // La región "esquina menos cuarto de círculo" es estrellada respecto al
    // vértice, así que el abanico de triángulos es válido aunque no sea convexa.
    painter.add(Shape::convex_polygon(points, mask, Stroke::NONE));
}

/// Centro del círculo, vértice de la esquina y ángulo inicial del arco.
///
/// El arco debe recorrer el cuadrante que queda **dentro** del cuadrado de la
/// esquina (de un punto tangente al otro). Barrer el cuadrante opuesto hace que
/// el máscara tape parte de la tarjeta en lugar de la esquina.
fn corner_geometry(rect: Rect, r: f32, corner: Corner) -> (Pos2, Pos2, f32) {
    match corner {
        Corner::TopLeft => (
            Pos2::new(rect.left() + r, rect.top() + r),
            rect.left_top(),
            180.0,
        ),
        Corner::TopRight => (
            Pos2::new(rect.right() - r, rect.top() + r),
            rect.right_top(),
            270.0,
        ),
        Corner::BottomRight => (
            Pos2::new(rect.right() - r, rect.bottom() - r),
            rect.right_bottom(),
            0.0,
        ),
        Corner::BottomLeft => (
            Pos2::new(rect.left() + r, rect.bottom() - r),
            rect.left_bottom(),
            90.0,
        ),
    }
}

/// Vértice + arco de 90° muestreado: el polígono del máscara.
fn corner_mask_points(center: Pos2, corner_pt: Pos2, r: f32, start_deg: f32) -> Vec<Pos2> {
    let steps = 10;
    let mut points = Vec::with_capacity(steps + 2);
    points.push(corner_pt);
    for i in 0..=steps {
        let t = i as f32 / steps as f32;
        let angle = (start_deg + t * 90.0).to_radians();
        points.push(Pos2::new(
            center.x + r * angle.cos(),
            center.y + r * angle.sin(),
        ));
    }
    points
}

/// Fondo de un campo de texto, con anillo de foco cian como en el diseño.
pub fn paint_field(painter: &Painter, rect: Rect, focused: bool, scale: f32) {
    let cr = CornerRadius::same((FIELD_RADIUS * scale) as u8);

    if focused {
        painter.rect_stroke(
            rect.expand(2.5 * scale),
            CornerRadius::same((FIELD_RADIUS * scale) as u8 + 3),
            Stroke::new(3.0 * scale, with_alpha(SECONDARY, 45)),
            StrokeKind::Inside,
        );
        painter.rect_filled(rect, cr, FIELD_BG_FOCUS);
        painter.rect_stroke(
            rect,
            cr,
            Stroke::new(1.2 * scale, SECONDARY),
            StrokeKind::Inside,
        );
    } else {
        painter.rect_filled(rect, cr, FIELD_BG);
        painter.rect_stroke(
            rect,
            cr,
            Stroke::new(1.0_f32, FIELD_BORDER),
            StrokeKind::Inside,
        );
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn el_ancho_de_la_fuente_embebida_esta_disponible() {
        // Si las fuentes no se hubiesen copiado, `include_bytes!` ni compilaría;
        // aquí comprobamos que los tres pesos tienen contenido real.
        assert!(FONT_REGULAR.len() > 1000);
        assert!(FONT_SEMIBOLD.len() > 1000);
        assert!(FONT_BOLD.len() > 1000);
    }

    #[test]
    fn tracked_separa_los_caracteres() {
        assert_eq!(tracked("AB"), "A\u{2009}B");
        assert_eq!(tracked(""), "");
    }

    #[test]
    fn with_alpha_respeta_los_extremos() {
        // egui guarda el color con alfa premultiplicado en espacio lineal, así
        // que solo los extremos son exactos; el resto es una mezcla válida.
        assert_eq!(with_alpha(SECONDARY, 255), SECONDARY);
        assert_eq!(with_alpha(SECONDARY, 0), Color32::TRANSPARENT);
        assert_eq!(with_alpha(SECONDARY, 40).a(), 40);
    }

    #[test]
    fn mix_interpola_y_se_satura() {
        assert_eq!(mix(Color32::BLACK, Color32::WHITE, 0.0), Color32::BLACK);
        assert_eq!(mix(Color32::BLACK, Color32::WHITE, 1.0), Color32::WHITE);
        assert_eq!(
            mix(Color32::BLACK, Color32::WHITE, 0.5),
            Color32::from_rgb(128, 128, 128)
        );
        assert_eq!(mix(Color32::BLACK, Color32::WHITE, 5.0), Color32::WHITE);
    }

    /// Regresión: los cuatro máscaros deben quedarse dentro del cuadrado de su
    /// esquina. Con los ángulos desviados 90° invadían la tarjeta y dejaban
    /// recortes oscuros visibles.
    #[test]
    fn los_mascaros_de_esquina_no_invaden_la_tarjeta() {
        let rect = Rect::from_min_size(Pos2::new(100.0, 50.0), Vec2::new(400.0, 300.0));
        let r = 18.0;

        let casos = [
            (
                Corner::TopLeft,
                Rect::from_min_max(Pos2::new(100.0, 50.0), Pos2::new(118.0, 68.0)),
            ),
            (
                Corner::TopRight,
                Rect::from_min_max(Pos2::new(482.0, 50.0), Pos2::new(500.0, 68.0)),
            ),
            (
                Corner::BottomRight,
                Rect::from_min_max(Pos2::new(482.0, 332.0), Pos2::new(500.0, 350.0)),
            ),
            (
                Corner::BottomLeft,
                Rect::from_min_max(Pos2::new(100.0, 332.0), Pos2::new(118.0, 350.0)),
            ),
        ];

        for (corner, cuadro) in casos {
            let (center, corner_pt, start_deg) = corner_geometry(rect, r, corner);
            let puntos = corner_mask_points(center, corner_pt, r, start_deg);

            assert!(cuadro.contains(puntos[0]), "{corner:?}: el vértice se sale");
            assert_eq!(puntos.len(), 12);

            for punto in &puntos {
                assert!(
                    cuadro.expand(1e-3).contains(*punto),
                    "{corner:?}: {punto:?} cae fuera de {cuadro:?}"
                );
                assert!(
                    ((*punto - center).length() - r).abs() < 1e-2 || *punto == corner_pt,
                    "{corner:?}: {punto:?} no está sobre el arco"
                );
            }
        }
    }
}

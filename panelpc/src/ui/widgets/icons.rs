//! Iconos vectoriales dibujados con el `Painter` de egui.
//!
//! Se dibujan a mano en lugar de usar una fuente de iconos para no añadir
//! dependencias ni glifos que puedan faltar en el sistema objetivo (un Panel PC
//! puede no tener emojis instalados). Todas las funciones trabajan con
//! coordenadas normalizadas 0..1 y preservan la proporción.

// Mientras `app.rs` no enrute a la pantalla de acceso, estos iconos solo los usa
// `login.rs`; el allow evita avisos de código muerto en el build del equipo.
#![allow(dead_code)]

use eframe::egui::{Color32, CornerRadius, Painter, Pos2, Rect, Shape, Stroke, StrokeKind};

/// Centro y lado del cuadrado de referencia del icono.
fn frame(rect: Rect) -> (Pos2, f32) {
    (rect.center(), rect.width().min(rect.height()))
}

/// Traduce coordenadas normalizadas (0..1) al rectángulo real.
fn p(center: Pos2, side: f32, x: f32, y: f32) -> Pos2 {
    Pos2::new(
        center.x + (x - 0.5) * side,
        center.y + (y - 0.5) * side,
    )
}

fn arc(center: Pos2, rx: f32, ry: f32, from_deg: f32, to_deg: f32, steps: usize) -> Vec<Pos2> {
    (0..=steps)
        .map(|i| {
            let t = i as f32 / steps as f32;
            let a = (from_deg + (to_deg - from_deg) * t).to_radians();
            Pos2::new(center.x + rx * a.cos(), center.y + ry * a.sin())
        })
        .collect()
}

/// Silueta de persona: cabeza y hombros.
pub fn person(painter: &Painter, rect: Rect, color: Color32) {
    let (c, s) = frame(rect);
    let w = (s * 0.11).max(1.3);

    painter.circle_stroke(p(c, s, 0.5, 0.33), s * 0.155, Stroke::new(w, color));

    // Hombros: semicírculo abierto hacia arriba.
    let shoulders = arc(p(c, s, 0.5, 0.94), s * 0.30, s * 0.42, 180.0, 360.0, 18);
    painter.add(Shape::line(shoulders, Stroke::new(w, color)));
}

/// Candado: arco superior, cuerpo y ojo de la cerradura.
pub fn lock(painter: &Painter, rect: Rect, color: Color32) {
    let (c, s) = frame(rect);
    let w = (s * 0.11).max(1.3);

    let shackle = arc(p(c, s, 0.5, 0.44), s * 0.19, s * 0.22, 180.0, 360.0, 16);
    painter.add(Shape::line(shackle, Stroke::new(w, color)));

    let body = Rect::from_min_max(p(c, s, 0.25, 0.45), p(c, s, 0.75, 0.86));
    painter.rect_stroke(
        body,
        CornerRadius::same((s * 0.10).max(1.0) as u8),
        Stroke::new(w, color),
        StrokeKind::Inside,
    );

    painter.circle_filled(p(c, s, 0.5, 0.65), (s * 0.05).max(1.0), color);
}

/// Ojo para el botón de mostrar/ocultar contraseña. Si `open` es falso, añade
/// la barra diagonal de "oculto".
pub fn eye(painter: &Painter, rect: Rect, color: Color32, open: bool) {
    let (c, s) = frame(rect);
    let w = (s * 0.10).max(1.2);

    let mut outline = arc(c, s * 0.36, s * 0.20, 180.0, 360.0, 18);
    outline.extend(arc(c, s * 0.36, s * 0.20, 0.0, 180.0, 18));
    painter.add(Shape::line(outline, Stroke::new(w, color)));

    painter.circle_stroke(c, s * 0.105, Stroke::new(w, color));

    if !open {
        painter.line_segment(
            [
                Pos2::new(c.x - s * 0.30, c.y + s * 0.28),
                Pos2::new(c.x + s * 0.30, c.y - s * 0.28),
            ],
            Stroke::new(w, color),
        );
    }
}

/// Flecha hacia la derecha del botón principal.
pub fn arrow_right(painter: &Painter, rect: Rect, color: Color32) {
    let (c, s) = frame(rect);
    let w = (s * 0.13).max(1.4);
    let stroke = Stroke::new(w, color);

    painter.line_segment([p(c, s, 0.12, 0.5), p(c, s, 0.86, 0.5)], stroke);
    painter.line_segment([p(c, s, 0.60, 0.24), p(c, s, 0.88, 0.5)], stroke);
    painter.line_segment([p(c, s, 0.60, 0.76), p(c, s, 0.88, 0.5)], stroke);
}

/// Terminal punto de venta: pantalla, teclas y ranura.
pub fn terminal(painter: &Painter, rect: Rect, color: Color32) {
    let (c, s) = frame(rect);
    let w = (s * 0.085).max(1.2);

    let body = Rect::from_min_max(p(c, s, 0.20, 0.13), p(c, s, 0.80, 0.87));
    painter.rect_stroke(
        body,
        CornerRadius::same((s * 0.09).max(1.0) as u8),
        Stroke::new(w, color),
        StrokeKind::Inside,
    );

    let screen = Rect::from_min_max(p(c, s, 0.32, 0.25), p(c, s, 0.68, 0.49));
    painter.rect_filled(screen, CornerRadius::same((s * 0.03).max(1.0) as u8), color);

    for i in 0..3 {
        let x = 0.35 + 0.15 * i as f32;
        painter.circle_filled(p(c, s, x, 0.65), (s * 0.035).max(0.8), color);
    }

    painter.line_segment(
        [p(c, s, 0.32, 0.79), p(c, s, 0.68, 0.79)],
        Stroke::new(w, color),
    );
}

/// Punto de estado para chips y etiquetas.
pub fn dot(painter: &Painter, center: Pos2, radius: f32, color: Color32) {
    painter.circle_filled(center, radius, color);
}

/// Caja de icono cuadrada y redondeada (insignia del logotipo).
pub fn badge(painter: &Painter, rect: Rect, fill: Color32, border: Color32, radius: f32) {
    painter.rect_filled(rect, CornerRadius::same(radius as u8), fill);
    painter.rect_stroke(
        rect,
        CornerRadius::same(radius as u8),
        Stroke::new(1.0_f32, border),
        StrokeKind::Inside,
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn las_coordenadas_normalizadas_respetan_el_centro() {
        let c = Pos2::new(10.0, 20.0);
        let centro = p(c, 40.0, 0.5, 0.5);
        assert!((centro.x - 10.0).abs() < 1e-4);
        assert!((centro.y - 20.0).abs() < 1e-4);
    }

    #[test]
    fn los_extremos_caen_en_el_borde_del_cuadrado() {
        let c = Pos2::new(0.0, 0.0);
        let arriba_izq = p(c, 40.0, 0.0, 0.0);
        assert!((arriba_izq.x + 20.0).abs() < 1e-4);
        assert!((arriba_izq.y + 20.0).abs() < 1e-4);
    }
}

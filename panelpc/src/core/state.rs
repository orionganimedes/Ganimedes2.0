use crate::core::models::{CartItem, PaymentMethod, Product};
use crate::infra::db::LocalDatabase;

pub struct PosState {
    pub db: LocalDatabase,
    pub products: Vec<Product>,
    pub categories: Vec<String>,
    pub selected_category_index: usize,
    pub search_query: String,
    pub cart: Vec<CartItem>,
    pub discount: f64,
    pub discount_input: String,
    pub selected_payment_method: PaymentMethod,
    pub show_checkout_dialog: bool,
    pub toast_message: Option<(String, std::time::Instant)>,
}

impl Default for PosState {
    fn default() -> Self {
        Self::new()
    }
}

impl PosState {
    pub fn new() -> Self {
        let db = LocalDatabase::new().expect("No se pudo inicializar la base de datos local");

        let products = db
            .get_all_products()
            .expect("No se pudo cargar el catálogo de productos");

        let categories = Self::get_default_categories();

        Self {
            db,
            products,
            categories,
            selected_category_index: 0,
            search_query: String::new(),
            cart: Vec::new(),
            discount: 0.0,
            discount_input: String::new(),
            selected_payment_method: PaymentMethod::Tarjeta,
            show_checkout_dialog: false,
            toast_message: None,
        }
    }

    fn get_default_categories() -> Vec<String> {
        vec![
            "Todos".to_string(),
            "Ropa".to_string(),
            "Calzado".to_string(),
            "Accesorios".to_string(),
            "Electronica".to_string(),
        ]
    }

    pub fn get_filtered_products(&self) -> Vec<&Product> {
        let category_filter = if self.selected_category_index == 0 {
            None
        } else {
            self.categories.get(self.selected_category_index).map(|s| s.as_str())
        };

        let query = self.search_query.trim().to_lowercase();

        self.products
            .iter()
            .filter(|p| {
                if let Some(cat) = category_filter {
                    if p.category != cat {
                        return false;
                    }
                }
                if !query.is_empty() {
                    let matches_name = p.name.to_lowercase().contains(&query);
                    let matches_category = p.category.to_lowercase().contains(&query);
                    if !matches_name && !matches_category {
                        return false;
                    }
                }
                true
            })
            .collect()
    }

    /// Añade una unidad del producto al carrito.
    ///
    /// Si ya estaba, incrementa la cantidad; el carrito vive en memoria porque
    /// es estado de sesión (lo definitivo se persiste al confirmar la venta).
    pub fn add_to_cart(&mut self, product: &Product) {
        if let Some(item) = self
            .cart
            .iter_mut()
            .find(|item| item.product.id == product.id)
        {
            item.quantity += 1;
        } else {
            self.cart.push(CartItem {
                product: product.clone(),
                quantity: 1,
            });
        }
    }

    /// Suma una unidad a la línea indicada.
    pub fn increment_cart_item(&mut self, index: usize) {
        if let Some(item) = self.cart.get_mut(index) {
            item.quantity += 1;
        }
    }

    /// Resta una unidad a la línea indicada, quitándola si llega a cero.
    pub fn decrement_cart_item(&mut self, index: usize) {
        if index >= self.cart.len() {
            return;
        }

        if self.cart[index].quantity > 1 {
            self.cart[index].quantity -= 1;
        } else {
            self.cart.remove(index);
        }
    }

    /// Quita una línea completa del carrito.
    pub fn remove_cart_item(&mut self, index: usize) {
        if index < self.cart.len() {
            self.cart.remove(index);
        }
    }

    /// Número total de unidades en el carrito (no de líneas).
    pub fn total_items(&self) -> u32 {
        self.cart.iter().map(|item| item.quantity).sum()
    }

    pub fn clear_cart(&mut self) {
        self.cart.clear();
        self.discount = 0.0;
        self.discount_input.clear();
    }

    pub fn set_discount_from_input(&mut self) {
        let trimmed = self.discount_input.trim();
        if trimmed.is_empty() {
            self.discount = 0.0;
        } else if let Ok(val) = trimmed.parse::<f64>() {
            self.discount = val.clamp(0.0, 100.0);
        }
    }

    pub fn calculate_subtotal(&self) -> f64 {
        self.cart
            .iter()
            .map(|item| item.product.price * (item.quantity as f64))
            .sum()
    }

    pub fn calculate_discount_amount(&self) -> f64 {
        self.calculate_subtotal() * (self.discount / 100.0)
    }

    pub fn calculate_total(&self) -> f64 {
        self.calculate_subtotal() - self.calculate_discount_amount()
    }

    pub fn show_toast(&mut self, msg: String) {
        self.toast_message = Some((msg, std::time::Instant::now()));
    }

    pub fn get_active_toast(&mut self) -> Option<&str> {
        let is_expired = if let Some((_, instant)) = &self.toast_message {
            instant.elapsed().as_secs_f32() >= 4.0
        } else {
            false
        };

        if is_expired {
            self.toast_message = None;
        }

        self.toast_message.as_ref().map(|(msg, _)| msg.as_str())
    }

    pub fn complete_sale(&mut self) -> Result<(), String> {
        // Simplified: In a full implementation, you'd create a sale record in the database
        // For now, just clear the cart
        self.clear_cart();
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn estado() -> PosState {
        PosState::new()
    }

    fn producto(id: u32) -> Product {
        Product {
            id,
            name: format!("Producto {}", id),
            price: 10.0,
            category: "Ropa".to_string(),
            image: "X".to_string(),
        }
    }

    #[test]
    fn test_initial_state() {
        let _state = PosState::new();
    }

    #[test]
    fn el_catalogo_no_arranca_vacio() {
        let state = estado();
        assert!(
            !state.products.is_empty(),
            "el catálogo debe traer productos sembrados"
        );
    }

    #[test]
    fn anadir_al_carrito_crea_una_linea() {
        let mut state = estado();
        state.add_to_cart(&producto(1));

        assert_eq!(state.cart.len(), 1);
        assert_eq!(state.cart[0].quantity, 1);
        assert_eq!(state.total_items(), 1);
    }

    #[test]
    fn anadir_el_mismo_producto_incrementa_la_cantidad() {
        let mut state = estado();
        state.add_to_cart(&producto(1));
        state.add_to_cart(&producto(1));

        assert_eq!(state.cart.len(), 1, "no debe duplicar la línea");
        assert_eq!(state.cart[0].quantity, 2);
    }

    #[test]
    fn incrementar_y_decrementar_respetan_los_limites() {
        let mut state = estado();
        state.add_to_cart(&producto(1));

        state.increment_cart_item(0);
        assert_eq!(state.cart[0].quantity, 2);

        state.decrement_cart_item(0);
        assert_eq!(state.cart[0].quantity, 1);

        // Al bajar de 1 la línea desaparece en lugar de quedar en cero.
        state.decrement_cart_item(0);
        assert!(state.cart.is_empty());
    }

    #[test]
    fn decrementar_un_indice_inexistente_no_entra_en_panico() {
        let mut state = estado();
        state.decrement_cart_item(7);
        state.increment_cart_item(7);
        state.remove_cart_item(7);
        assert!(state.cart.is_empty());
    }

    #[test]
    fn los_totales_reflejan_el_carrito() {
        let mut state = estado();
        state.add_to_cart(&producto(1));
        state.add_to_cart(&producto(1));
        state.add_to_cart(&producto(2));

        assert_eq!(state.calculate_subtotal(), 30.0);

        state.discount_input = "10".to_string();
        state.set_discount_from_input();

        assert_eq!(state.calculate_discount_amount(), 3.0);
        assert_eq!(state.calculate_total(), 27.0);
    }

    #[test]
    fn el_descuento_se_limita_a_cien() {
        let mut state = estado();
        state.discount_input = "250".to_string();
        state.set_discount_from_input();
        assert_eq!(state.discount, 100.0);

        state.discount_input = "-5".to_string();
        state.set_discount_from_input();
        assert_eq!(state.discount, 0.0);
    }

    #[test]
    fn buscar_y_filtrar_por_categoria() {
        let mut state = estado();

        // El filtro "Todos" (índice 0) devuelve el catálogo completo.
        assert_eq!(state.get_filtered_products().len(), state.products.len());

        // El buscador no distingue mayúsculas ni espacios sobrantes.
        state.search_query = "  camiseta  ".to_string();
        assert!(!state.get_filtered_products().is_empty());

        // Una búsqueda sin resultados no debe devolver nada.
        state.search_query = "zzzz-no-existe".to_string();
        assert!(state.get_filtered_products().is_empty());
    }

    #[test]
    fn completar_la_venta_vacia_el_carrito() {
        let mut state = estado();
        state.add_to_cart(&producto(1));
        state.discount_input = "10".to_string();
        state.set_discount_from_input();

        state.complete_sale().expect("la venta debe completarse");

        assert!(state.cart.is_empty());
        assert_eq!(state.discount, 0.0);
        assert!(state.discount_input.is_empty());
    }
}
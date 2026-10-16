//! Catálogo de productos en SQLite local.
//!
//! Este módulo es la fuente de verdad del **catálogo** cuando la aplicación
//! funciona sin backend. El **carrito** no se persiste aquí: vive en memoria
//! ([`crate::core::state::PosState`]) porque es estado de sesión, y quien lo
//! guarda definitivamente es PocketBase al confirmar la venta.
//!
//! Al abrir la base se siembra un catálogo de demostración la primera vez, de
//! modo que la aplicación arranca con contenido visible en lugar de una
//! pantalla vacía.

use crate::core::models::Product;
use rusqlite::Connection;

/// Productos de demostración: (id, nombre, precio, categoría, icono).
///
/// Las categorías deben coincidir con las de `PosState::categories` para que
/// los filtros de la interfaz encuentren resultados.
const PRODUCTOS_DEMO: &[(u32, &str, f64, &str, &str)] = &[
    (1, "Camiseta Básica", 29.99, "Ropa", "👕"),
    (2, "Pantalones Jeans", 49.99, "Ropa", "👖"),
    (3, "Zapatos Deportivos", 89.99, "Calzado", "👟"),
    (4, "Bolso de Mano", 59.99, "Accesorios", "👜"),
    (5, "Reloj de Pulsera", 129.99, "Accesorios", "⌚"),
    (6, "Auriculares Bluetooth", 79.99, "Electronica", "🎧"),
    (7, "Cargador Portátil", 39.99, "Electronica", "🔋"),
    (8, "Mochila Urban", 44.99, "Accesorios", "🎒"),
    (9, "Gafas de Sol", 69.99, "Accesorios", "🕶️"),
    (10, "Camisa Formal", 54.99, "Ropa", "👔"),
    (11, "Zapatos Tacón", 99.99, "Calzado", "👠"),
    (12, "Tablet 10\"", 349.99, "Electronica", "📱"),
];

pub struct LocalDatabase {
    conn: Connection,
}

impl LocalDatabase {
    /// Abre la base y garantiza que el catálogo tenga contenido.
    ///
    /// Es una base **en memoria**: cada arranque parte del catálogo de
    /// demostración. Para persistir entre ejecuciones basta con cambiar el
    /// [`Connection::open_in_memory`] por `Connection::open(ruta)`.
    pub fn new() -> Result<Self, String> {
        let conn = Connection::open_in_memory()
            .map_err(|e| format!("No se pudo abrir la base de datos: {}", e))?;

        let mut db = Self { conn };
        db.init_schema()?;
        db.seed_si_esta_vacia()?;
        Ok(db)
    }

    fn init_schema(&mut self) -> Result<(), String> {
        self.conn
            .execute_batch(SCHEMA)
            .map_err(|e| format!("No se pudo crear el esquema: {}", e))?;
        Ok(())
    }

    /// Inserta el catálogo de demostración sólo si la tabla está vacía.
    fn seed_si_esta_vacia(&mut self) -> Result<(), String> {
        let total: i64 = self
            .conn
            .query_row("SELECT COUNT(*) FROM products", [], |row| row.get(0))
            .map_err(|e| format!("No se pudo contar los productos: {}", e))?;

        if total > 0 {
            return Ok(());
        }

        let tx = self
            .conn
            .transaction()
            .map_err(|e| format!("No se pudo iniciar la transacción: {}", e))?;

        for (id, nombre, precio, categoria, icono) in PRODUCTOS_DEMO {
            tx.execute(
                "INSERT INTO products (id, name, price, category, image) VALUES (?1, ?2, ?3, ?4, ?5)",
                rusqlite::params![id, nombre, precio, categoria, icono],
            )
            .map_err(|e| format!("No se pudo sembrar el producto {}: {}", id, e))?;
        }

        tx.commit()
            .map_err(|e| format!("No se pudo confirmar el catálogo: {}", e))?;

        Ok(())
    }

    /// Devuelve el catálogo completo ordenado por identificador.
    pub fn get_all_products(&self) -> Result<Vec<Product>, String> {
        let mut stmt = self
            .conn
            .prepare("SELECT id, name, price, category, image FROM products ORDER BY id")
            .map_err(|e| format!("No se pudo preparar la consulta: {}", e))?;

        let products = stmt
            .query_map([], |row| {
                Ok(Product {
                    id: row.get(0)?,
                    name: row.get(1)?,
                    price: row.get(2)?,
                    category: row.get(3)?,
                    image: row.get(4)?,
                })
            })
            .map_err(|e| format!("No se pudo consultar el catálogo: {}", e))?;

        products
            .map(|p| p.map_err(|e| e.to_string()))
            .collect::<Result<Vec<Product>, String>>()
    }
}

const SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    category TEXT NOT NULL,
    image TEXT NOT NULL
);
"#;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn el_catalogo_se_siembra_al_abrir() {
        let db = LocalDatabase::new().expect("la base debe abrirse");
        let productos = db.get_all_products().expect("el catálogo debe leerse");
        assert_eq!(productos.len(), PRODUCTOS_DEMO.len());
    }

    #[test]
    fn leer_dos_veces_no_duplica_el_catalogo() {
        let db = LocalDatabase::new().expect("la base debe abrirse");
        let primera = db.get_all_products().expect("primera lectura");
        let segunda = db.get_all_products().expect("segunda lectura");
        assert_eq!(primera.len(), segunda.len());
    }

    #[test]
    fn las_categorias_sembradas_son_filtrables() {
        // Los filtros de la interfaz sólo encuentran productos si el nombre de
        // la categoría coincide exactamente con el de PosState::categories.
        let db = LocalDatabase::new().expect("la base debe abrirse");
        let productos = db.get_all_products().expect("el catálogo debe leerse");

        let conocidas = [
            "Ropa",
            "Calzado",
            "Accesorios",
            "Electronica",
        ];
        for p in &productos {
            assert!(
                conocidas.contains(&p.category.as_str()),
                "categoría inesperada en el catálogo: {}",
                p.category
            );
        }
    }

    #[test]
    fn los_precios_son_positivos() {
        let db = LocalDatabase::new().expect("la base debe abrirse");
        for p in db.get_all_products().expect("el catálogo debe leerse") {
            assert!(p.price > 0.0, "precio no válido en {}", p.name);
        }
    }
}

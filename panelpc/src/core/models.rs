use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Product {
    pub id: u32,
    pub name: String,
    pub price: f64,
    pub category: String,
    pub image: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CartItem {
    pub product: Product,
    pub quantity: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PaymentMethod {
    Tarjeta,
    Efectivo,
    Transferencia,
    Wallet,
}

impl PaymentMethod {
    pub const ALL: [PaymentMethod; 4] = [
        PaymentMethod::Tarjeta,
        PaymentMethod::Efectivo,
        PaymentMethod::Transferencia,
        PaymentMethod::Wallet,
    ];

    pub fn as_str(&self) -> &'static str {
        match self {
            PaymentMethod::Tarjeta => "Tarjeta",
            PaymentMethod::Efectivo => "Efectivo",
            PaymentMethod::Transferencia => "Transferencia",
            PaymentMethod::Wallet => "Wallet",
        }
    }
}

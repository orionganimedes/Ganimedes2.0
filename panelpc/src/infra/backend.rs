use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// ========================================
// POCKETBASE TYPES
// ========================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Record {
    #[serde(rename = "id")]
    pub record_id: String,
    #[serde(rename = "created")]
    pub created: String,
    #[serde(rename = "updated")]
    pub updated: String,
    #[serde(flatten)]
    pub fields: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthToken {
    pub token: String,
    pub data: UserRecord,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserRecord {
    pub id: String,
    pub email: String,
    pub role: String,
    pub pin: Option<String>,
    pub chair: Option<String>,
    pub shift: Option<String>,
    pub branch_code: Option<String>,
    pub is_active: bool,
}

// ========================================
// BACKEND CLIENT
// ========================================

pub struct BackendClient {
    base_url: String,
    client: reqwest::Client,
}

impl BackendClient {
    pub fn new(base_url: &str) -> Result<Self, String> {
        let client = reqwest::Client::new();
        Ok(Self {
            base_url: base_url.trim_end_matches('/').to_string(),
            client,
        })
    }

    // ========================================
    // AUTHENTICATION
    // ========================================

    pub async fn auth_with_password(&self, email: &str, password: &str) -> Result<AuthToken, String> {
        let url = format!("{}/api/admins/auth-with-password", self.base_url);
        
        let response = self.client
            .post(&url)
            .json(&serde_json::json!({
                "identity": email,
                "password": password
            }))
            .send()
            .await
            .map_err(|e| format!("Failed to authenticate: {}", e))?;

        if response.status().is_success() {
            response.json()
                .await
                .map_err(|e| format!("Failed to parse auth response: {}", e))
        } else {
            Err(format!("Authentication failed: {}", response.status()))
        }
    }

    pub async fn auth_with_oauth2(&self, provider: &str, code: &str, redirect_url: &str) -> Result<AuthToken, String> {
        let url = format!("{}/api/oauth2/auth-with-{}", self.base_url, provider);
        
        let response = self.client
            .post(&url)
            .json(&serde_json::json!({
                "code": code,
                "redirectUrl": redirect_url
            }))
            .send()
            .await
            .map_err(|e| format!("Failed to authenticate: {}", e))?;

        if response.status().is_success() {
            response.json()
                .await
                .map_err(|e| format!("Failed to parse auth response: {}", e))
        } else {
            Err(format!("Authentication failed: {}", response.status()))
        }
    }

    pub fn set_auth_token(&self, _token: &str) {
        // In a real implementation, you'd set the token on the client
        // For now, this is a placeholder
    }

    // ========================================
    // PRODUCTS & SERVICES
    // ========================================

    pub async fn get_products(&self) -> Result<Vec<Record>, String> {
        let url = format!("{}/api/collections/products_services/records", self.base_url);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to fetch products: {}", e))?;

        if response.status().is_success() {
            let result: serde_json::Value = response.json()
                .await
                .map_err(|e| format!("Failed to parse products: {}", e))?;

            // Extract items from the response
            if let Some(items) = result.get("items").and_then(|v| v.as_array()) {
                let products: Vec<Record> = items.iter()
                    .filter_map(|item| serde_json::from_value(item.clone()).ok())
                    .collect();
                Ok(products)
            } else {
                Ok(Vec::new())
            }
        } else {
            Err(format!("Failed to fetch products: {}", response.status()))
        }
    }

    pub async fn get_product_by_id(&self, id: &str) -> Result<Option<Record>, String> {
        let url = format!("{}/api/collections/products_services/records/{}", self.base_url, id);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to fetch product: {}", e))?;

        if response.status().is_success() {
            let record: Record = response.json()
                .await
                .map_err(|e| format!("Failed to parse product: {}", e))?;
            Ok(Some(record))
        } else if response.status().as_u16() == 404 {
            Ok(None)
        } else {
            Err(format!("Failed to fetch product: {}", response.status()))
        }
    }

    pub async fn search_products(&self, query: &str) -> Result<Vec<Record>, String> {
        let url = format!("{}/api/collections/products_services/records?filter=(name~\"{}\" || sku~\"{}\")", 
                         self.base_url, query, query);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to search products: {}", e))?;

        if response.status().is_success() {
            let result: serde_json::Value = response.json()
                .await
                .map_err(|e| format!("Failed to parse search results: {}", e))?;

            if let Some(items) = result.get("items").and_then(|v| v.as_array()) {
                let products: Vec<Record> = items.iter()
                    .filter_map(|item| serde_json::from_value(item.clone()).ok())
                    .collect();
                Ok(products)
            } else {
                Ok(Vec::new())
            }
        } else {
            Err(format!("Failed to search products: {}", response.status()))
        }
    }

    pub async fn get_categories(&self) -> Result<Vec<Record>, String> {
        let url = format!("{}/api/collections/categories/records", self.base_url);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to fetch categories: {}", e))?;

        if response.status().is_success() {
            let result: serde_json::Value = response.json()
                .await
                .map_err(|e| format!("Failed to parse categories: {}", e))?;

            if let Some(items) = result.get("items").and_then(|v| v.as_array()) {
                let categories: Vec<Record> = items.iter()
                    .filter_map(|item| serde_json::from_value(item.clone()).ok())
                    .collect();
                Ok(categories)
            } else {
                Ok(Vec::new())
            }
        } else {
            Err(format!("Failed to fetch categories: {}", response.status()))
        }
    }

    // ========================================
    // SALES
    // ========================================

    pub async fn create_sale(&self, sale_data: &SaleData) -> Result<Record, String> {
        let url = format!("{}/api/collections/sales/records", self.base_url);
        
        let response = self.client
            .post(&url)
            .json(sale_data)
            .send()
            .await
            .map_err(|e| format!("Failed to create sale: {}", e))?;

        if response.status().is_success() {
            response.json()
                .await
                .map_err(|e| format!("Failed to parse sale response: {}", e))
        } else {
            Err(format!("Failed to create sale: {}", response.status()))
        }
    }

    pub async fn create_sale_item(&self, item_data: &SaleItemData) -> Result<Record, String> {
        let url = format!("{}/api/collections/sale_items/records", self.base_url);
        
        let response = self.client
            .post(&url)
            .json(item_data)
            .send()
            .await
            .map_err(|e| format!("Failed to create sale item: {}", e))?;

        if response.status().is_success() {
            response.json()
                .await
                .map_err(|e| format!("Failed to parse sale item response: {}", e))
        } else {
            Err(format!("Failed to create sale item: {}", response.status()))
        }
    }

    pub async fn get_sales(&self, branch_code: &str) -> Result<Vec<Record>, String> {
        let url = format!("{}/api/collections/sales/records?filter=(branch_code=\"{}\")", 
                         self.base_url, branch_code);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to fetch sales: {}", e))?;

        if response.status().is_success() {
            let result: serde_json::Value = response.json()
                .await
                .map_err(|e| format!("Failed to parse sales: {}", e))?;

            if let Some(items) = result.get("items").and_then(|v| v.as_array()) {
                let sales: Vec<Record> = items.iter()
                    .filter_map(|item| serde_json::from_value(item.clone()).ok())
                    .collect();
                Ok(sales)
            } else {
                Ok(Vec::new())
            }
        } else {
            Err(format!("Failed to fetch sales: {}", response.status()))
        }
    }

    // ========================================
    // BRANCHES
    // ========================================

    pub async fn get_branches(&self) -> Result<Vec<Record>, String> {
        let url = format!("{}/api/collections/branches/records", self.base_url);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to fetch branches: {}", e))?;

        if response.status().is_success() {
            let result: serde_json::Value = response.json()
                .await
                .map_err(|e| format!("Failed to parse branches: {}", e))?;

            if let Some(items) = result.get("items").and_then(|v| v.as_array()) {
                let branches: Vec<Record> = items.iter()
                    .filter_map(|item| serde_json::from_value(item.clone()).ok())
                    .collect();
                Ok(branches)
            } else {
                Ok(Vec::new())
            }
        } else {
            Err(format!("Failed to fetch branches: {}", response.status()))
        }
    }

    pub async fn get_branch_by_code(&self, code: &str) -> Result<Option<Record>, String> {
        let url = format!("{}/api/collections/branches/records?filter=(code=\"{}\")", 
                         self.base_url, code);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to fetch branch: {}", e))?;

        if response.status().is_success() {
            let result: serde_json::Value = response.json()
                .await
                .map_err(|e| format!("Failed to parse branch: {}", e))?;

            if let Some(items) = result.get("items").and_then(|v| v.as_array()) {
                if let Some(first) = items.first() {
                    let branch: Record = serde_json::from_value(first.clone())
                        .map_err(|e| format!("Failed to parse branch: {}", e))?;
                    Ok(Some(branch))
                } else {
                    Ok(None)
                }
            } else {
                Ok(None)
            }
        } else {
            Err(format!("Failed to fetch branch: {}", response.status()))
        }
    }

    // ========================================
    // CHAIRS (BARBER CHAIRS)
    // ========================================

    pub async fn get_chairs(&self, branch_code: &str) -> Result<Vec<Record>, String> {
        let url = format!("{}/api/collections/chairs/records?filter=(branch_code=\"{}\")", 
                         self.base_url, branch_code);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to fetch chairs: {}", e))?;

        if response.status().is_success() {
            let result: serde_json::Value = response.json()
                .await
                .map_err(|e| format!("Failed to parse chairs: {}", e))?;

            if let Some(items) = result.get("items").and_then(|v| v.as_array()) {
                let chairs: Vec<Record> = items.iter()
                    .filter_map(|item| serde_json::from_value(item.clone()).ok())
                    .collect();
                Ok(chairs)
            } else {
                Ok(Vec::new())
            }
        } else {
            Err(format!("Failed to fetch chairs: {}", response.status()))
        }
    }

    pub async fn update_chair_status(&self, chair_id: &str, status: &str) -> Result<Record, String> {
        let url = format!("{}/api/collections/chairs/records/{}", self.base_url, chair_id);
        
        let response = self.client
            .patch(&url)
            .json(&serde_json::json!({
                "status": status
            }))
            .send()
            .await
            .map_err(|e| format!("Failed to update chair: {}", e))?;

        if response.status().is_success() {
            response.json()
                .await
                .map_err(|e| format!("Failed to parse chair update response: {}", e))
        } else {
            Err(format!("Failed to update chair: {}", response.status()))
        }
    }
}

// ========================================
// SALE DATA STRUCTURES
// ========================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SaleData {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub folio: Option<String>,
    pub branch_code: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub barber_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub client_name: Option<String>,
    pub subtotal: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub discount: Option<f64>,
    pub total: f64,
    pub payment_method: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cash_received: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub change_returned: Option<f64>,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SaleItemData {
    pub sale_folio: String,
    pub product_name: String,
    pub unit_price: f64,
    pub quantity: u32,
    pub total: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CartItemData {
    pub product_id: String,
    pub product_name: String,
    pub unit_price: f64,
    pub quantity: u32,
    pub total: f64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_backend_client_creation() {
        let client = BackendClient::new("http://localhost:8090");
        assert!(client.is_ok());
    }
}
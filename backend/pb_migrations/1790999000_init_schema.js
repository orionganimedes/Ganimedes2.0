/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // 1. Extend built-in 'users' collection with POS fields
  const usersCollection = app.findCollectionByNameOrId("_pb_users_auth_");
  if (usersCollection) {
    usersCollection.fields.add(new Field({
      name: "role",
      type: "select",
      values: ["admin", "master_barber", "senior_barber", "cashier"],
    }));
    usersCollection.fields.add(new Field({
      name: "pin",
      type: "text",
    }));
    usersCollection.fields.add(new Field({
      name: "chair",
      type: "text",
    }));
    usersCollection.fields.add(new Field({
      name: "shift",
      type: "text",
    }));
    usersCollection.fields.add(new Field({
      name: "branch_code",
      type: "text",
    }));
    usersCollection.fields.add(new Field({
      name: "is_active",
      type: "bool",
    }));
    usersCollection.listRule = "";
    usersCollection.viewRule = "";
    app.save(usersCollection);
  }

  // Helper to create collection with open API rules for POS
  const createCollection = (name, fields) => {
    const col = new Collection({
      name: name,
      type: "base",
      fields: fields,
      listRule: "",
      viewRule: "",
      createRule: "",
      updateRule: "",
      deleteRule: "",
    });
    app.save(col);
    return col;
  };

  // 2. Branches
  createCollection("branches", [
    { name: "name", type: "text", required: true },
    { name: "code", type: "text", required: true },
    { name: "address", type: "text" },
    { name: "phone", type: "text" },
    { name: "rfc", type: "text" },
    { name: "is_active", type: "bool" },
  ]);

  // 3. Categories
  createCollection("categories", [
    { name: "name", type: "text", required: true },
    { name: "slug", type: "text", required: true },
    { name: "order", type: "number" },
    { name: "is_service", type: "bool" },
  ]);

  // 4. Products & Services
  createCollection("products_services", [
    { name: "sku", type: "text", required: true },
    { name: "name", type: "text", required: true },
    { name: "subtitle", type: "text" },
    { name: "category_name", type: "text", required: true },
    { name: "price", type: "number", required: true },
    { name: "cost", type: "number" },
    { name: "is_service", type: "bool" },
    { name: "duration_minutes", type: "number" },
    { name: "stock", type: "number" },
    { name: "min_stock_alert", type: "number" },
    { name: "is_popular", type: "bool" },
    { name: "is_active", type: "bool" },
  ]);

  // 5. Barber Chairs (Realtime Status)
  createCollection("chairs", [
    { name: "chair_number", type: "text", required: true },
    { name: "status", type: "select", values: ["available", "in_service", "reserved"] },
    { name: "barber_name", type: "text" },
    { name: "client_name", type: "text" },
    { name: "service_name", type: "text" },
    { name: "branch_code", type: "text" },
  ]);

  // 6. Cash Shifts (Cortes de Caja / Arqueo)
  createCollection("cash_shifts", [
    { name: "branch_code", type: "text", required: true },
    { name: "shift_name", type: "text", required: true },
    { name: "operator_name", type: "text", required: true },
    { name: "status", type: "select", values: ["open", "closed"] },
    { name: "initial_cash", type: "number" },
    { name: "expected_cash", type: "number" },
    { name: "actual_cash", type: "number" },
    { name: "total_sales", type: "number" },
    { name: "cash_sales", type: "number" },
    { name: "card_sales", type: "number" },
    { name: "spei_sales", type: "number" },
    { name: "tickets_count", type: "number" },
    { name: "difference", type: "number" },
    { name: "opened_at", type: "date" },
    { name: "closed_at", type: "date" },
    { name: "notes", type: "text" },
  ]);

  // 7. Cash Movements (Entradas/Salidas de efectivo)
  createCollection("cash_movements", [
    { name: "type", type: "select", values: ["entry", "withdrawal"] },
    { name: "amount", type: "number", required: true },
    { name: "reason", type: "text", required: true },
    { name: "operator_name", type: "text" },
  ]);

  // 8. Sales (Tickets emitidos)
  createCollection("sales", [
    { name: "folio", type: "text", required: true },
    { name: "branch_code", type: "text" },
    { name: "barber_name", type: "text" },
    { name: "client_name", type: "text" },
    { name: "subtotal", type: "number" },
    { name: "discount", type: "number" },
    { name: "total", type: "number", required: true },
    { name: "payment_method", type: "select", values: ["cash", "card", "spei", "split"] },
    { name: "cash_received", type: "number" },
    { name: "change_returned", type: "number" },
    { name: "status", type: "select", values: ["completed", "pending", "cancelled"] },
  ]);

  // 9. Sale Items (Detalle de cada venta)
  createCollection("sale_items", [
    { name: "sale_folio", type: "text", required: true },
    { name: "product_name", type: "text", required: true },
    { name: "unit_price", type: "number", required: true },
    { name: "quantity", type: "number", required: true },
    { name: "total", type: "number", required: true },
  ]);

}, (app) => {
  const collections = [
    "sale_items",
    "sales",
    "cash_movements",
    "cash_shifts",
    "chairs",
    "products_services",
    "categories",
    "branches",
  ];
  for (const name of collections) {
    const col = app.findCollectionByNameOrId(name);
    if (col) {
      app.delete(col);
    }
  }
});

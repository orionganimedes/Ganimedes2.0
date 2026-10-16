/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // Cierra las reglas de API que estaban abiertas ("" = acceso público sin login).

  // --- Colección auth 'users' ---
  const users = app.findCollectionByNameOrId("users");
  if (users) {
    users.listRule = null;                        // solo superuser lista (evita enumerar emails)
    users.viewRule = "id = @request.auth.id";     // cada quien ve su propio registro
    users.createRule = null;                      // registro público deshabilitado (sign-up se habilitará después)
    users.updateRule = "id = @request.auth.id";   // auto-actualización (rol protegido por hook)
    users.deleteRule = null;                      // solo superuser elimina
    app.save(users);
  }

  // --- Colecciones de negocio: solo autenticados; borrado solo admin ---
  const business = [
    "branches",
    "categories",
    "products_services",
    "chairs",
    "cash_shifts",
    "cash_movements",
    "sales",
    "sale_items",
  ];
  for (const name of business) {
    const col = app.findCollectionByNameOrId(name);
    if (col) {
      col.listRule = "@request.auth.id != ''";
      col.viewRule = "@request.auth.id != ''";
      col.createRule = "@request.auth.id != ''";
      col.updateRule = "@request.auth.id != ''";
      col.deleteRule = "@request.auth.role = 'admin'";
      app.save(col);
    }
  }
}, (app) => {
  // Revertir: restaurar reglas abiertas.
  const business = [
    "branches", "categories", "products_services", "chairs",
    "cash_shifts", "cash_movements", "sales", "sale_items",
  ];
  for (const name of business) {
    const col = app.findCollectionByNameOrId(name);
    if (col) {
      col.listRule = ""; col.viewRule = ""; col.createRule = "";
      col.updateRule = ""; col.deleteRule = "";
      app.save(col);
    }
  }
  const users = app.findCollectionByNameOrId("users");
  if (users) {
    users.listRule = ""; users.viewRule = ""; users.createRule = "";
    users.updateRule = ""; users.deleteRule = "";
    app.save(users);
  }
});

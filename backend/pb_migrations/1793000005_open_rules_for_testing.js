/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // Modo PRUEBAS: abre todas las reglas de API para que la app Flutter
  // (que aún no envía token de autenticación en todas sus peticiones)
  // pueda registrarse y operar. La seguridad fina se re-aplicará después.
  const names = [
    "users",
    "branches",
    "categories",
    "products_services",
    "chairs",
    "cash_shifts",
    "cash_movements",
    "sales",
    "sale_items",
    "clients",
    "appointments",
    "ai_profiles",
  ];

  for (const name of names) {
    const col = app.findCollectionByNameOrId(name);
    if (col) {
      col.listRule = "";
      col.viewRule = "";
      col.createRule = "";
      col.updateRule = "";
      col.deleteRule = "";
      app.save(col);
    }
  }
}, (app) => {
  // No-op: esta migración deja las reglas abiertas para pruebas.
});

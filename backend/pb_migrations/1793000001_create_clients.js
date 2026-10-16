/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // Colección de clientes por negocio (tenant = business_name).
  const col = new Collection({
    name: "clients",
    type: "base",
    fields: [
      { name: "business_name", type: "text", required: true },
      { name: "name", type: "text", required: true },
      { name: "phone", type: "text" },
      { name: "email", type: "text" },
      { name: "notes", type: "text" },
      { name: "total_visits", type: "number" },
      { name: "total_spent", type: "number" },
      { name: "last_visit", type: "date" },
    ],
    listRule: "@request.auth.id != ''",
    viewRule: "@request.auth.id != ''",
    createRule: "@request.auth.id != ''",
    updateRule: "@request.auth.id != ''",
    deleteRule: "@request.auth.role = 'admin'",
  });
  app.save(col);
}, (app) => {
  const col = app.findCollectionByNameOrId("clients");
  if (col) app.delete(col);
});

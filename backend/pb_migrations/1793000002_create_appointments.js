/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // Colección de citas por negocio (tenant = business_name).
  const col = new Collection({
    name: "appointments",
    type: "base",
    fields: [
      { name: "business_name", type: "text", required: true },
      { name: "branch_code", type: "text" },
      { name: "client_name", type: "text", required: true },
      { name: "barber_name", type: "text" },
      { name: "service_name", type: "text" },
      { name: "date", type: "date" },
      { name: "time", type: "text" },
      { name: "status", type: "select", values: ["pending", "confirmed", "completed", "cancelled"] },
      { name: "notes", type: "text" },
    ],
    listRule: "@request.auth.id != ''",
    viewRule: "@request.auth.id != ''",
    createRule: "@request.auth.id != ''",
    updateRule: "@request.auth.id != ''",
    deleteRule: "@request.auth.role = 'admin'",
  });
  app.save(col);
}, (app) => {
  const col = app.findCollectionByNameOrId("appointments");
  if (col) app.delete(col);
});

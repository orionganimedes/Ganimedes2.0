/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // Perfil de "alimentación" de la IA por negocio (tenant = business_name).
  // Se llena desde la pantalla slide de la app al crear un usuario nuevo.
  const col = new Collection({
    name: "ai_profiles",
    type: "base",
    fields: [
      { name: "business_name", type: "text", required: true },
      { name: "business_type", type: "text" },
      { name: "services_summary", type: "text" },
      { name: "tone", type: "text" },
      { name: "special_instructions", type: "text" },
    ],
    listRule: "@request.auth.id != ''",
    viewRule: "@request.auth.id != ''",
    createRule: "@request.auth.id != ''",
    updateRule: "@request.auth.id != ''",
    deleteRule: "@request.auth.role = 'admin'",
  });
  app.save(col);
}, (app) => {
  const col = app.findCollectionByNameOrId("ai_profiles");
  if (col) app.delete(col);
});

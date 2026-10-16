/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  if (users) {
    // Permite listar usuarios del MISMO negocio (tenant) para que el agente
    // pueda ver a los barberos, sin exponer usuarios de otros negocios.
    users.listRule = "@request.auth.id != '' && business_name = @request.auth.business_name";
    app.save(users);
  }
}, (app) => {
  const users = app.findCollectionByNameOrId("users");
  if (users) {
    users.listRule = null;
    app.save(users);
  }
});

/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // Agrega el nombre del dueño al perfil de IA (pregunta inicial del onboarding).
  const col = app.findCollectionByNameOrId("ai_profiles");
  if (col && !col.fields.getByName("owner_name")) {
    col.fields.add(new Field({ name: "owner_name", type: "text" }));
    app.save(col);
  }
}, (app) => {
  const col = app.findCollectionByNameOrId("ai_profiles");
  if (col && col.fields.getByName("owner_name")) {
    col.fields.removeByName("owner_name");
    app.save(col);
  }
});

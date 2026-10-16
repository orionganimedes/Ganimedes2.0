/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // Aislamiento multi-tenant: agrega "business_name" a las colecciones que
  // guardan datos de un negocio específico. El agente filtra TODO por este campo.
  const collections = [
    "users",
    "chairs",
    "cash_shifts",
    "cash_movements",
    "sales",
    "sale_items",
  ];

  for (const name of collections) {
    const col = app.findCollectionByNameOrId(name);
    if (!col) continue;
    if (!col.fields.getByName("business_name")) {
      col.fields.add(new Field({ name: "business_name", type: "text" }));
      app.save(col);
    }
  }
}, (app) => {
  const collections = [
    "users",
    "chairs",
    "cash_shifts",
    "cash_movements",
    "sales",
    "sale_items",
  ];

  for (const name of collections) {
    const col = app.findCollectionByNameOrId(name);
    if (!col) continue;
    if (col.fields.getByName("business_name")) {
      col.fields.removeByName("business_name");
      app.save(col);
    }
  }
});

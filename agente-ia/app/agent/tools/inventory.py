"""Tool: inventario."""
from app.agent.tools.registry import register


async def _get_inventory_status(tenant, args, pb):
    category = args.get("category", "").strip()
    only_low_stock = args.get("only_low_stock", False)

    filters = [f'business_name = "{tenant}"']
    if category:
        filters.append(f'category_name = "{category}"')
    filter_str = " && ".join(filters)

    items, total = pb.list("products_services", tenant, filter=filter_str, sort="name")

    services = []
    products = []
    low_stock = []
    for p in items:
        name = p.get("name")
        price = p.get("price")
        cat = p.get("category_name")
        if p.get("is_service") is True:
            services.append({
                "name": name,
                "price": price,
                "category": cat,
                "duration_minutes": p.get("duration_minutes"),
            })
        else:
            stock = int(p.get("stock") or 0)
            min_stock = int(p.get("min_stock_alert") or 0)
            entry = {
                "name": name,
                "sku": p.get("sku"),
                "price": price,
                "category": cat,
                "stock": stock,
                "min_stock_alert": min_stock,
            }
            products.append(entry)
            if min_stock > 0 and stock <= min_stock:
                low_stock.append(entry)

    result_products = low_stock if only_low_stock else products
    result_services = [] if only_low_stock else services[:50]

    return {
        "total_catalog": total,
        "services": result_services,
        "products": result_products[:50],
        "low_stock_count": len(low_stock),
        "low_stock": low_stock,
    }


register(
    name="get_inventory_status",
    description="Lee el catálogo completo del negocio (servicios y productos) y detecta stock bajo.",
    parameters={
        "type": "object",
        "properties": {
            "category": {"type": "string", "description": "Categoría opcional para filtrar."},
            "only_low_stock": {"type": "boolean", "description": "Si es true, devuelve solo stock bajo."},
        },
        "required": [],
    },
    handler=_get_inventory_status,
)

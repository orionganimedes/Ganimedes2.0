"""Tool: inventario."""
from app.agent.tools.registry import register


async def _get_inventory_status(tenant, args, pb):
    # Lee TODO el catálogo (servicios + productos físicos) en modo lectura.
    items, total = pb.list("products_services", tenant, sort="name")

    services = []
    products = []
    low_stock = []
    for p in items:
        name = p.get("name")
        price = p.get("price")
        category = p.get("category_name")
        if p.get("is_service") is True:
            services.append({
                "name": name,
                "price": price,
                "category": category,
                "duration_minutes": p.get("duration_minutes"),
            })
        else:
            stock = int(p.get("stock") or 0)
            min_stock = int(p.get("min_stock_alert") or 0)
            entry = {
                "name": name,
                "sku": p.get("sku"),
                "price": price,
                "category": category,
                "stock": stock,
                "min_stock_alert": min_stock,
            }
            products.append(entry)
            if min_stock > 0 and stock <= min_stock:
                low_stock.append(entry)

    return {
        "total_catalog": total,
        "services": services[:50],
        "products": products[:50],
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

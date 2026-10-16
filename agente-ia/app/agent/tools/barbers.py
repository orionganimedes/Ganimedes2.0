"""Tool: barberos y rendimiento."""
from app.agent.tools.registry import register


async def _get_barber_stats(tenant, args, pb):
    barbers, _ = pb.list("users", tenant, filter='role != "admin"')
    sales, _ = pb.list("sales", tenant)

    stats: dict = {}
    for b in barbers:
        name = b.get("name") or b.get("email") or b.get("id")
        stats[name] = {"role": b.get("role"), "chair": b.get("chair"), "sales_count": 0, "total_mxn": 0.0}

    for s in sales:
        name = s.get("barber_name")
        if name in stats:
            stats[name]["sales_count"] += 1
            stats[name]["total_mxn"] += float(s.get("total") or 0)

    return {"barbers": {k: {**v, "total_mxn": round(v["total_mxn"], 2)} for k, v in stats.items()}}


register(
    name="get_barber_stats",
    description="Muestra los barberos del negocio y su rendimiento (ventas y total).",
    parameters={
        "type": "object",
        "properties": {
            "barber_name": {"type": "string", "description": "Nombre de barbero opcional para filtrar."},
        },
        "required": [],
    },
    handler=_get_barber_stats,
)

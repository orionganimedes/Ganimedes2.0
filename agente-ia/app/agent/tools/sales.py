"""Tool: reporte de ventas."""
from app.agent.tools.registry import register


async def _get_sales_report(tenant, args, pb):
    branch_code = args.get("branch_code")
    filters = [f'business_name = "{tenant}"']
    if branch_code:
        filters.append(f'branch_code = "{branch_code}"')
    filter_str = " && ".join(filters)

    period = args.get("period", "").strip().lower()
    if period:
        from datetime import datetime, timedelta, timezone
        now = datetime.now(timezone.utc)
        if period == "hoy":
            since = now.replace(hour=0, minute=0, second=0, microsecond=0)
        elif period == "7d":
            since = now - timedelta(days=7)
        elif period == "30d":
            since = now - timedelta(days=30)
        else:
            since = None
        if since is not None:
            since_str = since.strftime("%Y-%m-%d %H:%M:%S")
            filter_str += f' && created >= "{since_str}"'

    items, total = pb.list("sales", tenant, filter=filter_str, sort="-created")

    by_method: dict = {}
    total_amount = 0.0
    for s in items:
        amt = float(s.get("total") or 0)
        total_amount += amt
        m = s.get("payment_method") or "desconocido"
        by_method[m] = by_method.get(m, 0.0) + amt

    return {
        "total_tickets": total,
        "total_sales_mxn": round(total_amount, 2),
        "by_payment_method": {k: round(v, 2) for k, v in by_method.items()},
        "recent_tickets": [
            {
                "folio": s.get("folio"),
                "total": s.get("total"),
                "client": s.get("client_name"),
                "barber": s.get("barber_name"),
                "created": s.get("created"),
            }
            for s in items[:5]
        ],
    }


register(
    name="get_sales_report",
    description="Obtiene el reporte de ventas del negocio (totales, por método de pago y tickets recientes).",
    parameters={
        "type": "object",
        "properties": {
            "branch_code": {"type": "string", "description": "Código de sucursal opcional para filtrar."},
            "period": {"type": "string", "description": "Periodo opcional (ej. 'hoy', '7d', '30d')."},
        },
        "required": [],
    },
    handler=_get_sales_report,
)

"""Tool: reporte financiero y ganancias del día."""
from datetime import datetime, timezone

from app.agent.tools.registry import register


async def _generate_financial_report(tenant, args, pb):
    sales, _ = pb.list("sales", tenant)
    shifts, _ = pb.list("cash_shifts", tenant)

    total_sales = sum(float(s.get("total") or 0) for s in sales)
    by_method: dict = {}
    for s in sales:
        m = s.get("payment_method") or "desconocido"
        by_method[m] = by_method.get(m, 0.0) + float(s.get("total") or 0)

    open_shifts = [s for s in shifts if s.get("status") == "open"]

    return {
        "total_sales_mxn": round(total_sales, 2),
        "total_tickets": len(sales),
        "by_payment_method": {k: round(v, 2) for k, v in by_method.items()},
        "open_cash_shifts": len(open_shifts),
        "expected_cash_mxn": round(sum(float(s.get("expected_cash") or 0) for s in open_shifts), 2),
    }


register(
    name="generate_financial_report",
    description="Genera un reporte financiero: ventas totales, por método de pago y cortes de caja abiertos.",
    parameters={"type": "object", "properties": {}, "required": []},
    handler=_generate_financial_report,
)


async def _get_daily_earnings(tenant, args, pb):
    # Ventas de HOY (filtrando por la fecha de creación, en UTC).
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    ts = today_start.strftime("%Y-%m-%d %H:%M:%S")
    sales, _ = pb.list("sales", tenant, filter=f'created >= "{ts}"', sort="-created")

    total = 0.0
    cash_total = 0.0
    by_method: dict = {}
    for s in sales:
        amt = float(s.get("total") or 0)
        total += amt
        m = (s.get("payment_method") or "desconocido").lower()
        by_method[m] = by_method.get(m, 0.0) + amt
        if "cash" in m or "efectivo" in m:
            cash_total += amt

    shifts, _ = pb.list("cash_shifts", tenant)
    open_shifts = [s for s in shifts if s.get("status") == "open"]
    cash_in_drawer = sum(float(s.get("expected_cash") or 0) for s in open_shifts)

    return {
        "hoy_total_vendido_mxn": round(total, 2),
        "hoy_num_tickets": len(sales),
        "hoy_por_metodo_pago": {k: round(v, 2) for k, v in by_method.items()},
        "hoy_efectivo_mxn": round(cash_total, 2),
        "cortes_de_caja_abiertos": len(open_shifts),
        "efectivo_en_caja_estimado_mxn": round(cash_in_drawer, 2),
        "ultimas_ventas": [
            {"folio": s.get("folio"), "total": s.get("total"), "hora": s.get("created")}
            for s in sales[:5]
        ],
    }


register(
    name="get_daily_earnings",
    description="Revisa cuánto se ha vendido HOY (total, por método de pago y efectivo) y el estado de la caja.",
    parameters={"type": "object", "properties": {}, "required": []},
    handler=_get_daily_earnings,
)

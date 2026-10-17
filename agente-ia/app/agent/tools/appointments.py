"""Tool: citas."""
from app.agent.tools.registry import register


async def _list_appointments(tenant, args, pb):
    status = args.get("status")

    filters = [f'business_name = "{tenant}"']
    if status:
        filters.append(f'status = "{status}"')
    filter_str = " && ".join(filters)

    items, total = pb.list("appointments", tenant, filter=filter_str, sort="date")

    return {
        "total_appointments": total,
        "appointments": [
            {
                "client": a.get("client_name"),
                "barber": a.get("barber_name"),
                "service": a.get("service_name"),
                "date": a.get("date"),
                "time": a.get("time"),
                "status": a.get("status"),
            }
            for a in items[:50]
        ],
    }


register(
    name="list_appointments",
    description="Lista las citas del negocio, con filtro opcional por estado.",
    parameters={
        "type": "object",
        "properties": {
            "status": {
                "type": "string",
                "description": "Estado: pending, confirmed, completed o cancelled.",
            },
        },
        "required": [],
    },
    handler=_list_appointments,
)

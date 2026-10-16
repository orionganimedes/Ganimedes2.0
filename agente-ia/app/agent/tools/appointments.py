"""Tool: citas."""
from app.agent.tools.registry import register


async def _list_appointments(tenant, args, pb):
    status = args.get("status")
    filter = f'status = "{status}"' if status else ""

    items, total = pb.list("appointments", tenant, filter=filter, sort="date")

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

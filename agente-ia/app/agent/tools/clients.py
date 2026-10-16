"""Tool: clientes."""
from app.agent.tools.registry import register


async def _list_clients(tenant, args, pb):
    search = args.get("search")
    filter = f'name ~ "{search}"' if search else ""

    items, total = pb.list("clients", tenant, filter=filter, sort="-created")

    return {
        "total_clients": total,
        "clients": [
            {
                "name": c.get("name"),
                "phone": c.get("phone"),
                "email": c.get("email"),
                "total_visits": c.get("total_visits"),
                "total_spent": c.get("total_spent"),
                "last_visit": c.get("last_visit"),
            }
            for c in items[:50]
        ],
    }


register(
    name="list_clients",
    description="Lista los clientes del negocio, con opción de buscar por nombre.",
    parameters={
        "type": "object",
        "properties": {
            "search": {"type": "string", "description": "Texto para buscar por nombre."},
        },
        "required": [],
    },
    handler=_list_clients,
)

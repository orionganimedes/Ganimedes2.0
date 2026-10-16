"""Tool: sucursales."""
from app.agent.tools.registry import register


async def _list_branches(tenant, args, pb):
    items, total = pb.list("branches", tenant, sort="name")

    return {
        "total_branches": total,
        "branches": [
            {
                "name": b.get("name"),
                "code": b.get("code"),
                "address": b.get("address"),
                "phone": b.get("phone"),
                "is_active": b.get("is_active"),
            }
            for b in items
        ],
    }


register(
    name="list_branches",
    description="Lista las sucursales del negocio.",
    parameters={"type": "object", "properties": {}, "required": []},
    handler=_list_branches,
)

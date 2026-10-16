"""Construye el contexto del tenant (negocio) que se inyecta al prompt.

Para un modelo pequeño (qwen2.5:3b) el tool-calling dinámico no es fiable,
así que ejecutamos las tools de forma *eager*: su salida alimenta el contexto
que el modelo recibe junto con el prompt. Todas las consultas se filtran por
`business_name` (tenant).
"""
import json

from app.agent.tools.registry import execute_tool
from app.pocketbase.client import PocketBaseClient
from app.utils.logger import get_logger

log = get_logger("agent.context")

# (nombre de tool, etiqueta legible para el contexto)
_TOOL_SECTIONS = [
    ("list_branches", "Sucursales"),
    ("get_barber_stats", "Barberos y rendimiento"),
    ("get_sales_report", "Ventas"),
    ("generate_financial_report", "Financiero"),
    ("get_daily_earnings", "Ventas de hoy y caja"),
    ("get_inventory_status", "Inventario"),
    ("list_appointments", "Citas"),
    ("list_clients", "Clientes"),
]


async def build_tenant_context(pb: PocketBaseClient, tenant: str) -> str:
    sections: list[str] = []

    # Perfil de "alimentación" de la IA del negocio (se llena en la app al dar de alta)
    try:
        profiles, _ = pb.list("ai_profiles", tenant, per_page=1)
        if profiles:
            p = profiles[0]
            lines = []
            if p.get("owner_name"):
                lines.append(f"Dueño: {p['owner_name']}")
            if p.get("business_type"):
                lines.append(f"Giro: {p['business_type']}")
            if p.get("services_summary"):
                lines.append(f"Servicios: {p['services_summary']}")
            if p.get("tone"):
                lines.append(f"TONO OBLIGATORIO DE RESPUESTA: {p['tone']}")
            if p.get("special_instructions"):
                lines.append(f"Instrucciones del dueño: {p['special_instructions']}")
            profile_text = " | ".join(lines)
            sections.append(f"### Perfil del negocio (personalización obligatoria)\n{profile_text}")
    except Exception as exc:
        log.warning("no se pudo leer ai_profiles: %s", exc)

    for name, label in _TOOL_SECTIONS:
        try:
            result = await execute_tool(name, {}, tenant=tenant, pb=pb)
        except Exception as exc:
            log.warning("tool '%s' falló al construir contexto: %s", name, exc)
            continue

        if isinstance(result, dict) and "error" in result:
            continue

        sections.append(f"### {label}\n{json.dumps(result, ensure_ascii=False, default=str)}")

    if not sections:
        return f"Contexto del negocio (tenant): {tenant} (aún sin datos)."

    return "Datos actuales del negocio:\n\n" + "\n\n".join(sections)

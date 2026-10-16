"""Registro de tools del agente.

Cada tool se registra con su esquema JSON (para Ollama) y su handler.
El handler recibe SIEMPRE el `tenant` y el cliente `pb`, de modo que no
puede leer datos fuera del negocio actual.
"""
from dataclasses import dataclass
from typing import Any, Awaitable, Callable

from app.pocketbase.client import PocketBaseClient

Handler = Callable[..., Awaitable[Any]]


@dataclass
class Tool:
    name: str
    description: str
    parameters: dict
    handler: Handler


_REGISTRY: dict[str, Tool] = {}


def register(name: str, description: str, parameters: dict, handler: Handler) -> None:
    _REGISTRY[name] = Tool(name=name, description=description, parameters=parameters, handler=handler)


def get_tools() -> list[dict]:
    """Devuelve las tools en el formato que espera la API de Ollama."""
    return [
        {
            "type": "function",
            "function": {
                "name": t.name,
                "description": t.description,
                "parameters": t.parameters,
            },
        }
        for t in _REGISTRY.values()
    ]


def list_tools() -> list[dict]:
    """Devuelve la lista legible de tools (para el panel/API)."""
    return [
        {"name": t.name, "description": t.description, "parameters": t.parameters}
        for t in _REGISTRY.values()
    ]


async def execute_tool(name: str, args: dict, tenant: str, pb: PocketBaseClient) -> dict:
    tool = _REGISTRY.get(name)
    if not tool:
        return {"error": f"Tool '{name}' no existe"}

    try:
        result = await tool.handler(tenant=tenant, args=args or {}, pb=pb)
        return result if isinstance(result, dict) else {"result": result}
    except Exception as exc:  # no romper el loop del agente por un error de tool
        return {"error": f"Error ejecutando '{name}': {exc}"}

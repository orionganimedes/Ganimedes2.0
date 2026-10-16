"""Orquestador principal del agente.

Flujo:
1. Construye el system prompt + contexto completo del tenant (datos reales
   de PocketBase, obtenidos ejecutando las tools de forma *eager*).
2. Llama una sola vez al LLM con ese contexto (sin tool-calling dinámico,
   que no es fiable en modelos pequeños como qwen2.5:3b).
3. Devuelve la respuesta final.

Nota: si en el futuro se usa un modelo mayor (qwen2.5:7b+), se puede re-activar
el tool-calling dinámico usando `app/agent/tools/registry.get_tools()`.
"""
from app.agent.context.builder import build_tenant_context
from app.agent.llm import llm
from app.pocketbase.client import PocketBaseClient
from app.utils.logger import get_logger

log = get_logger("agent.orchestrator")


async def run_agent(
    *,
    tenant: str,
    user_id: str,
    message: str,
    history: list[dict],
    pb: PocketBaseClient,
    system_prompt: str,
) -> dict:
    context = await build_tenant_context(pb, tenant)
    system = f"{system_prompt}\n\n{context}"

    messages: list[dict] = [{"role": "system", "content": system}]
    messages.extend(history or [])
    messages.append({"role": "user", "content": message})

    try:
        resp = llm.chat(messages)
    except Exception as exc:
        log.error("Error llamando a Ollama: %s", exc)
        return {"reply": "Lo siento, no pude conectar con el modelo de IA.", "tool_calls": []}

    reply = (resp.get("message", {}).get("content") or "").strip()
    return {"reply": reply, "tool_calls": []}


def stream_agent(
    *,
    message: str,
    history: list[dict],
    system_prompt: str,
    context: str,
):
    """Generador síncrono que emite tokens (palabra por palabra) del agente."""
    system = f"{system_prompt}\n\n{context}"
    messages: list[dict] = [{"role": "system", "content": system}]
    messages.extend(history or [])
    messages.append({"role": "user", "content": message})

    for chunk in llm.chat_stream(messages):
        token = (chunk.get("message") or {}).get("content") or ""
        if token:
            yield token

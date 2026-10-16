"""Rutas del agente (chat, tools, prompt)."""
import json

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from app.agent.context.builder import build_tenant_context
from app.agent.context.prompt import get_system_prompt, set_system_prompt
from app.agent.memory.conversation import memory
from app.agent.orchestrator import run_agent, stream_agent
from app.agent.tools.registry import list_tools
from app.api.deps import get_admin, get_pb
from app.config import settings
from app.pocketbase.auth import get_tenant
from app.pocketbase.client import PocketBaseClient

router = APIRouter()


class ChatRequest(BaseModel):
    message: str
    history: list[dict] | None = None


class PromptUpdate(BaseModel):
    prompt: str


@router.get("/health")
def health():
    return {"status": "ok", "model": settings.OLLAMA_MODEL}


@router.get("/tools")
def tools():
    return {"tools": list_tools()}


@router.get("/prompt")
def get_prompt():
    return {"prompt": get_system_prompt()}


@router.post("/prompt")
def update_prompt(body: PromptUpdate):
    set_system_prompt(body.prompt)
    return {"ok": True}


@router.post("/chat")
async def chat(
    req: ChatRequest,
    admin: dict = Depends(get_admin),
    pb: PocketBaseClient = Depends(get_pb),
):
    tenant = get_tenant(admin)
    user_id = admin.get("id", "anon")

    history = req.history or memory.get(user_id)

    result = await run_agent(
        tenant=tenant,
        user_id=user_id,
        message=req.message,
        history=history,
        pb=pb,
        system_prompt=get_system_prompt(),
    )

    memory.add(user_id, "user", req.message)
    memory.add(user_id, "assistant", result["reply"])

    return result


@router.post("/chat/stream")
async def chat_stream(
    req: ChatRequest,
    admin: dict = Depends(get_admin),
    pb: PocketBaseClient = Depends(get_pb),
):
    tenant = get_tenant(admin)
    user_id = admin.get("id", "anon")
    history = req.history or memory.get(user_id)
    context = await build_tenant_context(pb, tenant)
    system_prompt = get_system_prompt()

    def generate():
        full = ""
        try:
            for token in stream_agent(
                message=req.message,
                history=history,
                system_prompt=system_prompt,
                context=context,
            ):
                full += token
                yield f"data: {json.dumps({'token': token, 'done': False}, ensure_ascii=False)}\n\n"
        except Exception as exc:
            yield f"data: {json.dumps({'error': str(exc), 'done': True}, ensure_ascii=False)}\n\n"
            return
        memory.add(user_id, "user", req.message)
        memory.add(user_id, "assistant", full)
        yield f"data: {json.dumps({'done': True}, ensure_ascii=False)}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")

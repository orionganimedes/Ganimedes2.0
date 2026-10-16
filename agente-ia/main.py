"""Punto de entrada de Ganimedes Agent (FastAPI)."""
from fastapi import FastAPI

from app.api.middleware import setup_middlewares
from app.api.routes import agent as agent_routes
from app.config import settings

app = FastAPI(
    title="Ganimedes Agent",
    description="Agente de IA multi-tenant para Ganimedes POS (lee PocketBase).",
    version="0.1.0",
)

setup_middlewares(app)
app.include_router(agent_routes.router, prefix="/api/agent")


@app.get("/")
def root():
    return {"service": "Ganimedes Agent", "status": "ok", "model": settings.OLLAMA_MODEL}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=settings.AGENT_PORT, reload=False)

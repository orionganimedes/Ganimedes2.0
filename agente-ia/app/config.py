"""Configuración central de Ganimedes Agent."""
import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent  # .../ganimedes-agent/app

# Cargar .env desde la raíz del proyecto
load_dotenv(BASE_DIR.parent / ".env")


class Settings:
    # PocketBase (base de datos multi-tenant)
    POCKETBASE_URL: str = os.getenv("POCKETBASE_URL", "http://localhost:8090").rstrip("/")

    # Ollama (motor LLM, Qwen2.5)
    OLLAMA_URL: str = os.getenv("OLLAMA_URL", "http://localhost:11434").rstrip("/")
    OLLAMA_MODEL: str = os.getenv("OLLAMA_MODEL", "qwen2.5:3b")

    # Servidor del agente
    AGENT_PORT: int = int(os.getenv("AGENT_PORT", "8000"))

    # Orquestador
    MAX_TOOL_ROUNDS: int = int(os.getenv("MAX_TOOL_ROUNDS", "6"))

    # System prompt (único). admin.md es editable para "entrenar" al agente.
    PROMPT_FILE: Path = Path(
        os.getenv("PROMPT_FILE", str(BASE_DIR / "agent" / "context" / "prompts" / "admin.md"))
    )
    # Archivo donde persiste un override del prompt (montado como volumen en Docker).
    PROMPT_OVERRIDE_FILE: Path = Path(
        os.getenv("PROMPT_OVERRIDE_FILE", str(BASE_DIR / ".." / "data" / "system_prompt.md"))
    )

    # CORS (panel frontend)
    CORS_ORIGINS: list = [
        o.strip() for o in os.getenv("CORS_ORIGINS", "*").split(",") if o.strip()
    ]


settings = Settings()

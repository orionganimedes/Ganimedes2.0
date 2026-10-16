"""Gestión del system prompt (editable para "entrenar" al agente)."""
import threading
from typing import Optional

from app.config import settings

_override: Optional[str] = None
_lock = threading.Lock()


def get_system_prompt() -> str:
    """Devuelve el prompt actual: override en memoria > override en disco > admin.md."""
    with _lock:
        if _override is not None:
            return _override

    # Override persistido en el volumen (sobrevive reinicios)
    if settings.PROMPT_OVERRIDE_FILE.exists():
        try:
            return settings.PROMPT_OVERRIDE_FILE.read_text(encoding="utf-8").strip()
        except Exception:
            pass

    if settings.PROMPT_FILE.exists():
        return settings.PROMPT_FILE.read_text(encoding="utf-8").strip()

    return "Eres un asistente del negocio."


def set_system_prompt(text: str) -> str:
    global _override
    text = text.strip()
    with _lock:
        _override = text
        try:
            settings.PROMPT_OVERRIDE_FILE.parent.mkdir(parents=True, exist_ok=True)
            settings.PROMPT_OVERRIDE_FILE.write_text(text, encoding="utf-8")
        except Exception:
            pass
    return text


def reset_system_prompt() -> str:
    global _override
    with _lock:
        _override = None
    return get_system_prompt()

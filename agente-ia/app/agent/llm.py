"""Cliente de Ollama (Qwen2.5) con soporte de tool-calling."""
import json
from typing import Any, Optional

import httpx

from app.config import settings
from app.utils.logger import get_logger

log = get_logger("agent.llm")


class OllamaLLM:
    def __init__(self):
        self.url = settings.OLLAMA_URL
        self.model = settings.OLLAMA_MODEL

    def chat(self, messages: list[dict], tools: Optional[list[dict]] = None) -> dict:
        payload: dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "stream": False,
        }
        if tools:
            payload["tools"] = tools

        r = httpx.post(f"{self.url}/api/chat", json=payload, timeout=300)
        r.raise_for_status()
        return r.json()

    def chat_stream(self, messages: list[dict]):
        """Chat con streaming: emite chunks JSON (palabra por palabra)."""
        payload: dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "stream": True,
        }
        with httpx.stream(
            "POST", f"{self.url}/api/chat", json=payload, timeout=300
        ) as r:
            r.raise_for_status()
            for line in r.iter_lines():
                if not line.strip():
                    continue
                try:
                    yield json.loads(line)
                except json.JSONDecodeError:
                    continue


llm = OllamaLLM()

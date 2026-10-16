"""Memoria conversacional simple (en memoria, por usuario).

Para producción esto debería respaldarse en PocketBase o Redis; aquí es
suficiente para el panel de entrenamiento y pruebas.
"""
from collections import defaultdict, deque


class ConversationMemory:
    def __init__(self, max_messages: int = 20):
        self.max_messages = max_messages
        self._store: dict[str, deque] = defaultdict(lambda: deque(maxlen=max_messages))

    def get(self, user_id: str) -> list[dict]:
        return list(self._store[user_id])

    def add(self, user_id: str, role: str, content: str) -> None:
        self._store[user_id].append({"role": role, "content": content})

    def clear(self, user_id: str) -> None:
        self._store.pop(user_id, None)


memory = ConversationMemory()

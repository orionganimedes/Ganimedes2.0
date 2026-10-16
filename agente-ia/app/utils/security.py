"""Utilidades de seguridad: extracción de tokens."""
from typing import Optional


def extract_token(authorization: Optional[str]) -> Optional[str]:
    """Extrae el token de un header Authorization.

    Acepta tanto el formato de PocketBase ("Authorization: <token>")
    como el de Bearer ("Authorization: Bearer <token>").
    """
    if not authorization:
        return None
    if authorization.lower().startswith("bearer "):
        return authorization[7:].strip()
    return authorization.strip()

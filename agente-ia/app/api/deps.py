"""Dependencias de FastAPI: extraer token, validar admin y tenant."""
from typing import Optional

from fastapi import Depends, Header, HTTPException, status

from app.config import settings
from app.pocketbase.auth import require_admin
from app.pocketbase.client import PocketBaseClient
from app.utils.security import extract_token


def get_token(authorization: Optional[str] = Header(default=None)) -> str:
    token = extract_token(authorization)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token requerido"
        )
    return token


def get_admin(token: str = Depends(get_token)) -> dict:
    return require_admin(token)


def get_pb(token: str = Depends(get_token)) -> PocketBaseClient:
    """Cliente PocketBase que actúa con el token del usuario."""
    return PocketBaseClient(settings.POCKETBASE_URL, token=token)

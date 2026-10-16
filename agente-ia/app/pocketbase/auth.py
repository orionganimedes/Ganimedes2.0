"""Autenticación contra PocketBase: validar JWT y verificar rol admin.

El agente recibe el token del usuario (emitido por PocketBase al hacer login
desde la app Flutter o el panel). Lo valida llamando a `auth-refresh`, que
devuelve el registro del usuario, y de ahí extrae el `business_name` (tenant).
"""
import httpx
from fastapi import HTTPException, status

from app.config import settings
from app.utils.logger import get_logger

log = get_logger("pocketbase.auth")


def validate_token(token: str) -> dict:
    """Valida el JWT del usuario en PocketBase y devuelve su registro."""
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token requerido")

    try:
        r = httpx.post(
            f"{settings.POCKETBASE_URL}/api/collections/users/auth-refresh",
            headers={"Authorization": token},
            timeout=10,
        )
    except httpx.RequestError as exc:
        log.error("PocketBase no disponible: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Base de datos no disponible",
        )

    if r.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido o expirado"
        )

    return r.json().get("record", {})


def require_admin(token: str) -> dict:
    """Valida el token y exige rol 'admin'. Devuelve el registro del admin."""
    record = validate_token(token)
    if record.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Se requiere rol admin"
        )
    return record


def get_tenant(admin_record: dict) -> str:
    """Extrae el tenant (business_name) del registro del admin."""
    tenant = admin_record.get("business_name") or ""
    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tu usuario no tiene un negocio (business_name) asignado",
        )
    return tenant

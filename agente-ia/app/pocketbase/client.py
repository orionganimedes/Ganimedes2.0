"""Cliente PocketBase (REST) con aislamiento multi-tenant.

Toda consulta de datos del negocio se filtra SIEMPRE por `business_name`
(tenant). Este filtro se inyecta de forma central para que ninguna tool
pueda leer datos de otro negocio por descuido.
"""
from typing import Any, Optional

import httpx

from app.utils.logger import get_logger

log = get_logger("pocketbase.client")


def _escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


class PocketBaseClient:
    def __init__(self, base_url: str, token: Optional[str] = None):
        self.base_url = base_url.rstrip("/")
        self.token = token

    def _headers(self) -> dict:
        h = {"Content-Type": "application/json"}
        if self.token:
            h["Authorization"] = self.token
        return h

    def _tenant_filter(self, tenant: Optional[str]) -> Optional[str]:
        if not tenant:
            return None
        return f'business_name = "{_escape(tenant)}"'

    def list(
        self,
        collection: str,
        tenant: Optional[str] = None,
        filter: str = "",
        sort: str = "",
        per_page: int = 500,
    ) -> tuple[list[dict], int]:
        """Lista registros de una colección, filtrados por tenant (si aplica).

        Devuelve (items, totalItems).
        """
        filters = []
        tenant_f = self._tenant_filter(tenant)
        if tenant_f:
            filters.append(tenant_f)
        if filter:
            filters.append(filter)

        params: dict[str, Any] = {"perPage": per_page}
        if filters:
            params["filter"] = " && ".join(filters)
        if sort:
            params["sort"] = sort

        r = httpx.get(
            f"{self.base_url}/api/collections/{collection}/records",
            params=params,
            headers=self._headers(),
            timeout=30,
        )
        r.raise_for_status()
        data = r.json()
        return data.get("items", []), data.get("totalItems", 0)

    def request(
        self,
        method: str,
        path: str,
        *,
        json: Optional[dict] = None,
        token: Optional[str] = None,
        timeout: int = 30,
    ) -> httpx.Response:
        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = token
        return httpx.request(
            method, f"{self.base_url}{path}", json=json, headers=headers, timeout=timeout
        )

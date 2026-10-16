# Ganimedes Agent — Arquitectura

## Servicios (separación de responsabilidades)

```
[App Flutter] ──┐
[Panel web]  ───┼──► ganimedes-agent (FastAPI :8000) ──► Ollama (Qwen2.5 :11434)
                │              │
                │              └──► PocketBase (:8090)  ← datos multi-tenant
                │
                └──► PocketBase (:8090)  (login/CRUD directo)
```

- **PocketBase** = base de datos + autenticación. No sabe nada de IA.
- **Ollama** = motor del modelo (Qwen2.5). Solo local (127.0.0.1:11434).
- **ganimedes-agent** = API FastAPI que orquesta al LLM + tools que leen PocketBase.
- **Panel web** (React) = frontend de entrenamiento (chat + edición de prompt).

## Aislamiento multi-tenant

- El **tenant** es el campo `business_name` presente en todas las colecciones de negocio.
- Un **admin** tiene asignado un `business_name`; el agente filtra **toda** consulta
  por `business_name = <tenant del admin>`.
- El filtro se inyecta de forma central en `app/pocketbase/client.py`, por lo que
  ninguna tool puede leer datos de otro negocio por descuido.

## Flujo de una petición de chat

1. El cliente envía `POST /api/agent/chat` con el token JWT de PocketBase.
2. `auth.py` valida el token vía `auth-refresh` y exige rol `admin`.
3. Se extrae el `business_name` (tenant) del registro del admin.
4. `context/builder.py` ejecuta las tools de forma **eager** y arma un resumen
   completo del negocio (sucursales, ventas, inventario, citas, clientes...).
5. `orchestrator.py` hace **una sola llamada** al LLM con ese contexto (sin
   tool-calling dinámico, que no es fiable en modelos pequeños como qwen2.5:3b).
6. Se devuelve la respuesta final.

## Tools

Cada tool vive en `app/agent/tools/<nombre>.py` y se registra con:
- nombre, descripción y esquema JSON (para Ollama),
- un handler `async (tenant, args, pb)` que consulta PocketBase filtrado por tenant.

Tools: ventas, citas, inventario, clientes, barberos, sucursales, reportes.

## Entrenamiento (panel)

- `GET  /api/agent/prompt` → devuelve el system prompt actual.
- `POST /api/agent/prompt` → actualiza el system prompt (persistido en el volumen `agent_data`).
- `GET  /api/agent/tools`  → lista las tools disponibles.

## Despliegue

- El agente corre en Docker con `network_mode: host` para alcanzar Ollama y
  PocketBase (que corren como servicios systemd del host).
- El panel web se sirve aparte (Vite build + cualquier servidor estático/Nginx).

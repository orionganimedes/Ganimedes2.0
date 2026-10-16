# 🧠 Memoria del trabajo — Ganimedes (agente IA + PocketBase + panel)

> Documento de memoria del proyecto realizado. Registra **qué** se hizo,
> **cómo** se hizo y **por qué**, para poder retomar o reproducir todo.

**Fecha:** 2026-10-05
**Entorno:** VPS Ubuntu `37.60.242.14` (hostname `vmi3328062`, Contabo) + workspace local.

---

## 1. Objetivo

Montar sobre el VPS una plataforma para **Ganimedes Barbería** con tres piezas
separadas y una app Flutter que vendrá después:

1. **PocketBase** — base de datos + autenticación (multi-tenant).
2. **ganimedes-agent** — API FastAPI con un agente de IA (Qwen2.5 vía Ollama)
   que lee los datos de PocketBase.
3. **ganimedes-panel** — frontend web (React) para chatear y "entrenar" al agente.

Requisito central: **aislamiento multi-tenant** — cada admin trabaja solo con
los datos de su negocio.

---

## 2. Contexto inicial (estado al empezar)

- **VPS** ya tenía corriendo:
  - Ollama en `127.0.0.1:11434` (modelos `qwen2.5:3b` y `ganimedes-copilot`).
  - Un agente Node.js/Express en `~/ganimedes-workspace/backend/api` (puerto 3000, parado).
  - `ufw` inactivo. Solo puerto 22 (SSH) expuesto. Docker NO instalado.
- **backend.zip** (subido por el usuario): PocketBase `v0.25.9` con 9 colecciones
  (`branches`, `users`, `categories`, `products_services`, `chairs`,
  `cash_shifts`, `cash_movements`, `sales`, `sale_items`), datos de prueba y
  **reglas de API abiertas** (cualquiera podía leer/escribir todo).

---

## 3. Cronología del trabajo (fases)

### Fase 1 — Análisis
- Conexión SSH al VPS (`ganimedes@37.60.242.14`, pass `190594`).
- Análisis del VPS: Ollama corriendo, agente Node parado, puertos.
- Análisis del `backend.zip`: PocketBase, esquema, datos y reglas abiertas.

### Fase 2 — Contenedorización del backend PocketBase
- Creé `Dockerfile`, `docker-compose.yml`, `docker-entrypoint.sh`,
  `.dockerignore` y `.env.example` para PocketBase.
- El entrypoint: `migrate up` → `superuser upsert` (desde env) → `serve`.
- Datos fuera de la imagen (volumen `pb_data`).

### Fase 3 — Limpieza de datos + seguridad (a petición del usuario)
- Eliminé: 3 usuarios (William M., William c., Diana B.), 7 sucursales,
  productos/servicios, ventas y detalle de ventas de prueba.
- Conservé las 5 categorías (catálogo base).
- Creé el admin de pruebas `prueba@ganimedes.com` (rol `admin`).
- Apliqué seguridad:
  - Reglas de API cerradas (colecciones de negocio: solo autenticados; borrado solo admin).
  - `users`: lista solo superuser, cada quien ve/edita su propio registro, registro público deshabilitado.
  - Hash de PIN (SHA-256) con hook JS.
  - Folios de venta auto-generados con hook JS.
  - Protección de rol (un usuario no se auto-asigna `admin`).
  - Limpieza de migraciones (eliminé una huérfana y auto-generadas).

### Fase 4 — Despliegue de PocketBase al VPS
- Subí `ganimedes-backend/` a `~/ganimedes-backend`.
- Creé servicio **systemd** `pocketbase.service` (User=ganimedes, puerto 8090).
- Verifiqué acceso externo (Contabo no bloquea el 8090).

### Fase 5 — Modelo multi-tenant (migraciones)
- Migraciones nuevas en `ganimedes-backend/pb_migrations/`:
  - `1793000000_add_tenant_fields.js` — agrega `business_name` a users, chairs,
    cash_shifts, cash_movements, sales, sale_items.
  - `1793000001_create_clients.js` — colección `clients`.
  - `1793000002_create_appointments.js` — colección `appointments`.
  - `1793000003_tenant_list_users.js` — `users.listRule` por tenant.
- Sembré datos de prueba del tenant `ganimedes` (1 sucursal, 3 productos,
  1 cliente, 1 cita, 1 venta con 2 líneas).

### Fase 6 — Construcción del agente (FastAPI) y del panel (React)
- Creé `ganimedes-agent/` (FastAPI) siguiendo la estructura pedida:
  - `app/pocketbase/` (cliente REST con filtro central por tenant + auth JWT).
  - `app/agent/` (llm, orchestrator, context/builder, tools, memory).
  - 7 tools: ventas, citas, inventario, clientes, barberos, sucursales, reportes.
  - `app/api/` (rutas chat/tools/prompt, deps, middleware).
  - `Dockerfile`, `docker-compose.yml` (network_mode: host).
- Creé `ganimedes-panel/` (React + Vite): login, chat y editor de prompt.

### Fase 7 — Despliegue completo en el VPS
- Instalé Docker en el VPS (script `get.docker.com`).
- Desplegué `ganimedes-agent` (contenedor, puerto 8000, network host).
- Desplegué `ganimedes-panel` (contenedor nginx, puerto 80).
- Verifiqué todo end-to-end (login → agente → Ollama → PocketBase).

---

## 4. Arquitectura final

```
[Panel web] :80 ──────┐
[App Flutter] (futuro)┼──► ganimedes-agent :8000 ──► Ollama :11434 (local)
                       │         │
                       │         └──► PocketBase :8090  (datos multi-tenant)
                       └──► PocketBase :8090  (login/CRUD directo)
```

| Servicio | Tecnología | Puerto | Despliegue |
|---|---|---|---|
| Panel | React + Vite (nginx) | 80 | Docker `ganimedes-panel` |
| Agente | FastAPI | 8000 | Docker `ganimedes-agent` (network host) |
| Base de datos | PocketBase | 8090 | systemd `pocketbase` |
| LLM | Ollama (Qwen2.5) | 11434 local | systemd (ya existía) |

**Multi-tenant:** el tenant es el campo `business_name`. El agente filtra TODA
consulta por `business_name = <tenant del admin>` de forma central en
`app/pocketbase/client.py`.

---

## 5. Decisiones técnicas (y por qué)

1. **Contexto "eager" en vez de tool-calling dinámico.** Qwen2.5:3b **no hace
   tool-calling fiable** (lo probé directo: pide datos en lugar de llamar la
   tool). Solución: las 7 tools se ejecutan siempre y su salida se inyecta al
   prompt; el modelo responde de ahí. Las tools siguen en código; si se sube a
   `qwen2.5:7b+`, se puede re-activar el tool-calling dinámico.
2. **Multi-tenant por `business_name`** (campo ya existente en branches/products),
   replicado a las demás colecciones. Más simple que crear un `tenant_id`.
3. **PocketBase por systemd** (rápido, sin Docker) y **agente/panel por Docker**
   (aislamiento y reproducibilidad).
4. **`network_mode: host` en el agente** para que alcance Ollama y PocketBase
   del host sin configurar redes extra.
5. **Reglas de API cerradas** (autenticado) + hash de PIN + folios automáticos.

---

## 6. Metodología de trabajo (cómo trabajé)

- **Conexión:** `sshpass` + `ssh -F /dev/null` (por el bug de permisos del
  `ssh_config` local) y `echo '190594' | sudo -S` para comandos root.
- **Verificar antes de actuar:** consulté el `types.d.ts` de PocketBase para
  confirmar la API exacta de hooks/migraciones; `jq` para parsear JSON.
- **Probar en copia antes de producción:** las migraciones se probaron en
  `/tmp/pb-test` (copia de la base) antes de subirlas al VPS.
- **Desplegar incremental y verificar cada paso:** subir → reiniciar → probar
  health → probar funcionalidad.
- **Diagnosticar por logs:** `docker logs`, `journalctl`, `curl` directo a
  Ollama para aislar el problema.

---

## 7. Problemas encontrados y soluciones

| Problema | Solución |
|---|---|
| `Bad owner or permissions on /etc/ssh/ssh_config.d/...` | usar `ssh -F /dev/null` |
| Reglas de API abiertas en PocketBase | migración `1792000000_security_rules.js` |
| Password de PocketBase exige mínimo 8 chars | admin con password `prueba1234` (no `1234`) |
| `users.listRule = null` daba 403 al agente | regla por tenant (`business_name = @request.auth.business_name`) |
| Qwen2.5:3b no hace tool-calling | contexto eager |
| Migraciones auto-generadas al hacer PATCH vía API | eliminarlas + `migrate history-sync` |
| `sqlite3` no instalado en el VPS | verificar vía API REST de PocketBase |

---

## 8. Credenciales y accesos ⚠️

> Cambiar antes de producción.

| Recurso | Usuario | Contraseña |
|---|---|---|
| SSH/sudo VPS | `ganimedes` | `190594` |
| PocketBase superusuario | `admin@ganimedes.com` | `Ganimedes2026!` |
| App admin (tenant `ganimedes`) | `prueba@ganimedes.com` | `prueba1234` (PIN `1234`) |

**URLs:** Panel `http://37.60.242.14/` · Agente `http://37.60.242.14:8000/api/agent/` ·
PocketBase `http://37.60.242.14:8090` (API `/api/`, admin `/_/`).

---

## 9. Estado actual (qué está corriendo)

- Contenedores: `ganimedes-agent` (8000), `ganimedes-panel` (80).
- systemd: `pocketbase` (8090), `ollama` (11434).
- Datos del tenant `ganimedes`: 1 sucursal, 3 productos/servicios, 1 cliente,
  1 cita, 1 venta, 2 líneas de venta.

### Comandos de gestión
```bash
# PocketBase
sudo systemctl status/restart pocketbase
journalctl -u pocketbase -f

# Docker
docker ps
docker logs -f ganimedes-agent
docker logs -f ganimedes-panel
cd ~/ganimedes-agent && docker compose up -d --build   # reconstruir agente
cd ~/ganimedes-panel && docker compose up -d --build   # reconstruir panel
```

---

## 10. Pendientes (siguientes pasos)

1. **Onboarding de admin**: al darse de alta un admin, crear automáticamente su
   negocio/sucursal (`business_name`) y que su agente trabaje sobre ese tenant.
2. **Seguridad a nivel DB**: extender el filtro por `business_name` a TODAS las
   colecciones en las reglas de PocketBase (hoy solo `users` lo tiene; el resto
   lo filtra el agente en código).
3. **HTTPS** con dominio/subdominio (DuckDNS) cuando salga de pruebas.
4. **Modelo más grande** (qwen2.5:7b+) para tool-calling dinámico si se requiere.
5. **Memoria conversacional persistente** (hoy es en memoria del proceso).

---

## 11. Estructura de los proyectos

```
ganimedes-backend/          # PocketBase (systemd en el VPS)
├── pocketbase              # binario
├── pb_migrations/          # esquema + multi-tenant + seguridad
├── pb_hooks/main.pb.js     # hash PIN, folios, protección de rol
├── pb_data/data.db         # datos (admin + tenant ganimedes)
├── Dockerfile, docker-compose.yml, docker-entrypoint.sh, .env.example
└── README.md

ganimedes-agent/            # API FastAPI del agente (Docker)
├── main.py
├── app/
│   ├── config.py
│   ├── pocketbase/ (client.py, auth.py)
│   ├── api/ (routes/agent.py, deps.py, middleware.py)
│   ├── agent/ (llm.py, orchestrator.py, context/, tools/, memory/)
│   └── utils/ (security.py, logger.py)
├── requirements.txt, Dockerfile, docker-compose.yml, .env
└── docs/ARCHITECTURE.md

ganimedes-panel/            # Frontend React (Docker nginx)
├── src/ (App.jsx, api.js, main.jsx, styles.css)
├── package.json, vite.config.js, index.html
├── Dockerfile, docker-compose.yml, .env
└── .env.example
```

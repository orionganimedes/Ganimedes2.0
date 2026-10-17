# PLAN MAESTRO: GANIMEDES 2.0

## Estado General

- [x] Fase 1: Aislamiento multi-tenant en todas las tools del agente IA — ✅ COMPLETADA Y DESPLEGADA
- [ ] Fase 2: Implementación de herramientas de negocio en el agente IA (FastAPI)
- [ ] Fase 3: Integración de servicios en Flutter (POS, Inventario y Cortes de Caja)
- [ ] Fase 4: Sincronización del panel administrativo de escritorio (Rust / Desktop)
- [ ] Fase 5: Pruebas end-to-end de flujo de cobro y tickets por WhatsApp

---

## Topología de Agentes

| Agente | Rol | Alcance |
|--------|-----|---------|
| **Arquitecto** | Diseño técnico, contratos y criterios de aceptación | Diseño de todas las fases |
| **Worker 1** | Implementación Backend / agente-ia (Python/FastAPI) | `agente-ia/`, `backend/` |
| **Worker 2** | Implementación Frontend Flutter / Rust | `ganimedes/`, `panelpc/` |
| **Auditor** | Validación estática, filtros multi-tenant, antipatrones Flutter | Revisión de todo cambio |
| **Deployer** | Análisis y auditoría de colecciones PocketBase vía SSH al VPS (puerto 8090) | Base de datos en producción |
| **SSH-OPS** | Sincronización y validación en VPS en tiempo real vía `sync_agent_vps.sh` | `agente-ia/` en producción |
| **Debugger** | Observabilidad en runtime Flutter via `flutter_manager.sh`, DevTools, `debug_report.md` | UI/Layout en `ganimedes/` |

### Scripts de infraestructura
- **SSH-OPS**: `/home/orion/orca/workspaces/ganimedes2.0/scripts/sync_agent_vps.sh`  
  Prompt: `.orchestrator/prompts/ssh_ops.md`  
  Activa automáticamente tras auditoría aprobada en cualquier tarea de `agente-ia/`.
- **Debugger**: `/home/orion/orca/workspaces/ganimedes2.0/debugger/scripts/flutter_manager.sh {start [device]|status|reload|restart|logs [n]|errors|stop}`

---

## Infraestructura de Producción

- **VPS**: `37.60.242.14` (usuario: ganimedes)
- **Ruta de tools en VPS**: `/home/ganimedes/ganimedes-agent/app/agent/tools/`
- **Contenedor Docker**: `ganimedes-agent` (Uvicorn en puerto 8000)
- **Comando de reinicio**: `docker restart ganimedes-agent`
- **PocketBase**: Puerto 8090 (activo vía SSH tunnel)

---

## Historial de Tareas

| ID | Descripción | Worker | Auditor | Debugger | Estado |
|----|-------------|--------|---------|----------|--------|
| 01_INIT_DATABASE_AUDIT | Auditoría inicial | — | — | — | ✅ |
| 02_SALES_TENANT_FILTER | Filtro multi-tenant `sales.py` | W1 | ✅ | — | ✅ desplegada |
| 03_SALES_PERIOD_FILTER | Filtro por periodo `sales.py` | W1 | ✅ | — | ✅ desplegada |
| 04_INVENTORY_TENANT_FILTER | Filtro multi-tenant `inventory.py` | W1 | ✅ | — | ✅ desplegada |
| 05_APPOINTMENTS_TENANT_FILTER | Filtro multi-tenant `appointments.py` | W1 | ✅ | — | ✅ desplegada |
| 06_CLIENTS_TENANT_FILTER | Filtro multi-tenant `clients.py` | W1 | ✅ | — | ✅ desplegada |
| 07_BARBERS_TENANT_FILTER | Filtro multi-tenant `barbers.py` | W1 | ✅ | — | ✅ desplegada |
| 08_REPORTS_TENANT_FILTER | Filtro multi-tenant `reports.py` | W1 | ✅ | — | ✅ desplegada |
| 09_BRANCHES_TENANT_FILTER | Filtro multi-tenant `branches.py` | W1 | ✅ | — | ✅ desplegada |
| 10_CASH_SHIFT_TOOL | Nueva tool `cash_shifts.py` | W1 | ✅ | — | ✅ desplegada |
| 11_COPILOT_LAYOUT_OVERFLOW | Fix RenderFlex en `ai_assistant_screen.dart` | W2 | pendiente | pendiente | 🔄 en curso |

---

## Tarea en Curso

- Tarea actual: `11_COPILOT_LAYOUT_OVERFLOW` — pendiente validación por Debugger y Auditor

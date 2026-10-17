# Ganimedes 2.0 — Stack Tecnológico e Implementaciones

## Arquitectura General

Ganimedes 2.0 es un sistema multi-tenant de punto de venta (POS) con agente de inteligencia artificial integrado. Está compuesto por cuatro módulos principales que interactúan entre sí.

```
┌─────────────────────────────────────────────────────┐
│                  GANIMEDES 2.0                      │
│                                                     │
│  Flutter Mobile POS  ←→  FastAPI Agent IA           │
│       (Android)              (:8000)                │
│           ↕                    ↕                    │
│      PocketBase DB  ←─────────────                  │
│         (:8090)                                     │
│           ↕                                         │
│    Rust Desktop Panel                               │
│       (panelpc/)                                    │
└─────────────────────────────────────────────────────┘
```

---

## Tecnologías por Módulo

### 1. Base de Datos — PocketBase
- **Versión:** PocketBase (self-hosted en VPS)
- **Host producción:** `37.60.242.14:8090`
- **Modelo:** Multi-tenant — cada colección tiene campo `business_name` como aislador de tenant
- **Colecciones principales:**
  - `sales` — tickets de venta
  - `sale_items` — líneas de cada ticket
  - `products_services` — catálogo de productos y servicios
  - `appointments` — citas agendadas
  - `clients` — cartera de clientes
  - `users` — operadores y administradores
  - `branches` — sucursales
  - `cash_shifts` — cortes de caja
  - `ai_profiles` — perfil de configuración del agente IA por negocio
  - `categories` — categorías del catálogo

### 2. Agente IA — FastAPI (Python)
- **Framework:** FastAPI con Uvicorn
- **Puerto:** 8000
- **Despliegue:** Contenedor Docker `ganimedes-agent` en VPS
- **Patrón:** Tools registradas con `register()` — cada tool es una función async con schema JSON
- **Tools implementadas:**

| Tool | Descripción |
|------|-------------|
| `get_sales_report` | Ventas totales por método de pago, filtro por tenant y periodo |
| `get_inventory_status` | Catálogo con stock bajo, filtro por categoría y tenant |
| `list_appointments` | Citas por estado y tenant |
| `list_clients` | Clientes con búsqueda por nombre y tenant |
| `get_barber_stats` | Rendimiento de barberos y ventas por operador |
| `generate_financial_report` | Reporte financiero consolidado por tenant |
| `get_daily_earnings` | Ventas del día actual con desglose por método de pago |
| `list_branches` | Sucursales del negocio por tenant |
| `get_cash_shift_status` | Estado del turno de caja actual e historial del día |

- **Regla multi-tenant:** Todas las queries a PocketBase incluyen `business_name = "{tenant}"` como filtro obligatorio y primero, combinado con `&&` para filtros adicionales.

### 3. Frontend Móvil — Flutter (Android)
- **SDK:** Flutter (Dart)
- **Target:** Android (mobile POS)
- **Arquitectura de navegación:**
  - Shell principal (`MainShell`) con `IndexedStack` de 4 tabs: Dashboard, POS, Inventario, Caja
  - Copilot IA como ruta independiente (`Navigator.push`) para pantalla completa
- **Pantallas principales:**
  - `DashboardScreen` — métricas y resumen del negocio
  - `PosScreen` — punto de venta y carrito
  - `InventoryScreen` — gestión de catálogo y stock
  - `CashRegisterScreen` — corte de caja y turnos
  - `AiAssistantScreen` — chat con el Copilot IA (ruta fullscreen)
  - `AiSetupScreen` — configuración del perfil del agente
- **Servicios:**
  - `PocketBaseService` — cliente HTTP al backend PocketBase con auto-discovery de servidor
  - `AiChatService` — cliente de streaming al agente FastAPI
- **Manejo de teclado:** `resizeToAvoidBottomInset: true` con layout `Column + Expanded` — sin cálculos manuales de insets

### 4. Panel Desktop — Rust
- **Framework:** Rust (panelpc/)
- **Propósito:** Panel administrativo de escritorio para gestión avanzada
- **Estado:** Fase 4 del roadmap (pendiente)

---

## Infraestructura de Orquestación

El proyecto usa un sistema de agentes especializados coordinados por el Arquitecto:

| Agente | Script / Herramienta | Responsabilidad |
|--------|---------------------|----------------|
| **Arquitecto** | Claude Code | Diseño técnico y contratos |
| **Worker 1** | Workspace `worker-1/` | Implementación backend Python |
| **Worker 2** | Workspace `worker-2/` | Implementación Flutter/Rust |
| **Auditor** | Claude Code | Validación estática y multi-tenant |
| **SSH-OPS** | `scripts/sync_agent_vps.sh` | Despliegue de código al VPS |
| **Deployer** | `ssh ganimedes@37.60.242.14` | Auditoría de PocketBase en producción |
| **Debugger** | `debugger/scripts/flutter_manager.sh` | Observabilidad runtime Flutter |

---

## Seguridad Multi-Tenant

**Regla estricta:** Ninguna query a PocketBase puede ejecutarse sin el filtro:

```python
filter = f'business_name = "{tenant}"'
```

Filtros adicionales se combinan siempre con el operador `&&`:

```python
filter = f'business_name = "{tenant}" && status = "open"'
```

Esto garantiza aislamiento completo de datos entre negocios que comparten la misma instancia de PocketBase.

---

## Flujo de Despliegue Backend

```
Worker 1 edita agente-ia/
      ↓
Auditor valida filtros y sintaxis
      ↓
SSH-OPS ejecuta sync_agent_vps.sh:
  1. py_compile local
  2. rsync → VPS
  3. py_compile remoto
  4. docker restart ganimedes-agent
  5. docker logs (verificación)
```

## Flujo de Despliegue Frontend

```
Worker 2 edita ganimedes/
      ↓
flutter analyze (sin errores)
      ↓
Debugger: flutter_manager.sh restart
      ↓
Debugger audita logs DevTools
      ↓
Auditor aprueba → git commit
```

---

## Comandos de Verificación Rápida

```bash
# Verificar sintaxis Python del agente IA
python3 -m py_compile agente-ia/app/**/*.py

# Analizar Flutter sin errores
flutter --directory ganimedes analyze

# Verificar compilación Rust
cargo check --manifest-path panelpc/Cargo.toml

# Estado del agente en producción
ssh ganimedes@37.60.242.14 "docker logs --tail 15 ganimedes-agent"

# Salud de PocketBase en producción
ssh ganimedes@37.60.242.14 "curl -s http://127.0.0.1:8090/api/health"
```

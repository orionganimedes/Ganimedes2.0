# Ganimedes 2.0 — POS & Business Engine

**Proyecto:** Ganimedes POS (Versión 2.0 — Producción)  
**Entorno Tecnológico:** Flutter 3.x / Dart (Android 14/15 — Google Pixel 7)  
**Backend:** PocketBase v0.25.9 (Self-hosted en VPS)  
**Motor de IA:** Ganimedes Copilot AI Engine en VPS (`http://37.60.242.14:8000`) con Streaming SSE  
**Fecha de Consolidación:** Octubre 2026  
**Estado:** ✅ Fase 1 completada • Multi-tenant aislado • Flutter fullscreen Copilot

---

## Tabla de Contenidos

1. [Visión General del Sistema](#1-visión-general-del-sistema)
2. [Arquitectura General](#2-arquitectura-general)
3. [Tecnologías por Módulo](#3-tecnologías-por-módulo)
4. [Base de Datos y Multi-Inquilino (PocketBase)](#4-base-de-datos-y-multi-inquilino-pocketbase)
5. [Módulo POS y Cobro](#5-módulo-pos-y-cobro)
6. [Visor de Ticket Digital Térmico y WhatsApp](#6-visor-de-ticket-digital-térmico-y-whatsapp)
7. [Módulo de Caja, Arqueo en Vivo y Corte Z](#7-módulo-de-caja-arqueo-en-vivo-y-corte-z)
8. [Asistente de IA — Ganimedes Copilot (Streaming SSE)](#8-asistente-de-ia--ganimedes-copilot-streaming-sse)
9. [Diseño y Sistema de Temas](#9-diseño-y-sistema-de-temas)
10. [Seguridad Multi-Tenant](#10-seguridad-multi-tenant)
11. [Infraestructura de Orquestación](#11-infraestructura-de-orquestación)
12. [Flujo de Despliegue](#12-flujo-de-despliegue)
13. [Comandos de Verificación Rápida](#13-comandos-de-verificación-rápida)
14. [Memoria del Proyecto](#14-memoria-del-proyecto)
15. [Credenciales y Accesos](#15-credenciales-y-accesos)

---

## 1. Visión General del Sistema

**Ganimedes 2.0 POS** es un sistema integral de punto de venta, control de inventario, auditoría de caja e inteligencia de negocios diseñado específicamente para barberías de alta rotación, cadenas de estilismo y comercios de servicios.

### Capacidades Principales Implementadas

- **Aislamiento Multi-Negocio Real:** Cada negocio registrado opera con su propio catálogo de inventario, servicios, precios y folios de ventas independientes.
- **Comprobantes Digitales Instantáneos:** Visor de ticket térmico de 80mm con código de barras y envío automatizado por WhatsApp (`+52` predeterminado).
- **Control Financiero y Corte Z:** Registro de ventas por método de pago (efectivo, tarjeta bancaria, SPEI/transferencia), balance en vivo de gaveta y arqueo con detección de sobrante/faltante.
- **Copiloto con IA en Vivo:** Pantalla fullscreen accesible desde la barra de navegación (`FloatingDock`), conectada a un VPS con streaming palabra por palabra (SSE).

---

## 2. Arquitectura General

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
| Agente IA | FastAPI | 8000 | Docker `ganimedes-agent` (network host) |
| Base de datos | PocketBase | 8090 | systemd `pocketbase` |
| LLM | Ollama (Qwen2.5) | 11434 local | systemd (ya existía) |

---

## 3. Tecnologías por Módulo

### Backend — PocketBase
- **Versión:** PocketBase v0.25.9 (self-hosted en VPS)
- **Host producción:** `37.60.242.14:8090`
- **Modelo:** Multi-tenant — campo `business_name` como aislador de tenant en todas las colecciones

### Agente IA — FastAPI (Python)
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

### Frontend Móvil — Flutter (Android)
- **SDK:** Flutter (Dart)
- **Target:** Android (mobile POS — Google Pixel 7)
- **Arquitectura de navegación:**
  - Shell principal (`MainShell`) con `IndexedStack` de 4 tabs: Dashboard, POS, Inventario, Caja
  - Copilot IA como ruta independiente (`Navigator.push`) para pantalla completa
- **Manejo de teclado:** `resizeToAvoidBottomInset: true` con layout `Column + Expanded` — sin cálculos manuales de insets

### Panel Desktop — Rust
- **Framework:** Rust (`panelpc/`)
- **Propósito:** Panel administrativo de escritorio para gestión avanzada
- **Estado:** Fase 4 del roadmap (pendiente)

---

## 4. Base de Datos y Multi-Inquilino (PocketBase)

### Colecciones y Esquema de Datos

1. **`users`:** `id`, `name`, `email`, `role` (`admin`, `master_barber`, `barber`), `branch_code`, `business_name`, `phone`, `pin`
2. **`branches`:** `code`, `name`, `business_name`, `parent_id`, `address`, `phone`
3. **`products_services`:** `name`, `price`, `stock`, `category`, `is_service`, `min_stock_alert`, `branch_code`, `business_name`, `barcode`, `duration_minutes`
4. **`sales`:** `folio` (`#TK-1001`), `customer_name`, `barber_name`, `branch_code`, `subtotal`, `discount`, `total`, `payment_method` (`cash`, `card`, `spei`), `cash_received`, `change_returned`
5. **`sale_items`:** `sale_folio`, `product_id`, `product_name`, `quantity`, `unit_price`, `total_price`, `branch_code`
6. **`cash_shifts`:** `branch_code`, `business_name`, `opened_by`, `initial_cash`, `expected_cash`, `actual_cash`, `difference`, `total_sales`, `cash_sales`, `card_sales`, `spei_sales`, `tickets_count`, `notes`
7. **`clients`:** cartera de clientes del negocio
8. **`appointments`:** citas agendadas por estado
9. **`ai_profiles`:** perfil de configuración del agente IA por negocio
10. **`categories`:** categorías del catálogo

### Mecanismo de Aislamiento

Al registrar un nuevo comercio, el sistema genera la sucursal matriz y el administrador vinculados a su propia razón social. Todas las queries aplican filtros parametrizados por `business_name`.

### Seguridad Implementada en PocketBase

- Reglas de API cerradas (colecciones de negocio: solo autenticados; borrado solo admin)
- `users`: lista solo superuser, cada quien ve/edita su propio registro
- Hash de PIN (SHA-256) con hook JS
- Folios de venta auto-generados con hook JS
- Protección de rol (un usuario no se auto-asigna `admin`)

---

## 5. Módulo POS y Cobro

- Archivo: `lib/screens/pos_screen.dart`
- **Catálogo:** Cuadrícula de 2 columnas con tarjetas reactivas, indicación de tiempo de servicio, stock en tiempo real y selector de categorías.
- **Carrito y Venta Flotante:** Resumen inferior persistente con selector de cliente y cálculo inmediato de totales.
- **Modal de Pago Multiforma (`lib/widgets/pos/payment_modal.dart`):**
  - Admite **Efectivo**, **Tarjeta Bancaria** (Clip/Stripe) y **Transferencia SPEI**
  - Teclado numérico y botones de denominación rápida ($50, $100, $200, $500, $1,000 MXN)
  - Cálculo dinámico de cambio a devolver en tiempo real
  - Registra la transacción atómica en `sales` y los conceptos en `sale_items`, descontando el stock correspondiente en `products_services`

---

## 6. Visor de Ticket Digital Térmico y WhatsApp

### Visor de Ticket Térmico

- Archivo: `lib/widgets/pos/digital_ticket_viewer_dialog.dart`
- **Diseño:** Representación realista de papel continuo de 80mm con muescas de corte en bordes, tipografía condensada monoespaciada, líneas punteadas y código de barras térmico.
- **Detalle:** Encabezado del negocio, sucursal, folio correlativo (`#TK-XXXXX`), fecha/hora, operador, cliente, tabla de productos/servicios, subtotal, impuestos, total, desglose de pago.

### Envío por WhatsApp

- Archivo: `lib/widgets/pos/send_ticket_whatsapp_dialog.dart`
- **Prefijo:** Predeterminado `+52` para México con campo para 10 dígitos
- **Plantilla Profesional:** Redacta un mensaje estructurado con emojis, membrete comercial, desglose de compra, totales y agradecimiento
- **Lanzador de App:** Utiliza `url_launcher` con URL Scheme nativo `whatsapp://send?phone=...&text=...` y respaldo universal a `https://wa.me/`
- **Permisos del Sistema:** Declaradas las consultas en `AndroidManifest.xml` para compatibilidad completa con Android 11+

---

## 7. Módulo de Caja, Arqueo en Vivo y Corte Z

- Archivo: `lib/screens/cash_register_screen.dart`
- **Métricas en Vivo del Turno:** Total de ventas brutas, desglose exacto (Efectivo, Terminal bancaria, SPEI), conteo total de tickets emitidos
- **Listado de Tickets del Turno:** Visualización de cada ticket generado con folio, hora, cliente, operador y badge del método de pago
- **Cierre de Turno / Corte Z:**
  - Modal interactivo que solicita el conteo físico del efectivo en gaveta
  - 🟢 **Arqueo Exacto ($0.00)** · 🔵 **Sobrante en Gaveta (+$X.XX)** · 🟠 **Faltante en Gaveta (-$X.XX)**
  - Guarda el registro formal en `cash_shifts` de PocketBase y reinicia los contadores del turno

---

## 8. Asistente de IA — Ganimedes Copilot (Streaming SSE)

### Conexión con el Servidor VPS

- **Host:** `http://37.60.242.14:8000`
- **Health Check:** `GET /health` → `{"status":"ok","service":"Ganimedes AI API"}`
- **Streaming Endpoint:** `POST /api/chat/stream`

### Servicio de IA (`lib/services/ai_chat_service.dart`)

- **Transmisión por Streaming (SSE):** Utiliza `LineSplitter()` en Dart sobre el flujo UTF-8 decodificado para procesar cada evento `data: {"token": "...", "done": false}` de forma robusta y libre de fragmentación.
- **Inyección de Métricas en Vivo:** Con cada mensaje, el servicio extrae automáticamente de PocketBase: razón social, código de sucursal, ventas totales del turno, efectivo en gaveta, e historial previo de la conversación.

### Pantalla de Chat (`lib/screens/ai_assistant_screen.dart`)

- Ruta fullscreen (`Navigator.push`) — independiente del `IndexedStack`
- **Fichas de Acción Rápida:** Sugerencias rápidas de consulta al Copilot
- **Efecto Máquina de Escribir:** Respuesta en tiempo real con cursor dinámico Cyan Neón (` ▍`)
- **Layout:** `Column + Expanded(ListView) + suggestions + input` — sin `BackdropFilter` ni cálculos manuales de insets

---

## 9. Diseño y Sistema de Temas

### Paleta de Colores

- **Tema Oscuro (Deep Obsidian):** Fondo `#0A0E17`, contenedores `#111827` a `#1F2937`, acentos en Cyan Neón (`#06B6D4 / #22D3EE`) y azul cobalto (`#1D4ED8`)
- **Tema Claro (Clean Canvas):** Fondo `#F8FAFC`, superficies `#FFFFFF` y bordes sutiles en `#E2E8F0`
- **Primary:** `#1D4ED8` — botones de acción principal, navegación activa
- **Secondary / Accent:** `#00B4D8` — indicadores de estado, feedback de live data
- **Success:** `#10B981` · **Warning:** `#F59E0B` · **Destructive:** `#EF4444`

### Tipografía

- **Familia:** Inter — máxima legibilidad en pantallas de alta densidad
- **Escalas:** `headline-xl` (32px/700) → `label-sm` (10px/600)
- **Numeric Clarity:** Tabular numeric styling (`tnum`) en totales y balances

### Layout & Espaciado

- **Grid 8pt** táctil — breakpoints: Compact <600px, Medium 600-1024px, Expanded >1024px
- Tap targets mínimos: `48×48px`
- Dock Flotante: Efecto Glassmorphism con `BackdropFilter` (sigma 16), esquinas 32px

---

## 10. Seguridad Multi-Tenant

**Regla estricta:** Ninguna query a PocketBase puede ejecutarse sin el filtro:

```python
filter = f'business_name = "{tenant}"'
```

Filtros adicionales se combinan siempre con `&&`:

```python
filter = f'business_name = "{tenant}" && status = "open"'
```

Esto garantiza aislamiento completo de datos entre negocios que comparten la misma instancia de PocketBase.

### Tools auditadas y corregidas (Fase 1)

| Tool | Archivo | Estado |
|------|---------|--------|
| `get_sales_report` + periodo | `tools/sales.py` | ✅ |
| `get_inventory_status` | `tools/inventory.py` | ✅ |
| `list_appointments` | `tools/appointments.py` | ✅ |
| `list_clients` | `tools/clients.py` | ✅ |
| `get_barber_stats` | `tools/barbers.py` | ✅ |
| `generate_financial_report` + `get_daily_earnings` | `tools/reports.py` | ✅ |
| `list_branches` | `tools/branches.py` | ✅ |
| `get_cash_shift_status` | `tools/cash_shifts.py` | ✅ (nueva) |

---

## 11. Infraestructura de Orquestación

El proyecto usa un sistema de agentes especializados coordinados por el Arquitecto:

| Agente | Herramienta | Responsabilidad |
|--------|-------------|----------------|
| **Arquitecto** | Claude Code | Diseño técnico y contratos |
| **Worker 1** | Workspace `worker-1/` | Implementación backend Python |
| **Worker 2** | Workspace `worker-2/` | Implementación Flutter/Rust |
| **Auditor** | Claude Code | Validación estática y multi-tenant |
| **SSH-OPS** | `scripts/sync_agent_vps.sh` | Despliegue de código al VPS |
| **Deployer** | `ssh ganimedes@37.60.242.14` | Auditoría de PocketBase en producción |
| **Debugger** | `debugger/scripts/flutter_manager.sh` | Observabilidad runtime Flutter |

### Scripts de Infraestructura

```bash
# SSH-OPS: sincroniza y valida en el VPS
/home/orion/orca/workspaces/ganimedes2.0/scripts/sync_agent_vps.sh

# Debugger: gestión de la app Flutter en dispositivo
flutter_manager.sh {start [device]|status|reload|restart|logs [n]|errors|stop}

# Deployer: conexión SSH persistente al VPS
ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=6 ganimedes@37.60.242.14 '<comando>'
```

---

## 12. Flujo de Despliegue

### Backend (Agente IA)

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

### Frontend (Flutter)

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

## 13. Comandos de Verificación Rápida

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

# Estado de contenedores Docker
ssh ganimedes@37.60.242.14 "docker ps"

# Gestión de PocketBase (systemd)
sudo systemctl status pocketbase
journalctl -u pocketbase -f

# Reconstruir agente en VPS
cd ~/ganimedes-agent && docker compose up -d --build
```

---

## 14. Memoria del Proyecto

### Cronología de Implementación

#### Fase 1 — Análisis Inicial
- Conexión SSH al VPS (`ganimedes@37.60.242.14`)
- Análisis del VPS: Ollama corriendo, agente Node parado, puertos abiertos
- Análisis del backend.zip: PocketBase, esquema, datos y reglas abiertas

#### Fase 2 — Contenedorización del Backend PocketBase
- `Dockerfile`, `docker-compose.yml`, `docker-entrypoint.sh`, `.dockerignore`, `.env.example` para PocketBase
- Entrypoint: `migrate up` → `superuser upsert` (desde env) → `serve`
- Datos fuera de la imagen (volumen `pb_data`)

#### Fase 3 — Limpieza de Datos + Seguridad
- Eliminación de datos de prueba; conservación de 5 categorías base
- Reglas de API cerradas, hash de PIN (SHA-256) con hook JS, folios auto-generados
- Protección de rol: un usuario no se auto-asigna `admin`

#### Fase 4 — Despliegue de PocketBase al VPS
- Servicio **systemd** `pocketbase.service` (User=ganimedes, puerto 8090)

#### Fase 5 — Modelo Multi-Tenant (Migraciones)
- Migraciones en `pb_migrations/`: agrega `business_name` a users, chairs, cash_shifts, cash_movements, sales, sale_items
- Nuevas colecciones: `clients`, `appointments`
- Datos semilla del tenant `ganimedes`: 1 sucursal, 3 productos, 1 cliente, 1 cita, 1 venta

#### Fase 6 — Construcción del Agente (FastAPI) y Panel (React)
- `ganimedes-agent/` (FastAPI): 7 tools con filtro central por tenant + auth JWT
- `ganimedes-panel/` (React + Vite): login, chat y editor de prompt

#### Fase 7 — Despliegue Completo en el VPS
- Docker instalado en el VPS
- `ganimedes-agent` (contenedor, puerto 8000, network host)
- `ganimedes-panel` (contenedor nginx, puerto 80)

#### Fase 8 — Aislamiento Multi-Tenant Estricto (Arquitecto/Worker 1)
- Auditoría y corrección de las 7 tools del agente IA
- Nueva tool `get_cash_shift_status` (cash_shifts.py)
- Despliegue al VPS vía SSH-OPS

#### Fase 9 — Flutter Copilot Fullscreen (Arquitecto/Worker 2)
- Fix RenderFlex overflow: `mainAxisSize.min` + `Expanded` inválido
- Conversión de Copilot IA a ruta fullscreen (`Navigator.push`)
- Eliminado del `IndexedStack` — 4 tabs únicamente

### Decisiones Técnicas

1. **Contexto "eager" en vez de tool-calling dinámico.** Qwen2.5:3b no hace tool-calling fiable — las 7 tools se ejecutan siempre y su salida se inyecta al prompt.
2. **Multi-tenant por `business_name`** — campo ya existente en branches/products, replicado a las demás colecciones.
3. **PocketBase por systemd** (rápido, sin Docker) y **agente/panel por Docker** (aislamiento y reproducibilidad).
4. **`network_mode: host` en el agente** para que alcance Ollama y PocketBase del host sin configurar redes extra.
5. **Copilot IA como ruta fullscreen** — elimina conflicto `mainAxisSize.min` + `Expanded` del IndexedStack.

### Problemas Encontrados y Soluciones

| Problema | Solución |
|---|---|
| `Bad owner or permissions on /etc/ssh/ssh_config.d/...` | usar `ssh -F /dev/null` |
| Reglas de API abiertas en PocketBase | migración `1792000000_security_rules.js` |
| Qwen2.5:3b no hace tool-calling | contexto eager |
| Migraciones auto-generadas al hacer PATCH vía API | eliminarlas + `migrate history-sync` |
| `sqlite3` no instalado en el VPS | verificar vía API REST de PocketBase |
| RenderFlex overflow en Copilot IA (Flutter) | `Column + Expanded` + ruta fullscreen |
| `separatorBuilder: (_, __)` — unnecessary_underscores | cambiar a `(_, _)` |

---

## 15. Credenciales y Accesos

> **Cambiar antes de producción.**

| Recurso | Usuario | Contraseña |
|---|---|---|
| SSH/sudo VPS | `ganimedes` | `190594` |
| PocketBase superusuario | `admin@ganimedes.com` | `Ganimedes2026!` |
| App admin (tenant `ganimedes`) | `prueba@ganimedes.com` | `prueba1234` (PIN `1234`) |

**URLs de Producción:**
- Panel: `http://37.60.242.14/`
- Agente IA: `http://37.60.242.14:8000/api/agent/`
- PocketBase: `http://37.60.242.14:8090` (API `/api/`, admin `/_/`)

---

## Estado Actual del Roadmap

- [x] **Fase 1:** Aislamiento multi-tenant en todas las tools del agente IA — ✅ COMPLETADA Y DESPLEGADA
- [x] **Fase 1.5:** Flutter Copilot fullscreen — ✅ COMPLETADA
- [ ] **Fase 2:** Implementación de herramientas de negocio en el agente IA (FastAPI)
- [ ] **Fase 3:** Integración de servicios en Flutter (POS, Inventario y Cortes de Caja)
- [ ] **Fase 4:** Sincronización del panel administrativo de escritorio (Rust / Desktop)
- [ ] **Fase 5:** Pruebas end-to-end de flujo de cobro y tickets por WhatsApp

---

## Árbol de Archivos Principal

```
ganimedes2.0/
├── agente-ia/                          # API FastAPI del agente (Docker)
│   └── app/
│       ├── pocketbase/ (client.py, auth.py)
│       ├── api/ (routes/agent.py, deps.py, middleware.py)
│       └── agent/
│           ├── llm.py
│           ├── orchestrator.py
│           └── tools/
│               ├── sales.py            # ✅ multi-tenant + periodo
│               ├── inventory.py        # ✅ multi-tenant + categoría
│               ├── appointments.py     # ✅ multi-tenant + estado
│               ├── clients.py          # ✅ multi-tenant + búsqueda
│               ├── barbers.py          # ✅ multi-tenant + barber_name
│               ├── reports.py          # ✅ multi-tenant (4 queries)
│               ├── branches.py         # ✅ multi-tenant
│               └── cash_shifts.py      # ✅ NUEVA tool
├── ganimedes/                          # Flutter Mobile POS
│   └── lib/
│       ├── screens/
│       │   ├── main_shell.dart         # ✅ Copilot como Navigator.push
│       │   └── ai_assistant_screen.dart# ✅ fullscreen, Column+Expanded
│       └── services/
│           ├── pocketbase_service.dart
│           └── ai_chat_service.dart
├── panelpc/                            # Rust Desktop Panel (Fase 4)
└── .orchestrator/
    ├── prompts/
    │   ├── deployer.md                 # Inspector PocketBase en VPS
    │   └── ssh_ops.md                  # Despliegue de código
    └── state/
        └── plan_maestro.md             # Topología y tareas
```

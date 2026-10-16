# Ganimedes 2.0 POS & Business Engine — Documento Maestro de Implementación

**Proyecto:** Ganimedes POS (Versión 2.0 — Producción)  
**Entorno Tecnológico:** Flutter 3.x / Dart (Android 14/15 — Google Pixel 7)  
**Backend:** PocketBase v0.25.9 (Local & Red)  
**Motor de IA:** Ganimedes Copilot AI Engine en VPS (`http://37.60.242.14:3000`) con Streaming SSE  
**Fecha de Consolidación:** Octubre 2026  
**Estado:** ✅ 100% Funcional • 0 Errores de Análisis • APK Compilado y Desplegado  

---

## 📑 Tabla de Contenidos
1. [Visión General del Sistema](#1-visión-general-del-sistema)
2. [Arquitectura General y Árbol de Archivos](#2-arquitectura-general-y-árbol-de-archivos)
3. [Base de Datos y Multi-Inquilino (PocketBase)](#3-base-de-datos-y-multi-inquilino-pocketbase)
4. [Módulo POS y Cobro](#4-módulo-pos-y-cobro)
5. [Visor de Ticket Digital Térmico (80mm) y Compartir por WhatsApp](#5-visor-de-ticket-digital-térmico-80mm-y-compartir-por-whatsapp)
6. [Módulo de Caja, Arqueo en Vivo y Corte Z](#6-módulo-de-caja-arqueo-en-vivo-y-corte-z)
7. [Asistente de IA en Navbar: Ganimedes Copilot (Streaming SSE)](#7-asistente-de-ia-en-navbar-ganimedes-copilot-streaming-sse)
8. [Diseño y Sistema de Temas (Cyber-Geométrico Dual)](#8-diseño-y-sistema-de-temas-cyber-geométrico-dual)
9. [Control de Calidad, Compilación y Despliegue](#9-control-de-calidad-compilación-y-despliegue)

---

## 1. Visión General del Sistema

**Ganimedes 2.0 POS** es un sistema integral de punto de venta, control de inventario, auditoría de caja e inteligencia de negocios diseñado específicamente para barberías de alta rotación, cadenas de estilismo y comercios de servicios.

### Capacidades Principales Implementadas:
* **Aislamiento Multi-Negocio Real:** Cada negocio registrado opera con su propio catálogo de inventario, servicios, precios y folios de ventas independientes.
* **Comprobantes Digitales Instantáneos:** Visor de ticket térmico de 80mm con código de barras y envío automatizado por WhatsApp (`+52` predeterminado).
* **Control Financiero y Corte Z:** Registro de ventas por método de pago (efectivo, tarjeta bancaria, SPEI/transferencia), balance en vivo de gaveta y arqueo con detección de sobrante/faltante.
* **Copiloto con IA en Vivo:** Pestaña nativa en la barra de navegación (`FloatingDock`) para administradores, conectada a un VPS con streaming palabra por palabra (SSE) que inyecta en tiempo real las finanzas del turno y catálogo del negocio.

---

## 2. Arquitectura General y Árbol de Archivos

```text
ganimedes/
├── android/
│   ├── app/
│   │   ├── build.gradle.kts                      # compileSdk = 35, targetSdk = 35, minSdk = 24
│   │   └── src/main/AndroidManifest.xml          # Permisos de red, cámara e intents (WhatsApp queries)
│   └── gradle.properties                         # JVM args (--enable-native-access=ALL-UNNAMED)
├── backend/
│   ├── pocketbase                                # Binario Linux de PocketBase v0.25.9
│   ├── pb_data/                                  # Almacenamiento SQLite y registros
│   └── pb_migrations/                            # Migraciones automáticas de esquema
│       └── 1791008000_add_branch_to_products.js  # Migración para multi-tenancy
├── docs/
│   └── implementaciones/                         # Respaldos de documentación técnica
├── implementaciones/
│   ├── DOCUMENTO_MAESTRO_DE_IMPLEMENTACION.md    # Este documento
│   ├── ETAPA_2_POS_INVENTARIO_TICKETS_WHATSAPP_CAJA.md
│   └── ETAPA_3_ASISTENTE_IA_COPILOT.md
└── lib/
    ├── main.dart                                 # Punto de entrada reactivo y configuración de rutas
    ├── models/
    │   ├── mock_data.dart                        # Modelos PosItem, CartItem, SaleItem con serialización
    │   └── user_session.dart                     # Modelo UserSession y evaluación de rol isAdmin
    ├── screens/
    │   ├── splash_screen.dart                    # Splash screen interactivo con barra reactiva 0-100%
    │   ├── main_shell.dart                       # Shell de navegación con IndexedStack y FloatingDock
    │   ├── pos_screen.dart                       # Terminal POS con catálogo en 2 columnas y ticket flotante
    │   ├── inventory_screen.dart                 # Gestión de inventario, KPIs, filtros y lector de barras
    │   ├── cash_register_screen.dart             # Arqueo de caja, tickets del turno y modal Corte Z
    │   ├── dashboard_screen.dart                 # Dashboard operativo con estado de sillones y métricas
    │   ├── ai_assistant_screen.dart              # Pantalla de Ganimedes Copilot con streaming en vivo
    │   └── auth/
    │       ├── login_screen.dart                 # Inicio de sesión automático por correo/contraseña/PIN
    │       └── signup_screen.dart                # Registro multi-inquilino de nuevo negocio y admin
    ├── services/
    │   ├── pocketbase_service.dart               # Servicio singleton de base de datos y negocio
    │   └── ai_chat_service.dart                  # Cliente HTTP con streaming SSE para VPS de IA
    ├── theme/
    │   ├── app_colors.dart                       # Paleta oficial Deep Obsidian, Cyan Neón y Clean Slate
    │   ├── app_theme.dart                        # Definiciones de ThemeData oscuro y claro
    │   └── theme_controller.dart                 # ChangeNotifier global de alternancia de tema
    └── widgets/
        ├── app_top_bar.dart                      # Encabezado corporativo, sucursal, tema y perfil
        ├── floating_dock.dart                    # Barra inferior cápsula con efecto desenfoque (Glassmorphism)
        ├── auth/
        │   └── pin_access_dialog.dart            # Modal de acceso rápido y cambio de especialista por PIN
        ├── modals/
        │   └── create_product_modal.dart         # Formulario de alta de productos/servicios en PocketBase
        ├── pos/
        │   ├── payment_modal.dart                # Diálogo de cobro multidivisa (Efectivo/Tarjeta/SPEI)
        │   ├── digital_ticket_viewer_dialog.dart # Visor de ticket térmico de 80mm con código de barras
        │   └── send_ticket_whatsapp_dialog.dart  # Modal de envío de comprobante por WhatsApp (+52)
        └── scanner/
            └── barcode_scanner_dialog.dart       # Lector de códigos de barras por cámara
```

---

## 3. Base de Datos y Multi-Inquilino (PocketBase)

### Colecciones y Esquema de Datos:
1. **`users`:**
   - Campos: `id`, `name`, `email`, `role` (`admin`, `master_barber`, `barber`), `branch_code`, `business_name`, `phone`, `pin`.
2. **`branches`:**
   - Campos: `code`, `name`, `business_name`, `parent_id`, `address`, `phone`.
3. **`products_services`:**
   - Campos: `name`, `price`, `stock`, `category`, `is_service`, `min_stock_alert`, `branch_code`, `business_name`, `barcode`, `duration_minutes`.
4. **`sales`:**
   - Campos: `folio` (`#TK-1001`), `customer_name`, `barber_name`, `branch_code`, `subtotal`, `discount`, `total`, `payment_method` (`cash`, `card`, `spei`), `cash_received`, `change_returned`.
5. **`sale_items`:**
   - Campos: `sale_folio`, `product_id`, `product_name`, `quantity`, `unit_price`, `total_price`, `branch_code`.
6. **`cash_shifts`:**
   - Campos: `branch_code`, `business_name`, `opened_by`, `initial_cash`, `expected_cash`, `actual_cash`, `difference`, `total_sales`, `cash_sales`, `card_sales`, `spei_sales`, `tickets_count`, `notes`.

### Mecanismo de Aislamiento:
* Al registrar un nuevo comercio en [`signup_screen.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/screens/auth/signup_screen.dart), el sistema genera la sucursal matriz y el administrador vinculados a su propia razón social.
* Todas las consultas en [`pocketbase_service.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/services/pocketbase_service.dart) aplican automáticamente filtros parametrizados:
  ```dart
  filter=branch_code='$branchCode'
  ```
* Cada comercio inicia con su inventario y folios en ceros, garantizando total privacidad entre establecimientos.

---

## 4. Módulo POS y Cobro

* Archivo: [`lib/screens/pos_screen.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/screens/pos_screen.dart)
* **Catálogo:** Cuadrícula de 2 columnas con tarjetas reactivas, indicación de tiempo de servicio, stock en tiempo real y selector de categorías.
* **Carrito y Venta Flotante:** Resumen inferior persistente con selector de cliente y cálculo inmediato de totales.
* **Modal de Pago Multiforma ([`lib/widgets/pos/payment_modal.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/widgets/pos/payment_modal.dart)):**
  * Admite **Efectivo**, **Tarjeta Bancaria** (Clip/Stripe) y **Transferencia SPEI**.
  * Teclado numérico y botones de denominación rápida ($50, $100, $200, $500, $1,000 MXN).
  * Cálculo dinámico de cambio a devolver en tiempo real.
  * Al completar la venta, registra la transacción atómica en `sales` y los conceptos en `sale_items`, descontando el stock correspondiente en `products_services`.

---

## 5. Visor de Ticket Digital Térmico (80mm) y Compartir por WhatsApp

### Visor de Ticket Térmico:
* Archivo: [`lib/widgets/pos/digital_ticket_viewer_dialog.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/widgets/pos/digital_ticket_viewer_dialog.dart)
* **Diseño:** Representación realista de papel continuo de 80mm con muescas de corte en bordes, tipografía condensada monoespaciada, líneas punteadas y código de barras térmico.
* **Detalle:** Encabezado del negocio, sucursal, folio correlativo (`#TK-XXXXX`), fecha/hora, operador, cliente, tabla de productos/servicios, subtotal, impuestos, total, desglose de pago, efectivo recibido y cambio.
* **Acciones integradas:**
  * 📄 **Ver / Imprimir Ticket**
  * 💬 **Enviar por WhatsApp**
  * 📋 **Copiar al portapapeles**

### Envío por WhatsApp:
* Archivo: [`lib/widgets/pos/send_ticket_whatsapp_dialog.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/widgets/pos/send_ticket_whatsapp_dialog.dart)
* **Prefijo:** Predeterminado `+52` para México con campo para 10 dígitos.
* **Plantilla Profesional:** Redacta un mensaje estructurado con emojis, membrete comercial, desglose de compra, totales y agradecimiento.
* **Lanzador de App:** Utiliza `url_launcher` con URL Scheme nativo `whatsapp://send?phone=...&text=...` y respaldo universal a `https://wa.me/`.
* **Permisos del Sistema:** Declaradas las consultas en `AndroidManifest.xml` (`queries` para `com.whatsapp` y `com.whatsapp.w4b`) para compatibilidad completa con Android 11+.

---

## 6. Módulo de Caja, Arqueo en Vivo y Corte Z

* Archivo: [`lib/screens/cash_register_screen.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/screens/cash_register_screen.dart)
* **Métricas en Vivo del Turno:**
  * Total de ventas brutas.
  * Desglose exacto: Efectivo en gaveta, terminal bancaria y transferencias SPEI.
  * Conteo total de tickets emitidos.
* **Listado de Tickets del Turno:**
  * Visualización de cada ticket generado con folio, hora, cliente, operador y badge del método de pago.
  * Botones rápidos en cada renglón para **"Ver Ticket"** y **"WhatsApp"**.
* **Cierre de Turno / Corte Z:**
  * Modal interactivo que solicita el conteo físico del efectivo en gaveta.
  * Cálculo dinámico de arqueo:
    * 🟢 **Arqueo Exacto ($0.00)**
    * 🔵 **Sobrante en Gaveta (+$X.XX)**
    * 🟠 **Faltante en Gaveta (-$X.XX)**
  * Guarda el registro formal en `cash_shifts` de PocketBase y reinicia los contadores de la caja a ceros para el siguiente turno.

---

## 7. Asistente de IA en Navbar: Ganimedes Copilot (Streaming SSE)

### Conexión con el Servidor VPS:
* **Host:** `http://37.60.242.14:3000`
* **Health Check:** `GET /health` $\rightarrow$ `{"status":"ok","service":"Ganimedes AI API","model":"ganimedes-copilot"}`.
* **Streaming Endpoint:** `POST /api/chat/stream`.

### Servicio de IA ([`lib/services/ai_chat_service.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/services/ai_chat_service.dart)):
* **Transmisión por Streaming (SSE):** Utiliza `LineSplitter()` en Dart sobre el flujo UTF-8 decodificado para procesar cada evento `data: {"token": "...", "done": false}` y `data: {"done": true}` de forma robusta y libre de fragmentación.
* **Inyección de Métricas en Vivo:** Con cada mensaje, el servicio extrae automáticamente de PocketBase:
  * Razón social y código de sucursal.
  * Ventas totales del turno (`total_sales_shift`).
  * Número de tickets del turno (`tickets_count_shift`).
  * Efectivo en gaveta (`cash_in_drawer`).
  * Historial previo de la conversación.

### Pantalla de Chat ([`lib/screens/ai_assistant_screen.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/screens/ai_assistant_screen.dart)):
* **Píldora de Red en Tiempo Real:** `🟢 En línea` con opción de toque para `🟠 Reconectar`.
* **Fichas de Acción Rápida (*Action Chips*):**
  * *¿Cómo van las ventas del turno de hoy?*
  * *¿Cuáles son los productos más vendidos?*
  * *Revisa si tenemos inventario crítico o bajo stock*
  * *Dame una recomendación para aumentar el ticket promedio*
  * *Redacta una promoción atractiva para WhatsApp*
* **Efecto Máquina de Escribir (Typewriter):**
  * Mientras el modelo inicializa (primeros 2 segundos), muestra *"Ganimedes Copilot está pensando..."* con loader animado.
  * En cuanto arriba el primer token, se transforma en la burbuja de respuesta escribiéndose en tiempo real con un cursor dinámico Cyan Neón (` ▍`).
  * Botón de un toque para copiar la respuesta generada al portapapeles.
  * Margen inferior optimizado (`padding: EdgeInsets.fromLTRB(12, 8, 12, 90)`) para evitar solapamientos con la barra flotante.

### Integración en la Barra Flotante ([`lib/widgets/floating_dock.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/widgets/floating_dock.dart)):
* Se ubica en la posición 5 del dock, a un costado del icono de **Caja**.
* Resaltado con icono `Icons.auto_awesome_rounded` y acento Cyan Neón.
* Condicionado estrictamente por rol: visible únicamente para usuarios con permisos de Administrador (`isAdmin == true`).

---

## 8. Diseño y Sistema de Temas (Cyber-Geométrico Dual)

* **Tema Oscuro (Deep Obsidian):** Fondo `#0A0E17`, contenedores `#111827` a `#1F2937`, acentos en Cyan Neón (`#06B6D4` / `#22D3EE`) y azul cobalto (`#1D4ED8`).
* **Tema Claro (Clean Canvas):** Fondo `#F8FAFC`, superficies `#FFFFFF` y bordes sutiles en `#E2E8F0`.
* **Dock Flotante:** Efecto de desenfoque tipo Glassmorphism con `BackdropFilter` (sigma 16) y esquinas redondeadas (radio 32).
* **Controlador Reactivo:** [`ThemeController.instance`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/theme/theme_controller.dart) permite alternar el tema instantáneamente desde el encabezado superior en cualquier pantalla sin recargar la aplicación.

---

## 9. Control de Calidad, Compilación y Despliegue

### Métricas de Calidad de Código:
* **Dart Analyzer (`dart analyze`):** `0 errors • 0 warnings`.
* **Compilación APK:** Finalizada con código de salida `0` en modo depuración optimizada:
  ```text
  ✓ Built build/app/outputs/flutter-apk/app-debug.apk
  ```

### Despliegue en Dispositivo Físico (Google Pixel 7):
* **Redirección de Puertos (ADB Reverse):**
  ```bash
  adb reverse tcp:8090 tcp:8090
  ```
  Permite al teléfono comunicarse con la base de datos PocketBase que corre localmente en la máquina del desarrollador (`http://127.0.0.1:8090`).
* **Conexión con VPS:**
  El teléfono accede directamente a `http://37.60.242.14:3000` a través de su conexión de datos o Wi-Fi para las consultas por streaming de Ganimedes Copilot.

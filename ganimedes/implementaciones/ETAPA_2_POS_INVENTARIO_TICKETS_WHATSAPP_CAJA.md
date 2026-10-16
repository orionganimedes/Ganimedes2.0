# Ganimedes 2.0 POS — Documento de Implementaciones (Etapa 2)

**Proyecto:** Ganimedes Business & POS Engine (v2.0)  
**Fecha de Actualización:** Octubre 2026  
**Entorno:** Flutter 3.x / Dart (Android 14/15 - Google Pixel 7) & PocketBase v0.25.9 Local Backend  

---

## 📋 Resumen de Nuevas Funcionalidades Implementadas

En esta fase de desarrollo se integraron las capacidades operativas esenciales del ecosistema POS, cubriendo el ciclo de vida completo de una venta: desde el alta de productos y servicios por negocio independiente, hasta el cobro, emisión y envío digital de tickets por WhatsApp, y el posterior arqueo y corte de caja en tiempo real.

---

## 1. 🏢 Aislamiento Multi-Inquilino de Inventario por Negocio

### Problema Resuelto:
Cada usuario dado de alta en la plataforma corresponde a un negocio o sucursal diferente (por ejemplo, *Barber Dias*, *The Villain's Barber*, *Barbería Ganimedes*). Anteriormente, el catálogo era global y compartido.

### Solución Técnica:
1. **Ampliación de Esquema en PocketBase:**
   - Se agregaron los campos `branch_code` (código de sucursal) y `business_name` (nombre del negocio) a la colección `products_services`.
   - Se formalizó la migración permanente en [`backend/pb_migrations/1791008000_add_branch_to_products.js`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/backend/pb_migrations/1791008000_add_branch_to_products.js).
2. **Modelo de Datos (`PosItem`):**
   - Se actualizaron los campos `branchCode` y `businessName` en [`lib/models/mock_data.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/models/mock_data.dart) con serialización JSON completa y método `copyWith`.
3. **Servicio Reactivo (`PocketBaseService`):**
   - **`getProductsServices()`**: Aplica automáticamente el filtro `branch_code='$branchCode'`, de forma que cada usuario sólo consulta y administra los productos de su propio establecimiento.
   - **`createProductService()`**: Estampa automáticamente la sucursal y razón social del operador activo al registrar un nuevo ítem.
   - **`findProductByBarcode()`**: Busca el código de barras acotado a la sucursal activa.
   - **`getSales()` y `getNextFolio()`**: Las ventas y la numeración correlativa (`#TK-1001`, `#TK-1002`, etc.) quedan estrictamente aisladas por negocio.
4. **Migración de Productos Existentes:**
   - Los productos previamente registrados (*Corte de cabello*, *Cera de cabello*, *Cera fuerte mate*, *Toallas calientes*) quedaron asignados a `barber_dias`.
   - Cualquier nuevo usuario registrado comienza con su inventario limpio en ceros.

---

## 2. 🧾 Visor de Ticket Digital Térmico de 80mm

### Componente:
[`lib/widgets/pos/digital_ticket_viewer_dialog.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/widgets/pos/digital_ticket_viewer_dialog.dart)

### Características:
- **Estética de Impresora Térmica:** Simulación visual de papel continuo off-white (`#FBFBFB`) con muescas de guillotina superior/inferior, divisores punteados y tipografía proporcional.
- **Información del Negocio y Venta:**
  - Logotipo del giro y nombre comercial en mayúsculas.
  - Sucursal y leyenda fiscal simplificada.
  - Folio correlativo (`#TK-XXXXX`), fecha y hora exacta (`DD/MM/AAAA HH:mm`).
  - Nombre del cliente y operador que atendió la orden.
- **Tabla de Ítems Vendidos:**
  - Columnas: Cantidad (`CANT`), Nombre del Servicio/Producto (`DESCRIPCIÓN`) y Precio Liquidado (`TOTAL`).
  - Carga inmediata desde el carrito o consulta asíncrona mediante `PocketBaseService().getSaleItems(folio)` cuando se abre un ticket histórico desde Caja.
- **Totales y Finanzas:**
  - Subtotal, Descuentos aplicados y Total en Moneda Nacional (`$XXX.XX MXN`).
  - Forma de pago (Efectivo / Tarjeta Bancaria / Transferencia SPEI).
  - Efectivo recibido y cambio entregado.
- **Código de Barras Gráfico:**
  - Representación visual de barras térmicas con el folio impreso en tipografía monoespaciada.
- **Barra de Acciones Rápidas:**
  - 💬 **Enviar por WhatsApp:** Abre el diálogo de envío digital.
  - 📋 **Copiar Texto:** Copia el comprobante en formato texto plano estructurado al portapapeles.
  - 🖨️ **Imprimir:** Envío simulado o conexión a impresora térmica bluetooth/red.
  - ✖ **Cerrar:** Vuelve al flujo operativo.

---

## 3. 💬 Integración Directa con WhatsApp

### Componente:
[`lib/widgets/pos/send_ticket_whatsapp_dialog.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/widgets/pos/send_ticket_whatsapp_dialog.dart)

### Características:
- **Formato Digital Profesional:** Construye un mensaje con emojis, membrete, desglose de ítems, totales, detalles de pago y mensaje de cortesía.
- **Marcación Rápida:** Prefijo predeterminado para México (`+52`) con validación automática de número a 10 dígitos.
- **Lanzador de Aplicación:** Emplea `url_launcher` con URL Scheme prioritario (`whatsapp://send?phone=...&text=...`) y respaldo universal a `https://wa.me/`.
- **Permisos de Sistema:** Se declararon las consultas de paquetes e intents en [`android/app/src/main/AndroidManifest.xml`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/android/app/src/main/AndroidManifest.xml) para asegurar compatibilidad total con Android 11+ (`queries` para `com.whatsapp` y `com.whatsapp.w4b`).
- **Respaldo:** En caso de que el cliente no cuente con la app instalada en la terminal, cuenta con botón para copiar el texto íntegro.

---

## 4. 💰 Módulo de Caja, Arqueo y Corte Z

### Pantalla:
[`lib/screens/cash_register_screen.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/screens/cash_register_screen.dart)

### Funcionalidades Añadidas:
1. **Desglose de Formas de Pago:**
   - Efectivo Registrado en Turno.
   - Terminal Bancaria (Clip / Stripe).
   - Transferencia SPEI / QR.
2. **Listado de Tickets del Turno:**
   - Muestra en tiempo real todos los tickets emitidos en la base de datos para el turno del negocio activo.
   - Muestra folio, hora, cliente, barbero y badge del método de pago.
   - Botones directos en cada tarjeta para **"Ver Ticket"** y **"WhatsApp"**.
3. **Cierre de Turno / Corte Z Interactivo:**
   - Ventana modal con resumen financiero: Ventas totales, número de tickets, fondo inicial de gaveta, efectivo esperado, tarjeta y SPEI.
   - Campo para capturar el **efectivo físico contado**.
   - Cálculo en tiempo real de diferencia:
     - 🟢 **Arqueo Exacto ($0.00)**
     - 🔵 **Sobrante en Gaveta (+$X.XX)**
     - 🟠 **Faltante en Gaveta (-$X.XX)**
   - Campo de notas u observaciones.
   - Registro permanente del reporte en la colección `cash_shifts` de PocketBase.
   - Reinicio del estado de gaveta y arqueo a ceros para el siguiente turno.

---

## 5. 📦 Alta Rápida de Productos y Escáner de Código de Barras

### Componentes:
- [`lib/widgets/modals/create_product_modal.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/widgets/modals/create_product_modal.dart)
- [`lib/widgets/scanner/barcode_scanner_dialog.dart`](file:///home/orion/Documentos/desarrollos/ganimedes2.0/ganimedes/lib/widgets/scanner/barcode_scanner_dialog.dart)

### Flujo:
- **Servicios (Sin código de barras):** Genera automáticamente un SKU/ID legible basado en el texto ingresado (ej. "Corte de cabello" $\rightarrow$ `CORTE-DE-CABELLO`).
- **Productos Físicos:** Permite capturar o escanear el código de barras con la cámara del dispositivo mediante `mobile_scanner`, asignando stock y alerta de stock mínimo.

---

## 6. 🛠️ Estabilidad y Conectividad del Backend

- **Optimización de Consultas PocketBase:** Se eliminó el parámetro de ordenamiento `sort=-created` que originaba respuestas HTTP 400 Bad Request en PocketBase, implementando la ordenación en memoria para mantener siempre los registros más recientes en la parte superior.
- **Manejo Silencioso de Colecciones Nuevas:** Se suprimieron las alertas intrusivas de desconexión cuando un negocio nuevo no tiene productos o tickets creados.
- **Túnel de Red Local:** Configuración permanente de `adb reverse tcp:8090 tcp:8090` para que el teléfono físico se comunique con el backend en la computadora como `127.0.0.1:8090`.

---

## 7. 🚀 Estado de Calidad y Compilación

- **Análisis Estático de Código (`dart analyze` / `analyze_files`):** **0 errores**.
- **Compilación de Android Debug APK:** **Exitosa (Código 0)**.
  - Artefacto generado: `ganimedes/build/app/outputs/flutter-apk/app-debug.apk`
- **Despliegue Físico:** Probado e instalado en **Google Pixel 7 (Android 14/15)**.

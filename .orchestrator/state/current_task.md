# TAREA ACTUAL: 12_COPILOT_FULLSCREEN_ROUTE

**Asignada a:** Worker 2 (Flutter)  
**Ciclo:** Fase B (Frontend Flutter) con validación por Debugger  
**Estado:** pendiente  
**Estimado:** ~35 líneas modificadas en 2 archivos  
**Referencia:** `especificaci_n_t_cnica_copilot_fullscreen.md`

---

## Diagnóstico completo (por qué el parche anterior no es suficiente)

La corrección de `mainAxisSize` (tarea 11) resolvió el overflow del modal de comisiones, pero la causa raíz sistémica permanece: `AiAssistantScreen` vive en un `IndexedStack` dentro de un `Scaffold` que comparte espacio con `FloatingDock` y `AppTopBar`. Al enfocar el `TextField`:

- `resizeToAvoidBottomInset: false` obliga al cálculo manual de `inputBottom` y `listBottomPadding`.
- Si `DeviceBreakpoints.isKeyboardOpen` falla o el cálculo es incorrecto para el dispositivo, la barra de input tapa los mensajes y/o aparecen overflows.

**Solución definitiva:** Convertir `AiAssistantScreen` en una ruta a pantalla completa (`Navigator.push`), liberarla del `IndexedStack` y permitir que Flutter maneje el teclado con `resizeToAvoidBottomInset: true`.

---

## Cambios requeridos

### Archivo 1: `ganimedes/lib/screens/main_shell.dart`

**A. Modificar `_onTabSelected`** para que el índice 4 (Copilot) abra la ruta en lugar de cambiar el índice:

```dart
void _onTabSelected(int index) {
  if (index == 4) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiAssistantScreen(
          onNavigateToTab: (tabIndex) {
            Navigator.of(context).pop();
            _onTabSelected(tabIndex);
          },
        ),
      ),
    );
    return;
  }
  setState(() => _currentIndex = index);
  if (index == 0) {
    _dashboardKey.currentState?.reloadMetrics();
  } else if (index == 1) {
    _posKey.currentState?.reloadCatalog();
  } else if (index == 2) {
    _inventoryKey.currentState?.reloadData();
  } else if (index == 3) {
    _cashRegisterKey.currentState?.reloadSummary();
  }
}
```

**B. Eliminar `AiAssistantScreen` del `IndexedStack`** (quedará con 4 hijos: índices 0-3):

```dart
// ELIMINAR este hijo del IndexedStack:
AiAssistantScreen(
  onNavigateToTab: _onTabSelected,
),
```

**C. Ajustar sanitización de índices** — eliminar las referencias a índice 4:

```dart
// ANTES:
if (!isAdmin && safeIndex == 4) safeIndex = 1;

// ELIMINAR esa línea — índice 4 ya no existe en IndexedStack
```

También en `_onSwitchOperator`:
```dart
// ANTES:
if (!pb.isAdmin && _currentIndex == 4) _currentIndex = 1;

// ELIMINAR esa línea
```

---

### Archivo 2: `ganimedes/lib/screens/ai_assistant_screen.dart`

**A. Cambiar `resizeToAvoidBottomInset`** de `false` a `true` en el `Scaffold` del método `build` (línea ~644).

**B. Reemplazar el layout principal** del `body` — pasar de `Stack + Positioned` a `Column` simple:

```dart
body: SafeArea(
  child: Column(
    children: [
      _buildHeaderCard(shift, barberName, chair),
      _buildStatusRow(),
      Expanded(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageItem(_messages[index]),
            ),
          ),
        ),
      ),
      // Chips de sugerencias (visibles solo cuando no hay texto enviando)
      if (!_isSending)
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _quickSuggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) => _buildSuggestionChip(_quickSuggestions[index]),
          ),
        ),
      // Barra de input fija sobre el teclado
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: _buildInputRow(),
      ),
    ],
  ),
),
```

**C. Extraer el chip de sugerencia a un método auxiliar** `_buildSuggestionChip(String suggestion)` con el widget existente en `_buildFloatingInputBar`.

**D. Extraer la fila de input** a un método auxiliar `_buildInputRow()` con el `Row` del `TextField` + botón de envío ya existente en `_buildFloatingInputBar`.

**E. Eliminar las variables calculadas que ya no se necesitan** en el método `build`:
- `isKeyboardOpen`, `isCompact`, `bottomInset`, `listBottomPadding`, `inputBottom`

**F. Eliminar el método `_buildFloatingInputBar`** una vez extraídos sus componentes a los dos métodos auxiliares.

---

## Contratos técnicos clave

| Invariante | Detalle |
|------------|---------|
| `onNavigateToTab` en ruta fullscreen | Debe hacer `Navigator.pop` primero, luego llamar `_onTabSelected(tabIndex)` en el shell |
| `resizeToAvoidBottomInset: true` | Flutter maneja el desplazamiento del teclado; no se necesita cálculo manual |
| `IndexedStack` con 4 hijos | Índices 0 (Dashboard), 1 (POS), 2 (Inventory), 3 (CashRegister) |
| Scroll al fondo | `_scrollToBottom()` sigue funcionando igual con el nuevo `ListView` |
| `SafeArea` en fullscreen | `top: true, bottom: true` para la ruta independiente |

---

## Archivos a modificar

| Ruta | Cambio estimado |
|------|----------------|
| `ganimedes/lib/screens/main_shell.dart` | ~12 líneas (eliminar hijo IndexedStack, modificar `_onTabSelected`, eliminar 2 guards de índice 4) |
| `ganimedes/lib/screens/ai_assistant_screen.dart` | ~25 líneas (cambiar `resizeToAvoidBottomInset`, reemplazar body, extraer 2 métodos auxiliares, eliminar 5 variables) |

---

## Archivos protegidos (NO tocar)

- `ganimedes/lib/widgets/floating_dock.dart`
- `ganimedes/lib/services/ai_chat_service.dart`
- `ganimedes/lib/services/pocketbase_service.dart`
- `ganimedes/lib/utils/device_breakpoints.dart`
- `agente-ia/` (cualquier archivo)
- `backend/` (cualquier archivo)
- `.orchestrator/` (cualquier archivo)

---

## Criterios de aceptación — Worker 2

1. `flutter analyze` sin errores nuevos.
2. El tap en el botón Copilot del `FloatingDock` abre `AiAssistantScreen` en pantalla completa (se puede ver el `BackButton` del `AppBar` o una flecha de retroceso nativa de Android).
3. El `IndexedStack` tiene exactamente 4 hijos; el índice 4 ya no existe en él.
4. Al enfocar el `TextField` del chat, el teclado sube y la barra de input queda visible encima sin cálculos manuales.
5. Los botones de acción "Aplicar combo a siguiente orden" y "Añadir 1 al ticket actual" en las tarjetas del chat: al tocarse, cierran la ruta de Copilot y navegan al tab correcto (POS/Inventario) en el shell.

---

## Fase de validación — Debugger Agent

Tras el `flutter analyze` limpio de Worker 2:

```bash
# 1. Hot Reload o inicio
/home/orion/orca/workspaces/ganimedes2.0/debugger/scripts/flutter_manager.sh reload

# 2. Capturar logs por 10 segundos tras abrir Copilot y enfocar el TextField
/home/orion/orca/workspaces/ganimedes2.0/debugger/scripts/flutter_manager.sh logs 40

# 3. Capturar solo errores
/home/orion/orca/workspaces/ganimedes2.0/debugger/scripts/flutter_manager.sh errors
```

**Puntos de verificación en `debug_report.md`:**
- Sin `RenderFlex overflowed` al abrir Copilot.
- Sin `RenderFlex overflowed` al enfocar el TextField y abrir el teclado.
- Sin `setState() called after dispose()` al navegar de regreso al shell.
- Sin `unbounded height` en ningún widget de `ai_assistant_screen.dart`.
- La URL de DevTools reportada para inspección adicional si se requiere.

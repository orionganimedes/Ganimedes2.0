# Solución UI: Copilot IA FullScreen Route

## 1. Diagnóstico y Fundamento
- **Espacio Vertical Óptimo:** La UI conversacional requiere el 100% del alto disponible. Al abrir el teclado virtual en Android, mantener un `BottomNavigationBar` reduce drásticamente el área útil del historial y detona excepciones de `RenderFlex overflow`.
- **Eliminación de Redundancia:** Resuelve la colisión entre el menú lateral flotante, la barra de pestañas (POS, Inventario, Caja, Copilot) y la caja de texto del chat.
- **Arquitectura Limpia:** Evita condicionales sobre `bottomNavigationBar` en el shell principal. Copilot pasa a ser un módulo independiente con su propio `BackButton`.

---

## 2. Implementación Técnica

### A. Apertura como Ruta Independiente (`HomeScreen` / Shell)
```dart
// En lugar de alternar el índice en BottomNavigationBar / IndexedStack:
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const AiAssistantScreen(),
  ),
);
```

### B. Estructura de `AiAssistantScreen` (`ai_assistant_screen.dart`)
```dart
Scaffold(
  resizeToAvoidBottomInset: true, // Permite que el teclado empuje la caja sin desbordar
  appBar: AppBar(
    title: const Text('Copilot IA'),
  ),
  body: Column(
    children: [
      Expanded(
        child: ListView.builder(
          // Historial de mensajes elástico
        ),
      ),
      const InputChatBar(), // Barra inferior de entrada fija sobre el teclado
    ],
  ),
)
```

---

## 3. Directiva para Claude Code (`arquitecto`)

Copiar en el prompt del Arquitecto:

```text
Decisión de diseño para resolver el desbordamiento en Copilot IA:
Adoptamos el Enfoque A (Ruta dedicada a pantalla completa con Navigator.push).

Por favor, define la tarea en current_task.md para WORKER 2:
1. Retirar AiAssistantScreen del BottomNavigationBar/IndexedStack del shell principal.
2. Hacer que el botón de Copilot abra AiAssistantScreen como una ruta independiente con Navigator.push().
3. Limpiar AiAssistantScreen para que no renderice la BottomNavigationBar, configure resizeToAvoidBottomInset: true y mantenga el historial dentro de un Expanded.
4. Worker 2 debe validar con `flutter analyze` y el Debugger Agent comprobará en el emulador que al enfocar el TextField no existan RenderFlex overflows.
```
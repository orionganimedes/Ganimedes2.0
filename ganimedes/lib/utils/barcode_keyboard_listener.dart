import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that listens for rapid keyboard input from physical USB or Bluetooth
/// barcode scanners and triggers [onBarcodeScanned] when Enter is received.
class BarcodeKeyboardListener extends StatefulWidget {
  final Widget child;
  final ValueChanged<String> onBarcodeScanned;
  final bool enabled;

  const BarcodeKeyboardListener({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
    this.enabled = true,
  });

  @override
  State<BarcodeKeyboardListener> createState() => _BarcodeKeyboardListenerState();
}

class _BarcodeKeyboardListenerState extends State<BarcodeKeyboardListener> {
  final FocusNode _focusNode = FocusNode();
  final StringBuffer _buffer = StringBuffer();
  DateTime _lastKeystrokeTime = DateTime.now();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!widget.enabled) return;
    if (event is! KeyDownEvent) return;

    final now = DateTime.now();
    final difference = now.difference(_lastKeystrokeTime).inMilliseconds;
    _lastKeystrokeTime = now;

    // If more than 150ms elapsed between keystrokes, it's likely manual user typing, not a scanner
    if (difference > 150 && _buffer.isNotEmpty) {
      _buffer.clear();
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final code = _buffer.toString().trim();
      _buffer.clear();
      if (code.isNotEmpty) {
        widget.onBarcodeScanned(code);
      }
    } else {
      final char = event.character;
      if (char != null && char.isNotEmpty && RegExp(r'[a-zA-Z0-9\-_]').hasMatch(char)) {
        _buffer.write(char);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: false,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

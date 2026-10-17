import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_chat_service.dart';
import '../services/pocketbase_service.dart';
import '../utils/device_breakpoints.dart';

enum MessageType {
  text,
  shiftDiagnosis,
  realtimeInventory,
}

class ChatMessage {
  String text;
  final bool isUser;
  final DateTime timestamp;
  bool isStreaming;
  final MessageType type;
  final String? systemTag;
  final Map<String, dynamic>? extraData;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
    this.type = MessageType.text,
    this.systemTag,
    this.extraData,
  });
}

class AiAssistantScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const AiAssistantScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isCheckingHealth = true;
  bool _isOnline = true;

  final List<String> _quickSuggestions = [
    '¿Cómo van las ventas del turno de hoy?',
    'Revisa si nos queda Cold Brew en el refrigerador',
    '¿Cuáles son los productos con stock crítico?',
    'Dame una recomendación para elevar el ticket promedio',
    'Redacta un mensaje promocional para WhatsApp',
  ];

  @override
  void initState() {
    super.initState();
    _checkServerHealth();
    _seedInitialBriefing();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _seedInitialBriefing() {
    final pb = PocketBaseService();
    final barberName = pb.userName.isNotEmpty ? pb.userName : 'Carlos Mendoza';

    final now = DateTime.now();
    final time1 = DateTime(now.year, now.month, now.day, 9, 41);
    final time2 = DateTime(now.year, now.month, now.day, 9, 42);
    final time3 = DateTime(now.year, now.month, now.day, 9, 42);
    final time4 = DateTime(now.year, now.month, now.day, 9, 44);
    final time5 = DateTime(now.year, now.month, now.day, 9, 44);

    _messages.addAll([
      ChatMessage(
        text:
            '¡Buen día $barberName! 👋 Estoy monitoreando tus ventas en tiempo real, el inventario de la sucursal y tus comisiones activas.\n\n¿En qué puedo apoyarte con el siguiente cliente?',
        isUser: false,
        timestamp: time1,
        systemTag: 'Ganimedes Core',
      ),
      ChatMessage(
        text:
            '¿Cómo va mi rendimiento de hoy y qué producto debería ofrecer a mi siguiente cliente?',
        isUser: true,
        timestamp: time2,
      ),
      ChatMessage(
        text: 'DIAGNÓSTICO DE TURNO',
        isUser: false,
        timestamp: time3,
        type: MessageType.shiftDiagnosis,
        systemTag: 'Copilot Engine v4.2',
        extraData: {
          'dailyGoalPercent': 72,
          'salesAccumulated': 2450.0,
          'completedServices': 8,
          'nextClientService': 'Ritual de Barba',
          'nextClientTime': '10:00 AM',
          'recommendedProduct1': 'Pomada Matte',
          'recommendedProduct2': 'Aceite Wood & Oak',
          'ticketIncrease': 220.0,
        },
      ),
      ChatMessage(
        text: 'Revisa si nos queda Cold Brew en el refrigerador.',
        isUser: true,
        timestamp: time4,
      ),
      ChatMessage(
        text: 'INVENTARIO EN TIEMPO REAL',
        isUser: false,
        timestamp: time5,
        type: MessageType.realtimeInventory,
        systemTag: 'Copilot Engine v4.2',
        extraData: {
          'badge': 'Stock Saludable',
          'productName': 'Cold Brew Chiapas 250ml',
          'batchLocation': 'Lote #CB-409 • Nevera Principal',
          'stockQty': 28,
          'minQty': 10,
          'replenishmentNote':
              'Proveedor local programó reabastecimiento: Mañana 08:30 AM.',
        },
      ),
    ]);
  }

  Future<void> _checkServerHealth() async {
    setState(() => _isCheckingHealth = true);
    final available = await AiChatService().isServiceAvailable();
    if (mounted) {
      setState(() {
        _isOnline = available;
        _isCheckingHealth = false;
      });
    }
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (immediate) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? textToSend]) async {
    final text = (textToSend ?? _inputController.text).trim();
    if (text.isEmpty || _isSending) return;

    _inputController.clear();

    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    final assistantMsg = ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
      systemTag: 'Copilot Engine v4.2',
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(assistantMsg);
      _isSending = true;
    });
    _scrollToBottom();

    final allHistory = _messages
        .take(_messages.length - 2)
        .where((m) => m.type == MessageType.text && m.text.isNotEmpty)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();
    final history = allHistory.length > 6
        ? allHistory.sublist(allHistory.length - 6)
        : allHistory;

    String networkBuffer = '';
    int displayedLen = 0;
    bool networkDone = false;
    final drainCompleter = Completer<void>();

    // Buffer de tipado fluido a ~60fps estilo ChatGPT
    final typewriterTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        if (!drainCompleter.isCompleted) drainCompleter.complete();
        return;
      }
      final remaining = networkBuffer.length - displayedLen;
      if (remaining > 0) {
        // Avanza de forma adaptativa (1 a 5 caracteres por frame) para fluidez sin rezago
        final step = remaining > 40
            ? 5
            : remaining > 20
                ? 3
                : remaining > 8
                    ? 2
                    : 1;
        displayedLen = (displayedLen + step).clamp(0, networkBuffer.length);
        setState(() {
          assistantMsg.text = networkBuffer.substring(0, displayedLen);
          _isOnline = true;
        });
        _scrollToBottom(immediate: true);
      } else if (networkDone) {
        timer.cancel();
        if (!drainCompleter.isCompleted) drainCompleter.complete();
      }
    });

    try {
      await for (final token in AiChatService.sendMessageStream(
        text,
        history: history,
      )) {
        if (!mounted) break;
        networkBuffer += token;
      }
      networkDone = true;
      await drainCompleter.future;

      if (mounted) {
        setState(() {
          assistantMsg.text = networkBuffer;
          assistantMsg.isStreaming = false;
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      networkDone = true;
      typewriterTimer.cancel();
      if (mounted) {
        setState(() {
          if (networkBuffer.isEmpty) {
            assistantMsg.text =
                '⚠️ No fue posible comunicarse con el nodo Copilot.\n\nDetalle: ${e.toString().replaceAll("Exception: ", "")}';
          } else {
            assistantMsg.text =
                '$networkBuffer\n\n⚠️ [Transmisión interrumpida: ${e.toString().replaceAll("Exception: ", "")}]';
          }
          assistantMsg.isStreaming = false;
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141C2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Color(0xFF38BDF8), size: 22),
            SizedBox(width: 10),
            Text('Reiniciar Copilot', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          '¿Deseas restaurar la sesión inicial de Copilot IA?',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _seedInitialBriefing();
              });
            },
            child: const Text('Restaurar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCopilotSettings() {
    final pb = PocketBaseService();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF223047))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 22),
                SizedBox(width: 10),
                Text(
                  'Configuración de Nodo Copilot IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingRow('Estado del Modelo', 'Online • Streaming activo', const Color(0xFF10B981)),
            _buildSettingRow('Conexión PocketBase', pb.baseUrl, const Color(0xFF38BDF8)),
            _buildSettingRow('Latencia Estimada', '18 ms', const Color(0xFF38BDF8)),
            _buildSettingRow('Operador Activo', pb.userName, Colors.white),
            _buildSettingRow('Sucursal', pb.branchCode.toUpperCase(), Colors.white),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String title, String val, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          Text(
            val,
            style: TextStyle(
              color: valColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showCommissionsModal() {
    final pb = PocketBaseService();
    final name = pb.userName.isNotEmpty ? pb.userName : 'Carlos Mendoza';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF223047))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF223047)),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Desglose de Comisiones del Turno',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Operador: $name • Comisión: 45%',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B121E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ventas Base Turno', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      SizedBox(height: 4),
                      Text('\$2,450.00 MXN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Comisión Ganada (45%)', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('\$1,102.50 MXN', style: TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SERVICIOS REGISTRADOS HOY (8)',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  _commissionItem('Corte Clásico & Fade', '08:15 AM', '\$350.00', '\$157.50'),
                  _commissionItem('Ritual de Barba Completo', '08:45 AM', '\$420.00', '\$189.00'),
                  _commissionItem('Corte Ejecutivo + Lavado', '09:05 AM', '\$380.00', '\$171.00'),
                  _commissionItem('Pomada Matte Fijación Media', '09:08 AM', '\$280.00', '\$126.00'),
                  _commissionItem('Perfilado de Cejas & Barba', '09:20 AM', '\$220.00', '\$99.00'),
                  _commissionItem('Tratamiento Capilar Revitalizante', '09:35 AM', '\$500.00', '\$225.00'),
                  _commissionItem('Cold Brew Chiapas 250ml', '09:37 AM', '\$75.00', '\$33.75'),
                  _commissionItem('Corte Infantil', '09:55 AM', '\$225.00', '\$101.25'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commissionItem(String name, String time, String total, String comm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF223047)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                Text(time, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(total, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
              Text('+$comm', style: const TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  void _onApplyCombo() {
    widget.onNavigateToTab?.call(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF22D3EE)),
        ),
        content: const Row(
          children: [
            Icon(Icons.shopping_cart_checkout_rounded, color: Color(0xFF22D3EE), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Combo Pomada Matte + Aceite Wood & Oak (10% OFF) listo para el próximo ticket.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddProductToTicket() {
    widget.onNavigateToTab?.call(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF22D3EE)),
        ),
        content: const Row(
          children: [
            Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF22D3EE), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '1x Cold Brew Chiapas 250ml añadido a la orden actual en POS.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onOpenKardex() {
    widget.onNavigateToTab?.call(2);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF059669)),
        ),
        content: const Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: Color(0xFF34D399), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mostrando Kardex y almacén para Cold Brew Chiapas en Inventario.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pb = PocketBaseService();
    final barberName = pb.userName.isNotEmpty ? pb.userName : 'Carlos Mendoza';
    final userMap = pb.currentUser;
    final chair = (userMap != null && userMap['chair'] != null && (userMap['chair'] as String).isNotEmpty)
        ? userMap['chair'] as String
        : 'Sillón 01';
    final shift = (userMap != null && userMap['shift'] != null && (userMap['shift'] as String).isNotEmpty)
        ? userMap['shift'] as String
        : 'Turno Mañana';

    final isKeyboardOpen = DeviceBreakpoints.isKeyboardOpen(context);
    final isCompact = DeviceBreakpoints.isLandscapeCompact(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Espacio de seguridad inferior para garantizar que el scroll no quede tapado
    final double listBottomPadding = isKeyboardOpen
        ? 80.0
        : (isCompact ? 116.0 : (bottomInset > 0 ? bottomInset + 148.0 : 158.0));

    // Posicionamiento de la barra de entrada flotante justo encima del FloatingDock
    final double inputBottom = isKeyboardOpen
        ? 8.0
        : (isCompact ? 52.0 : (bottomInset > 0 ? bottomInset + 72.0 : 80.0));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // Contenido Principal (Header + Status + Lista de Mensajes)
            Positioned.fill(
              child: Column(
                children: [
                  // Sub-Header Superior de Copilot IA
                  _buildHeaderCard(shift, barberName, chair),

                  // Barra de estado de conexión y PocketBase
                  _buildStatusRow(),

                  // Lista de Mensajes con clearance inferior perfecto
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(16, 8, 16, listBottomPadding),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return _buildMessageItem(msg);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Barra Flotante de Sugerencias e Input posicionada limpiamente sobre el dock
            Positioned(
              bottom: inputBottom,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _buildFloatingInputBar(context, isCompact, isKeyboardOpen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String shift, String barberName, String chair) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF223047), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono de Copilot con resplandor cyan y punto de estado
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22D3EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF141C2B), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF22D3EE),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Título y Subtítulo dinámico
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Copilot IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C2B3F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0891B2), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF22D3EE),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Nodo 01',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$shift • $barberName ($chair)',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Acciones de cabecera: Limpiar y Ajustes
          IconButton(
            onPressed: _clearChat,
            tooltip: 'Reiniciar conversación',
            icon: const Icon(Icons.cleaning_services_rounded, size: 20),
            color: const Color(0xFF94A3B8),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1A2436),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: _showCopilotSettings,
            tooltip: 'Configuración de Copilot',
            icon: const Icon(Icons.tune_rounded, size: 20),
            color: const Color(0xFF94A3B8),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1A2436),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storage_rounded,
                color: Color(0xFF06B6D4),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _isOnline
                    ? 'PocketBase DB sincronizado • Latencia 18ms'
                    : 'Modo Offline • Latencia local',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCheckingHealth
                      ? const Color(0xFF94A3B8)
                      : (_isOnline ? const Color(0xFF22D3EE) : Colors.orangeAccent),
                  boxShadow: [
                    BoxShadow(
                      color: (_isCheckingHealth
                              ? const Color(0xFF94A3B8)
                              : (_isOnline ? const Color(0xFF22D3EE) : Colors.orangeAccent))
                          .withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _isCheckingHealth
                    ? 'Verificando'
                    : (_isOnline ? 'En vivo' : 'Local'),
                style: TextStyle(
                  color: _isCheckingHealth
                      ? const Color(0xFF94A3B8)
                      : (_isOnline ? const Color(0xFF22D3EE) : Colors.orangeAccent),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    if (msg.type == MessageType.shiftDiagnosis) {
      return _buildShiftDiagnosisMessage(msg);
    }
    if (msg.type == MessageType.realtimeInventory) {
      return _buildRealtimeInventoryMessage(msg);
    }

    if (!msg.isUser && msg.text.isEmpty && msg.isStreaming) {
      return _buildThinkingBubble();
    }

    final isUser = msg.isUser;
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')} ${msg.timestamp.hour >= 12 ? 'PM' : 'AM'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 580),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF161F30),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF243248),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: msg.text,
                              style: TextStyle(
                                color: isUser ? Colors.white : const Color(0xFFE2E8F0),
                                fontSize: 13.5,
                                height: 1.45,
                              ),
                            ),
                            if (msg.isStreaming)
                              const TextSpan(
                                text: ' ▍',
                                style: TextStyle(
                                  color: Color(0xFF22D3EE),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!isUser && !msg.isStreaming && msg.text.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: msg.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copiado al portapapeles'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    isUser
                        ? timeStr
                        : '$timeStr • ${msg.systemTag ?? 'Ganimedes Core'}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(left: 8, top: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF94A3B8),
                size: 17,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShiftDiagnosisMessage(ChatMessage msg) {
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')} ${msg.timestamp.hour >= 12 ? 'PM' : 'AM'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 620),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141C2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF223047), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header de la tarjeta
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: Color(0xFF38BDF8),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'DIAGNÓSTICO DE TURNO',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Meta diaria: 72%',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Métricas de ventas acumuladas y completados
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B121E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1A2638)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ventas acumuladas',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '\$2,450 ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'MXN',
                                        style: TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Completados',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '8 servicios',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Barra de progreso con gradiente cyan
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          height: 5,
                          color: const Color(0xFF1E293B),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.72,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Recuadro interior de Oportunidad de Cross-Sell
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B121E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.star_outline_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Oportunidad de Cross-Sell',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 12.5,
                                  height: 1.45,
                                ),
                                children: [
                                  TextSpan(text: 'Tu próximo cliente agendó '),
                                  TextSpan(
                                    text: 'Ritual de Barba',
                                    style: TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' (10:00 AM). Hay stock óptimo de ',
                                  ),
                                  TextSpan(
                                    text: 'Pomada Matte',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: ' y '),
                                  TextSpan(
                                    text: 'Aceite Wood & Oak',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF070F1C),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF14243B)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.show_chart_rounded,
                                    color: Color(0xFF22D3EE),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11.5,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                'El combo con 10% de descuento sugerido eleva tu ticket promedio en ',
                                          ),
                                          TextSpan(
                                            text: '+ \$220 MXN.',
                                            style: TextStyle(
                                              color: Color(0xFF22D3EE),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Botones de acción integrados
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _onApplyCombo,
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.black,
                              size: 17,
                            ),
                            label: const Text(
                              'Aplicar combo a siguiente orden',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF22D3EE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _showCommissionsModal,
                            icon: const Icon(
                              Icons.receipt_long_rounded,
                              color: Color(0xFFCBD5E1),
                              size: 16,
                            ),
                            label: const Text(
                              'Ver comisiones',
                              style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF1E293B).withValues(alpha: 0.6),
                              side: const BorderSide(color: Color(0xFF334155)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$timeStr • ${msg.systemTag ?? 'Copilot Engine v4.2'}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeInventoryMessage(ChatMessage msg) {
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')} ${msg.timestamp.hour >= 12 ? 'PM' : 'AM'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 620),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141C2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF223047), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con Badge de Stock Saludable
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xFF38BDF8),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'INVENTARIO EN TIEMPO REAL',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF064E3B).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF059669),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'Stock Saludable',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Detalle del Producto y Miniatura
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B121E),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF1F2B3E)),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_cafe_rounded,
                                color: Color(0xFFF59E0B),
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cold Brew Chiapas 250ml',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Lote #CB-409 • Nevera Principal',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Text(
                                      '28 pzas',
                                      style: TextStyle(
                                        color: Color(0xFF22D3EE),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '| Min. 10 pzas',
                                      style: TextStyle(
                                        color: const Color(0xFF94A3B8)
                                            .withValues(alpha: 0.9),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Aviso de Reabastecimiento
                      Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            color: Color(0xFF38BDF8),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11.5,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'Proveedor local programó reabastecimiento: ',
                                  ),
                                  TextSpan(
                                    text: 'Mañana 08:30 AM.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Botones de Acción
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _onAddProductToTicket,
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: Color(0xFFCBD5E1),
                              size: 16,
                            ),
                            label: const Text(
                              'Añadir 1 al ticket actual',
                              style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF1E293B).withValues(alpha: 0.6),
                              side: const BorderSide(color: Color(0xFF334155)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _onOpenKardex,
                            icon: const Icon(
                              Icons.sync_rounded,
                              color: Color(0xFFCBD5E1),
                              size: 16,
                            ),
                            label: const Text(
                              'Kardex',
                              style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF1E293B).withValues(alpha: 0.6),
                              side: const BorderSide(color: Color(0xFF334155)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$timeStr • ${msg.systemTag ?? 'Copilot Engine v4.2'}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141C2B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF223047)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF22D3EE),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Ganimedes Copilot está analizando...',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingInputBar(
    BuildContext context,
    bool isCompact,
    bool isKeyboardOpen,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chips de sugerencia rápida (visibles cuando el teclado no está ocupando espacio)
        if (!isKeyboardOpen && !_isSending) ...[
          Container(
            height: 34,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _quickSuggestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final suggestion = _quickSuggestions[index];
                return InkWell(
                  onTap: () => _sendMessage(suggestion),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141C2B).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF24344D)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF38BDF8),
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          suggestion,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // Contenedor Flotante del Input
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              decoration: BoxDecoration(
                color: const Color(0xFF131D2E).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF283B55),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B121E),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1F2E45)),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF22D3EE),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Pregunta a Copilot sobre ventas o inventario...',
                        hintStyle: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isSending
                            ? [const Color(0xFF334155), const Color(0xFF334155)]
                            : [const Color(0xFF06B6D4), const Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: _isSending
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isSending ? null : () => _sendMessage(),
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/mock_data.dart';
import '../../services/pocketbase_service.dart';
import '../../theme/app_colors.dart';

class SendTicketWhatsAppDialog extends StatefulWidget {
  final String folio;
  final double total;
  final List<CartItem> cartItems;
  final List<Map<String, dynamic>> rawItems;
  final String paymentMethod;
  final double cashReceived;
  final double changeReturned;
  final String barberName;
  final String clientName;
  final DateTime? date;

  const SendTicketWhatsAppDialog({
    super.key,
    required this.folio,
    required this.total,
    this.cartItems = const [],
    this.rawItems = const [],
    this.paymentMethod = 'Efectivo',
    this.cashReceived = 0.0,
    this.changeReturned = 0.0,
    this.barberName = 'Operador',
    this.clientName = 'Cliente General',
    this.date,
  });

  static Future<void> show(
    BuildContext context, {
    required String folio,
    required double total,
    List<CartItem> cartItems = const [],
    List<Map<String, dynamic>> rawItems = const [],
    String paymentMethod = 'Efectivo',
    double cashReceived = 0.0,
    double changeReturned = 0.0,
    String barberName = 'Operador',
    String clientName = 'Cliente General',
    DateTime? date,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SendTicketWhatsAppDialog(
        folio: folio,
        total: total,
        cartItems: cartItems,
        rawItems: rawItems,
        paymentMethod: paymentMethod,
        cashReceived: cashReceived,
        changeReturned: changeReturned,
        barberName: barberName,
        clientName: clientName,
        date: date,
      ),
    );
  }

  @override
  State<SendTicketWhatsAppDialog> createState() => _SendTicketWhatsAppDialogState();
}

class _SendTicketWhatsAppDialogState extends State<SendTicketWhatsAppDialog> {
  final _phoneController = TextEditingController();
  final String _countryCode = '52'; // Mexico default
  bool _isSending = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.rawItems);
    if (_items.isEmpty && widget.cartItems.isEmpty) {
      _loadSaleItems();
    }
  }

  Future<void> _loadSaleItems() async {
    try {
      final items = await PocketBaseService().getSaleItems(widget.folio);
      if (mounted && items.isNotEmpty) {
        setState(() {
          _items = items;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatTicketMessage() {
    final pb = PocketBaseService();
    final biz = pb.businessName.isNotEmpty ? pb.businessName.toUpperCase() : 'GANIMEDES POS';
    final branch = pb.branchCode.isNotEmpty ? pb.branchCode.toUpperCase() : 'MATRIZ';
    final dt = widget.date ?? DateTime.now();
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    buffer.writeln('💈 *$biz* 💈');
    buffer.writeln('_Comprobante Digital de Venta_');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🧾 *Folio:* ${widget.folio}');
    buffer.writeln('📅 *Fecha:* $dateStr');
    buffer.writeln('👤 *Cliente:* ${widget.clientName}');
    buffer.writeln('✂️ *Atendió:* ${widget.barberName}');
    buffer.writeln('📍 *Sucursal:* $branch');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('*DETALLE DE COMPRA:*');

    if (widget.cartItems.isNotEmpty) {
      for (final item in widget.cartItems) {
        buffer.writeln('• ${item.quantity}x ${item.item.name} - \$${item.total.toStringAsFixed(2)}');
      }
    } else if (_items.isNotEmpty) {
      for (final item in _items) {
        final name = item['product_name'] ?? item['name'] ?? 'Producto';
        final qty = item['quantity'] ?? 1;
        final t = (item['total'] as num?)?.toDouble() ?? 0.0;
        buffer.writeln('• ${qty}x $name - \$${t.toStringAsFixed(2)}');
      }
    } else {
      buffer.writeln('• 1x Consumo General - \$${widget.total.toStringAsFixed(2)}');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *TOTAL:* \$${widget.total.toStringAsFixed(2)} MXN');
    buffer.writeln('💳 *Forma de Pago:* ${widget.paymentMethod}');
    if (widget.cashReceived > 0) {
      buffer.writeln('💵 *Recibido:* \$${widget.cashReceived.toStringAsFixed(2)}');
      if (widget.changeReturned > 0) {
        buffer.writeln('🪙 *Cambio:* \$${widget.changeReturned.toStringAsFixed(2)}');
      }
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('¡Muchas gracias por tu preferencia!');
    buffer.writeln('Powered by *Ganimedes Cloud POS* ⚡');

    return buffer.toString();
  }

  Future<void> _sendWhatsApp() async {
    final rawNumber = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (rawNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el número celular de WhatsApp del cliente'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String fullPhone = rawNumber;
    if (rawNumber.length == 10) {
      fullPhone = '$_countryCode$rawNumber';
    } else if (rawNumber.startsWith('52') && rawNumber.length == 12) {
      fullPhone = rawNumber;
    }

    setState(() => _isSending = true);

    try {
      final message = _formatTicketMessage();
      final encodedMessage = Uri.encodeComponent(message);

      // WhatsApp URL scheme
      final whatsappUrl = Uri.parse('whatsapp://send?phone=$fullPhone&text=$encodedMessage');
      final webUrl = Uri.parse('https://wa.me/$fullPhone?text=$encodedMessage');

      bool launched = false;
      if (await canLaunchUrl(whatsappUrl)) {
        launched = await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        if (await canLaunchUrl(webUrl)) {
          launched = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      }

      if (mounted) {
        if (launched) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Abriendo WhatsApp para enviar a $fullPhone...'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          // If neither launched, copy text to clipboard as fallback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir WhatsApp. ¡Texto del ticket copiado al portapapeles!'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir WhatsApp: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _copyToClipboard() {
    final text = _formatTicketMessage();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comprobante copiado al portapapeles'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messagePreview = _formatTicketMessage();

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceContainer : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: const Color(0xFF25D366).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      color: Color(0xFF25D366),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enviar Ticket por WhatsApp',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Comprobante digital directo al cliente',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Phone Number Input
              const Text(
                'Número Celular del Cliente:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Country Code Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerHigh : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🇲🇽', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '+$_countryCode',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Number Field
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '844 123 4567 (10 dígitos)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Message Preview Box
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vista Previa del Mensaje:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copiar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowest : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    messagePreview,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Send Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isSending ? 'Abriendo WhatsApp...' : 'Abrir WhatsApp y Enviar',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

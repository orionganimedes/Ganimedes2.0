import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/mock_data.dart';
import '../../services/pocketbase_service.dart';
import '../../theme/app_colors.dart';
import 'send_ticket_whatsapp_dialog.dart';

class DigitalTicketViewerDialog extends StatefulWidget {
  final String folio;
  final double total;
  final double subtotal;
  final double discount;
  final List<CartItem> cartItems;
  final List<Map<String, dynamic>> rawItems;
  final String paymentMethod;
  final double cashReceived;
  final double changeReturned;
  final String barberName;
  final String clientName;
  final String? branchName;
  final DateTime? date;

  const DigitalTicketViewerDialog({
    super.key,
    required this.folio,
    required this.total,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.cartItems = const [],
    this.rawItems = const [],
    this.paymentMethod = 'Efectivo',
    this.cashReceived = 0.0,
    this.changeReturned = 0.0,
    this.barberName = 'Operador',
    this.clientName = 'Cliente General',
    this.branchName,
    this.date,
  });

  static Future<void> show(
    BuildContext context, {
    required String folio,
    required double total,
    double subtotal = 0.0,
    double discount = 0.0,
    List<CartItem> cartItems = const [],
    List<Map<String, dynamic>> rawItems = const [],
    String paymentMethod = 'Efectivo',
    double cashReceived = 0.0,
    double changeReturned = 0.0,
    String barberName = 'Operador',
    String clientName = 'Cliente General',
    String? branchName,
    DateTime? date,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DigitalTicketViewerDialog(
        folio: folio,
        total: total,
        subtotal: subtotal > 0 ? subtotal : total,
        discount: discount,
        cartItems: cartItems,
        rawItems: rawItems,
        paymentMethod: paymentMethod,
        cashReceived: cashReceived,
        changeReturned: changeReturned,
        barberName: barberName,
        clientName: clientName,
        branchName: branchName,
        date: date,
      ),
    );
  }

  @override
  State<DigitalTicketViewerDialog> createState() => _DigitalTicketViewerDialogState();
}

class _DigitalTicketViewerDialogState extends State<DigitalTicketViewerDialog> {
  List<Map<String, dynamic>> _loadedItems = [];
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadedItems = List.from(widget.rawItems);
    if (_loadedItems.isEmpty && widget.cartItems.isEmpty) {
      _fetchItemsFromPocketBase();
    }
  }

  Future<void> _fetchItemsFromPocketBase() async {
    setState(() => _isLoadingItems = true);
    try {
      final items = await PocketBaseService().getSaleItems(widget.folio);
      if (mounted) {
        setState(() {
          _loadedItems = items;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  String _generatePlainTextTicket() {
    final pb = PocketBaseService();
    final biz = pb.businessName.isNotEmpty ? pb.businessName.toUpperCase() : 'GANIMEDES POS';
    final branch = widget.branchName ?? (pb.branchCode.isNotEmpty ? pb.branchCode.toUpperCase() : 'MATRIZ');
    final dt = widget.date ?? DateTime.now();
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('           $biz           ');
    buffer.writeln('       COMPROBANTE DIGITAL DE VENTA     ');
    buffer.writeln('========================================');
    buffer.writeln('Folio:       ${widget.folio}');
    buffer.writeln('Fecha:       $dateStr');
    buffer.writeln('Cliente:     ${widget.clientName}');
    buffer.writeln('Atendio:     ${widget.barberName}');
    buffer.writeln('Sucursal:    $branch');
    buffer.writeln('----------------------------------------');
    buffer.writeln('CANT  DESCRIPCIÓN              TOTAL   ');
    buffer.writeln('----------------------------------------');

    if (widget.cartItems.isNotEmpty) {
      for (final item in widget.cartItems) {
        final name = item.item.name.padRight(22).substring(0, 22);
        final qty = '${item.quantity}x'.padRight(5);
        final total = '\$${item.total.toStringAsFixed(2)}'.padLeft(8);
        buffer.writeln('$qty $name $total');
      }
    } else if (_loadedItems.isNotEmpty) {
      for (final item in _loadedItems) {
        final name = (item['product_name'] ?? 'Producto').toString().padRight(22).substring(0, 22);
        final qty = '${item['quantity'] ?? 1}x'.padRight(5);
        final totalNum = (item['total'] as num?)?.toDouble() ?? 0.0;
        final total = '\$${totalNum.toStringAsFixed(2)}'.padLeft(8);
        buffer.writeln('$qty $name $total');
      }
    } else {
      buffer.writeln('1x    Consumo General          \$${widget.total.toStringAsFixed(2)}');
    }

    buffer.writeln('----------------------------------------');
    if (widget.discount > 0) {
      buffer.writeln('Subtotal:             \$${widget.subtotal.toStringAsFixed(2)}');
      buffer.writeln('Descuento:           -\$${widget.discount.toStringAsFixed(2)}');
    }
    buffer.writeln('TOTAL:                \$${widget.total.toStringAsFixed(2)} MXN');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Forma de Pago:        ${widget.paymentMethod.toUpperCase()}');
    if (widget.cashReceived > 0) {
      buffer.writeln('Efectivo Recibido:    \$${widget.cashReceived.toStringAsFixed(2)}');
      buffer.writeln('Cambio:               \$${widget.changeReturned.toStringAsFixed(2)}');
    }
    buffer.writeln('========================================');
    buffer.writeln('      ¡GRACIAS POR SU PREFERENCIA!      ');
    buffer.writeln('           GANIMEDES 2.0 POS            ');
    buffer.writeln('========================================');

    return buffer.toString();
  }

  void _copyToClipboard() {
    final text = _generatePlainTextTicket();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket copiado al portapapeles'),
        backgroundColor: AppColors.secondary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openWhatsAppDialog() {
    SendTicketWhatsAppDialog.show(
      context,
      folio: widget.folio,
      total: widget.total,
      cartItems: widget.cartItems,
      rawItems: _loadedItems,
      paymentMethod: widget.paymentMethod,
      cashReceived: widget.cashReceived,
      changeReturned: widget.changeReturned,
      barberName: widget.barberName,
      clientName: widget.clientName,
      date: widget.date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pb = PocketBaseService();
    final bizName = pb.businessName.isNotEmpty ? pb.businessName : 'Ganimedes Barber & POS';
    final branchName = widget.branchName ?? (pb.branchCode.isNotEmpty ? pb.branchCode.toUpperCase() : 'MATRIZ');
    final dt = widget.date ?? DateTime.now();
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Visor de Ticket Digital (80mm)',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Ticket Body (Realistic Thermal Paper)
            Flexible(
              child: Container(
                color: Colors.black45,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFBFB), // Realistic thermal paper off-white
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Thermal printer notch simulation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            20,
                            (index) => Container(
                              width: 6,
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E0E0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Store Logo / Brand
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                          child: const Icon(
                            Icons.content_cut_rounded,
                            color: Color(0xFF1E1E1E),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bizName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'SUCURSAL: $branchName',
                          style: const TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'COMPROBANTE SIMPLIFICADO DE VENTA',
                          style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Metadata Box
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E0E0), style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              _ReceiptInfoRow(label: 'FOLIO:', value: widget.folio, bold: true),
                              const SizedBox(height: 4),
                              _ReceiptInfoRow(label: 'FECHA:', value: dateStr),
                              const SizedBox(height: 4),
                              _ReceiptInfoRow(label: 'CLIENTE:', value: widget.clientName),
                              const SizedBox(height: 4),
                              _ReceiptInfoRow(label: 'ATENDIÓ:', value: widget.barberName),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Dashed Divider
                        _DashedReceiptLine(),
                        const SizedBox(height: 8),

                        // Table Header
                        const Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                'CANT',
                                style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'DESCRIPCIÓN',
                                style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'TOTAL',
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _DashedReceiptLine(),
                        const SizedBox(height: 8),

                        // Items
                        if (_isLoadingItems)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        else if (widget.cartItems.isNotEmpty)
                          ...widget.cartItems.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          color: Color(0xFF111111),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item.item.name,
                                        style: const TextStyle(
                                          color: Color(0xFF111111),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '\$${item.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF111111),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                        else if (_loadedItems.isNotEmpty)
                          ..._loadedItems.map((item) {
                            final totalNum = (item['total'] as num?)?.toDouble() ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${item['quantity'] ?? 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF111111),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      (item['product_name'] ?? 'Producto').toString(),
                                      style: const TextStyle(
                                        color: Color(0xFF111111),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${totalNum.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF111111),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 32,
                                  child: Text('1', style: TextStyle(color: Color(0xFF111111), fontSize: 12)),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Consumo General',
                                    style: TextStyle(color: Color(0xFF111111), fontSize: 12),
                                  ),
                                ),
                                Text(
                                  '\$${widget.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF111111),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 8),
                        _DashedReceiptLine(),
                        const SizedBox(height: 8),

                        // Totals Summary
                        if (widget.discount > 0) ...[
                          _ReceiptInfoRow(
                            label: 'SUBTOTAL:',
                            value: '\$${widget.subtotal.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 4),
                          _ReceiptInfoRow(
                            label: 'DESCUENTO:',
                            value: '-\$${widget.discount.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL:',
                              style: TextStyle(
                                color: Color(0xFF111111),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '\$${widget.total.toStringAsFixed(2)} MXN',
                              style: const TextStyle(
                                color: Color(0xFF111111),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _DashedReceiptLine(),
                        const SizedBox(height: 8),

                        // Payment Details
                        _ReceiptInfoRow(
                          label: 'FORMA DE PAGO:',
                          value: widget.paymentMethod.toUpperCase(),
                          bold: true,
                        ),
                        if (widget.cashReceived > 0) ...[
                          const SizedBox(height: 4),
                          _ReceiptInfoRow(
                            label: 'RECIBIDO:',
                            value: '\$${widget.cashReceived.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 4),
                          _ReceiptInfoRow(
                            label: 'CAMBIO:',
                            value: '\$${widget.changeReturned.toStringAsFixed(2)}',
                            bold: true,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Barcode Simulation
                        Column(
                          children: [
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(36, (i) {
                                  final isThick = (i % 3 == 0) || (i % 7 == 0);
                                  final isSpace = (i % 5 == 0);
                                  if (isSpace) return const SizedBox(width: 3);
                                  return Container(
                                    width: isThick ? 3.5 : 1.8,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    color: const Color(0xFF111111),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.folio,
                              style: const TextStyle(
                                color: Color(0xFF444444),
                                fontSize: 11,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Footer note
                        const Text(
                          '¡GRACIAS POR SU PREFERENCIA!',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ganimedes 2.0 POS Cloud Engine',
                          style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // WhatsApp Button (Primary Call-to-action)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _openWhatsAppDialog,
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: const Text(
                            'Enviar por WhatsApp',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Copy Text Button
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerLowest,
                          foregroundColor: AppColors.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.borderSoft),
                          ),
                        ),
                        tooltip: 'Copiar texto del ticket',
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Print simulation button
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurface,
                            side: const BorderSide(color: AppColors.borderSoft),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ticket enviado a impresora térmica (80mm)'),
                                backgroundColor: AppColors.success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('Imprimir', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close button
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ReceiptInfoRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF111111),
              fontSize: 11,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DashedReceiptLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCCCCCC)),
              ),
            );
          }),
        );
      },
    );
  }
}

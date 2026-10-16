import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../../services/pocketbase_service.dart';
import '../../theme/app_colors.dart';
import 'digital_ticket_viewer_dialog.dart';
import 'send_ticket_whatsapp_dialog.dart';

class TicketConfirmationDialog extends StatelessWidget {
  final double total;
  final String folio;
  final List<CartItem> cartItems;
  final String paymentMethod;
  final double cashReceived;
  final double changeReturned;
  final String barberName;
  final String clientName;
  final VoidCallback onNewSale;

  const TicketConfirmationDialog({
    super.key,
    required this.total,
    required this.folio,
    this.cartItems = const [],
    this.paymentMethod = 'Efectivo',
    this.cashReceived = 0.0,
    this.changeReturned = 0.0,
    this.barberName = 'Operador',
    this.clientName = 'Cliente General',
    required this.onNewSale,
  });

  static Future<void> show(
    BuildContext context, {
    required double total,
    required String folio,
    List<CartItem> cartItems = const [],
    String paymentMethod = 'Efectivo',
    double cashReceived = 0.0,
    double changeReturned = 0.0,
    String barberName = 'Operador',
    String clientName = 'Cliente General',
    required VoidCallback onNewSale,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TicketConfirmationDialog(
        total: total,
        folio: folio,
        cartItems: cartItems,
        paymentMethod: paymentMethod,
        cashReceived: cashReceived,
        changeReturned: changeReturned,
        barberName: barberName,
        clientName: clientName,
        onNewSale: onNewSale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchName = PocketBaseService().branchCode.toUpperCase();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.secondary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Venta Guardada con Éxito',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Folio: $folio • Registrado en PocketBase',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        _StatusPill(
                          icon: Icons.cloud_done_rounded,
                          label: 'PocketBase OK',
                          color: AppColors.success,
                        ),
                        _StatusPill(
                          icon: Icons.inventory_2_rounded,
                          label: 'Stock Descontado',
                          color: AppColors.secondary,
                        ),
                        _StatusPill(
                          icon: Icons.print_rounded,
                          label: 'Listo para Imprimir',
                          color: AppColors.tertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Digital Ticket Receipt
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Column(
                  children: [
                    // Top gradient strip
                    Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryContainer,
                            AppColors.secondary,
                            AppColors.primaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Merchant Header
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.content_cut_rounded,
                                color: AppColors.secondary,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'GANIMEDES BARBER & POS',
                                style: TextStyle(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sucursal $branchName • Terminal 01',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                            ),
                          ),
                          const Divider(
                            color: AppColors.borderSoft,
                            height: 20,
                          ),

                          // Metadata
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ATENDIÓ',
                                    style: TextStyle(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    barberName,
                                    style: const TextStyle(
                                      color: AppColors.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'CLIENTE',
                                    style: TextStyle(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    clientName,
                                    style: const TextStyle(
                                      color: AppColors.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(
                            color: AppColors.borderSoft,
                            height: 20,
                          ),

                          // Items Breakdown
                          if (cartItems.isNotEmpty)
                            ...cartItems.map((ci) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _ReceiptItemRow(
                                    name: ci.item.name,
                                    qty: '${ci.quantity}x',
                                    price: '\$${ci.total.toStringAsFixed(2)}',
                                  ),
                                ))
                          else
                            const _ReceiptItemRow(
                              name: 'Venta General',
                              qty: '1x',
                              price: '\$0.00',
                            ),

                          const Divider(
                            color: AppColors.borderSoft,
                            height: 20,
                          ),

                          // Totals
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL LIQUIDADO',
                                style: TextStyle(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '\$${total.toStringAsFixed(2)} MXN',
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Método: $paymentMethod ${cashReceived > 0 ? '(Recibido \$${cashReceived.toStringAsFixed(2)})' : ''}',
                                style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              if (changeReturned > 0)
                                Text(
                                  'Cambio: \$${changeReturned.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              // Primary WhatsApp Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  SendTicketWhatsAppDialog.show(
                    context,
                    folio: folio,
                    total: total,
                    cartItems: cartItems,
                    paymentMethod: paymentMethod,
                    cashReceived: cashReceived,
                    changeReturned: changeReturned,
                    barberName: barberName,
                    clientName: clientName,
                  );
                },
                icon: const Icon(Icons.chat_rounded, size: 20),
                label: const Text(
                  'Enviar Ticket por WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: const BorderSide(color: AppColors.borderSoft),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        DigitalTicketViewerDialog.show(
                          context,
                          folio: folio,
                          total: total,
                          cartItems: cartItems,
                          paymentMethod: paymentMethod,
                          cashReceived: cashReceived,
                          changeReturned: changeReturned,
                          barberName: barberName,
                          clientName: clientName,
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('Ver / Imprimir Ticket'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onNewSale();
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Nueva Venta'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItemRow extends StatelessWidget {
  final String name;
  final String qty;
  final String price;

  const _ReceiptItemRow({
    required this.name,
    required this.qty,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              qty,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Text(
          price,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../../services/pocketbase_service.dart';
import '../../theme/app_colors.dart';
import 'ticket_confirmation_dialog.dart';

class PaymentModal extends StatefulWidget {
  final double total;
  final List<CartItem> cartItems;
  final String barberName;
  final String clientName;
  final VoidCallback onPaymentCompleted;

  const PaymentModal({
    super.key,
    required this.total,
    this.cartItems = const [],
    this.barberName = 'Operador',
    this.clientName = 'Cliente General',
    required this.onPaymentCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required double total,
    List<CartItem> cartItems = const [],
    String barberName = 'Operador',
    String clientName = 'Cliente General',
    required VoidCallback onPaymentCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: PaymentModal(
            total: total,
            cartItems: cartItems,
            barberName: barberName,
            clientName: clientName,
            onPaymentCompleted: onPaymentCompleted,
          ),
        ),
      ),
    );
  }

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  int _selectedMethod = 0; // 0: Efectivo, 1: Terminal, 2: SPEI/QR, 3: Mixto
  late double _receivedAmount;
  double _discountPercent = 0.0;
  bool _isSaving = false;
  String _currentFolio = '#TK-...';

  double get _discount => widget.total * (_discountPercent / 100.0);
  double get _effectiveTotal =>
      (widget.total - _discount).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _receivedAmount = widget.total;
    _fetchFolio();
  }

  void _setDiscount(double percent) {
    setState(() {
      _discountPercent = percent;
      _receivedAmount = _effectiveTotal;
    });
  }

  Future<void> _fetchFolio() async {
    try {
      final f = await PocketBaseService().getNextFolio();
      if (mounted) setState(() => _currentFolio = f);
    } catch (_) {}
  }

  String get _paymentMethodName {
    switch (_selectedMethod) {
      case 0:
        return 'Efectivo';
      case 1:
        return 'Terminal Tarjeta';
      case 2:
        return 'SPEI / QR';
      case 3:
        return 'Pago Dividido';
      default:
        return 'Efectivo';
    }
  }

  String get _paymentMethodCode {
    switch (_selectedMethod) {
      case 0:
        return 'cash';
      case 1:
        return 'card';
      case 2:
        return 'spei';
      case 3:
        return 'split';
      default:
        return 'cash';
    }
  }

  Future<void> _completePayment() async {
    setState(() => _isSaving = true);
    final finalTotal = _effectiveTotal;
    final change = _receivedAmount > finalTotal ? _receivedAmount - finalTotal : 0.0;

    try {
      await PocketBaseService().createSale(
        folio: _currentFolio,
        subtotal: widget.total,
        discount: _discount,
        total: finalTotal,
        paymentMethod: _paymentMethodCode,
        cashReceived: _selectedMethod == 0 ? _receivedAmount : finalTotal,
        changeReturned: change,
        cartItems: widget.cartItems,
        barberName: widget.barberName,
        clientName: widget.clientName,
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onPaymentCompleted();

      TicketConfirmationDialog.show(
        context,
        total: finalTotal,
        folio: _currentFolio,
        cartItems: widget.cartItems,
        paymentMethod: _paymentMethodName,
        cashReceived: _selectedMethod == 0 ? _receivedAmount : finalTotal,
        changeReturned: change,
        barberName: widget.barberName,
        clientName: widget.clientName,
        onNewSale: () {},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar venta: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final finalTotal = _effectiveTotal;
    final change = _receivedAmount > finalTotal ? _receivedAmount - finalTotal : 0.0;
    final totalItems = widget.cartItems.fold(0, (sum, i) => sum + i.quantity);
    final isCompactLandscape = MediaQuery.sizeOf(context).height < 520;

    return Container(
      margin: EdgeInsets.only(
        top: isCompactLandscape ? 16 : 50,
        bottom: bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderSoft),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Confirmar Cobro',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _currentFolio,
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Caja 01 • Sucursal ${PocketBaseService().branchCode.toUpperCase()}',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Total Display Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceContainer,
                    AppColors.surfaceContainerHigh,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Column(
                children: [
                  const Text(
                    'MONTO TOTAL A LIQUIDAR',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '\$${finalTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'MXN',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (_discount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Subtotal: \$${widget.total.toStringAsFixed(2)} • Desc (${_discountPercent.toStringAsFixed(0)}%): -\$${_discount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.content_cut_rounded,
                          size: 13,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalItems ítems • Atiende ${widget.barberName}',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Discount Section (RBAC: Admin & Master Barber only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DESCUENTO',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                if (!PocketBaseService().canApplyDiscount)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 12, color: AppColors.onSurfaceVariant),
                        SizedBox(width: 4),
                        Text(
                          'Solo Admin / Master Barber',
                          style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (PocketBaseService().canApplyDiscount)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickAmountChip(
                    label: '0%',
                    isSelected: _discountPercent == 0,
                    onTap: () => _setDiscount(0),
                  ),
                  _QuickAmountChip(
                    label: '5%',
                    isSelected: _discountPercent == 5,
                    onTap: () => _setDiscount(5),
                  ),
                  _QuickAmountChip(
                    label: '10%',
                    isSelected: _discountPercent == 10,
                    onTap: () => _setDiscount(10),
                  ),
                  _QuickAmountChip(
                    label: '15%',
                    isSelected: _discountPercent == 15,
                    onTap: () => _setDiscount(15),
                  ),
                  _QuickAmountChip(
                    label: '20%',
                    isSelected: _discountPercent == 20,
                    onTap: () => _setDiscount(20),
                  ),
                ],
              )
            else
              Text(
                'Los descuentos requieren privilegios de Administrador o Master Barber.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 20),

            // Payment Methods Selector
            const Text(
              'FORMA DE PAGO',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _PaymentMethodTile(
                  title: 'Efectivo',
                  subtitle: 'Gaveta física',
                  icon: Icons.payments_rounded,
                  isSelected: _selectedMethod == 0,
                  onTap: () => setState(() => _selectedMethod = 0),
                ),
                _PaymentMethodTile(
                  title: 'Terminal',
                  subtitle: 'Clip / Stripe POS',
                  icon: Icons.point_of_sale_rounded,
                  isSelected: _selectedMethod == 1,
                  onTap: () => setState(() => _selectedMethod = 1),
                ),
                _PaymentMethodTile(
                  title: 'SPEI / QR',
                  subtitle: 'CoDi directo',
                  icon: Icons.qr_code_2_rounded,
                  isSelected: _selectedMethod == 2,
                  onTap: () => setState(() => _selectedMethod = 2),
                ),
                _PaymentMethodTile(
                  title: 'Dividir',
                  subtitle: 'Efectivo + Tarjeta',
                  icon: Icons.call_split_rounded,
                  isSelected: _selectedMethod == 3,
                  onTap: () => setState(() => _selectedMethod = 3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Cash fast buttons if Cash selected
            if (_selectedMethod == 0) ...[
              const Text(
                'EFECTIVO RECIBIDO',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickAmountChip(
                    label: 'Exacto (\$${finalTotal.toStringAsFixed(0)})',
                    isSelected: _receivedAmount == finalTotal,
                    onTap: () => setState(() => _receivedAmount = finalTotal),
                  ),
                  _QuickAmountChip(
                    label: '+\$50 (\$${(finalTotal + 50).toStringAsFixed(0)})',
                    isSelected: _receivedAmount == finalTotal + 50,
                    onTap: () => setState(() => _receivedAmount = finalTotal + 50),
                  ),
                  _QuickAmountChip(
                    label: '+\$100 (\$${(finalTotal + 100).toStringAsFixed(0)})',
                    isSelected: _receivedAmount == finalTotal + 100,
                    onTap: () => setState(() => _receivedAmount = finalTotal + 100),
                  ),
                  _QuickAmountChip(
                    label: '+\$200 (\$${(finalTotal + 200).toStringAsFixed(0)})',
                    isSelected: _receivedAmount == finalTotal + 200,
                    onTap: () => setState(() => _receivedAmount = finalTotal + 200),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Change Calculation Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cambio a devolver:',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '\$${change.toStringAsFixed(2)} MXN',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Confirm Button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryContainer,
                    AppColors.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSaving ? null : _completePayment,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.point_of_sale_rounded, color: Colors.white),
                label: Text(
                  _isSaving
                      ? 'Registrando en PocketBase...'
                      : 'Completar Cobro • \$${finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerHighest
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary.withValues(alpha: 0.6)
                : AppColors.borderSoft,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary.withValues(alpha: 0.15)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.secondary : AppColors.onSurfaceVariant,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.secondary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickAmountChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.borderSoft,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.onSecondaryContainer
                : AppColors.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/pocketbase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/pos/digital_ticket_viewer_dialog.dart';
import '../widgets/pos/send_ticket_whatsapp_dialog.dart';

class CashRegisterScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPos;

  const CashRegisterScreen({
    super.key,
    this.onNavigateToPos,
  });

  @override
  State<CashRegisterScreen> createState() => CashRegisterScreenState();
}

class CashRegisterScreenState extends State<CashRegisterScreen> {
  bool _isLoading = true;

  void reloadSummary() {
    _loadSummary();
  }
  double _totalSales = 0.0;
  int _ticketCount = 0;
  double _cashTotal = 0.0;
  int _cashCount = 0;
  double _cardTotal = 0.0;
  int _cardCount = 0;
  double _transferTotal = 0.0;
  int _transferCount = 0;
  double _initialFund = 0.0;
  double _cashInDrawer = 0.0;
  List<Map<String, dynamic>> _salesList = [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final summary = await PocketBaseService().getCashRegisterSummary();
      final sales = await PocketBaseService().getSales(limit: 50);
      if (mounted) {
        setState(() {
          _totalSales = (summary['totalSales'] as num?)?.toDouble() ?? 0.0;
          _ticketCount = (summary['ticketCount'] as num?)?.toInt() ?? 0;
          _cashTotal = (summary['cashTotal'] as num?)?.toDouble() ?? 0.0;
          _cashCount = (summary['cashCount'] as num?)?.toInt() ?? 0;
          _cardTotal = (summary['cardTotal'] as num?)?.toDouble() ?? 0.0;
          _cardCount = (summary['cardCount'] as num?)?.toInt() ?? 0;
          _transferTotal = (summary['transferTotal'] as num?)?.toDouble() ?? 0.0;
          _transferCount = (summary['transferCount'] as num?)?.toInt() ?? 0;
          _initialFund = (summary['initialFund'] as num?)?.toDouble() ?? 0.0;
          _cashInDrawer = (summary['cashInDrawer'] as num?)?.toDouble() ?? 0.0;
          _salesList = sales;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSetInitialFundDialog() {
    final controller = TextEditingController(
      text: _initialFund > 0 ? _initialFund.toStringAsFixed(2) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fondo Inicial de Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa el monto de efectivo con el que abre la gaveta para dar cambio:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_money_rounded),
                labelText: 'Monto Inicial (\$) *',
                hintText: 'Ej. 500.00',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.trim()) ?? 0.0;
              PocketBaseService().setInitialFund(val);
              Navigator.pop(ctx);
              _loadSummary();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fondo inicial fijado en \$${val.toStringAsFixed(2)}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog() {
    final cashController = TextEditingController(text: _cashInDrawer > 0 ? _cashInDrawer.toStringAsFixed(2) : '');
    final notesController = TextEditingController();
    double countedCash = _cashInDrawer;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final diff = countedCash - _cashInDrawer;
          Color diffColor = AppColors.success;
          String diffText = 'Arqueo Exacto (\$0.00)';
          if (diff > 0.01) {
            diffColor = AppColors.secondary;
            diffText = 'Sobrante en Gaveta: +\$${diff.toStringAsFixed(2)}';
          } else if (diff < -0.01) {
            diffColor = Colors.orangeAccent;
            diffText = 'Faltante en Gaveta: -\$${diff.abs().toStringAsFixed(2)}';
          }

          return AlertDialog(
            backgroundColor: AppColors.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.inventory_rounded, color: AppColors.secondary, size: 22),
                SizedBox(width: 8),
                Text('Corte Z / Arqueo de Caja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen Financiero del Turno:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _dialogRow('Ventas Totales:', '\$${_totalSales.toStringAsFixed(2)}'),
                  _dialogRow('Tickets Emitidos:', '$_ticketCount'),
                  _dialogRow('Fondo Inicial de Caja:', '\$${_initialFund.toStringAsFixed(2)}'),
                  _dialogRow('Cobros en Efectivo:', '\$${_cashTotal.toStringAsFixed(2)}'),
                  _dialogRow('Efectivo Esperado en Gaveta:', '\$${_cashInDrawer.toStringAsFixed(2)}'),
                  _dialogRow('Cobros con Tarjeta:', '\$${_cardTotal.toStringAsFixed(2)}'),
                  _dialogRow('Transferencias SPEI:', '\$${_transferTotal.toStringAsFixed(2)}'),
                  const Divider(height: 20),
                  const Text(
                    'Efectivo Físico Contado en Caja:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: cashController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.payments_rounded, size: 18),
                      labelText: 'Total contado en gaveta (\$)',
                      hintText: _cashInDrawer.toStringAsFixed(2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val.trim()) ?? 0.0;
                      setDialogState(() {
                        countedCash = parsed;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: diffColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      diffText,
                      style: TextStyle(
                        color: diffColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Notas u observaciones (opcional)',
                      hintText: 'Ej. Turno cerrado sin incidencias...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() => isSaving = true);
                        try {
                          await PocketBaseService().closeCashShift(
                            initialCash: _initialFund,
                            expectedCash: _cashInDrawer,
                            actualCash: countedCash,
                            totalSales: _totalSales,
                            cashSales: _cashTotal,
                            cardSales: _cardTotal,
                            speiSales: _transferTotal,
                            ticketsCount: _ticketCount,
                            notes: notesController.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadSummary();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('¡Corte de caja registrado en servidor! Arqueo reiniciado a ceros.'),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error al guardar corte: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                icon: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(isSaving ? 'Guardando...' : 'Finalizar Turno'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmCancelSale(String saleId, String folio) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('¿Cancelar Venta $folio?'),
        content: const Text(
          'Esta acción anulará el ticket, descontará el monto del corte de caja y restaurará el stock de los productos físicos.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await PocketBaseService().cancelSale(saleId, folio: folio);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Venta $folio cancelada exitosamente'),
                      backgroundColor: AppColors.surfaceContainerHighest,
                    ),
                  );
                  _loadSummary();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al cancelar la venta'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pb = PocketBaseService();
    final operatorName = pb.userName.isNotEmpty ? pb.userName : 'Operador';
    final startTime = pb.shiftStartTime;
    final timeStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // Main Shift Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Turno & Operador
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: AppColors.secondary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Caja Abierta',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Turno Activo',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            operatorName,
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Corte y Arqueo Operativo',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),

                // Apertura & Fondo Inicial
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'APERTURA',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: AppColors.tertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Hoy $timeStr',
                                  style: const TextStyle(
                                    color: AppColors.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _showSetInitialFundDialog,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'FONDO INICIAL',
                                    style: TextStyle(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 11,
                                    color: AppColors.secondary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.savings_rounded,
                                    size: 14,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '\$${_initialFund.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Resumen Métricas y Ventas (2 Cards)
          Row(
            children: [
              // Ventas Turno
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'VENTAS TURNO',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${_totalSales.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _ticketCount > 0
                                ? Icons.check_circle_outline_rounded
                                : Icons.hourglass_empty_rounded,
                            size: 12,
                            color: _ticketCount > 0 ? AppColors.secondary : AppColors.outline,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$_ticketCount tickets emitidos',
                              style: TextStyle(
                                color: _ticketCount > 0
                                    ? AppColors.secondary
                                    : AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Efectivo en Gaveta
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'GAVETA CASH',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.point_of_sale_rounded,
                              size: 14,
                              color: AppColors.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${_cashInDrawer.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Fondo + Ventas Cash',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zero-State Banner when no tickets yet
          if (!_isLoading && _ticketCount == 0) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Caja lista en ceros',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Aún no hay ventas en este turno. Las ventas registradas en el POS se calcularán automáticamente aquí.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (widget.onNavigateToPos != null) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: widget.onNavigateToPos,
                            child: const Text(
                              '⚡ Ir a Terminal POS para cobrar →',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Desglose por Método de Pago
          const Text(
            'DESGLOSE POR FORMA DE PAGO',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              children: [
                _PaymentBreakdownRow(
                  icon: Icons.payments_rounded,
                  title: 'Efectivo Registrado',
                  tickets: '$_cashCount cobros',
                  amount: '\$${_cashTotal.toStringAsFixed(2)}',
                  color: AppColors.secondary,
                ),
                const Divider(color: AppColors.borderSoft, height: 20),
                _PaymentBreakdownRow(
                  icon: Icons.credit_card_rounded,
                  title: 'Terminal Bancaria (Clip / Stripe)',
                  tickets: '$_cardCount cobros',
                  amount: '\$${_cardTotal.toStringAsFixed(2)}',
                  color: AppColors.primary,
                ),
                const Divider(color: AppColors.borderSoft, height: 20),
                _PaymentBreakdownRow(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Transferencia SPEI / QR',
                  tickets: '$_transferCount cobros',
                  amount: '\$${_transferTotal.toStringAsFixed(2)}',
                  color: AppColors.tertiary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderSoft),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _showSetInitialFundDialog,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Fondo Inicial'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _showCloseShiftDialog,
                  icon: const Icon(Icons.lock_clock_rounded, size: 18),
                  label: const Text('Cerrar Turno'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tickets / Compras Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pb.canViewAllSales
                    ? 'TICKETS Y VENTAS DEL TURNO (${_salesList.length})'
                    : 'MIS TICKETS DEL TURNO (${_salesList.length})',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: AppColors.secondary,
                onPressed: _loadSummary,
                tooltip: 'Actualizar tickets',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_salesList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long_rounded, color: AppColors.onSurfaceVariant, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'No hay tickets emitidos en este turno',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._salesList.map((sale) {
              final saleId = (sale['id'] ?? '').toString();
              final isCancelled = (sale['status'] ?? '').toString().toLowerCase() == 'cancelled';
              final folio = (sale['folio'] ?? '#TK-0000').toString();
              final total = (sale['total'] as num?)?.toDouble() ?? 0.0;
              final subtotal = (sale['subtotal'] as num?)?.toDouble() ?? total;
              final discount = (sale['discount'] as num?)?.toDouble() ?? 0.0;
              final method = (sale['payment_method'] ?? 'Efectivo').toString();
              final client = (sale['client_name'] ?? 'Cliente General').toString();
              final barber = (sale['barber_name'] ?? 'Operador').toString();
              final cashReceived = (sale['cash_received'] as num?)?.toDouble() ?? 0.0;
              final changeReturned = (sale['change_returned'] as num?)?.toDouble() ?? 0.0;

              Color methodColor = AppColors.secondary;
              String methodLabel = 'Efectivo';
              IconData methodIcon = Icons.payments_rounded;

              if (method.toLowerCase().contains('card') || method.toLowerCase().contains('tarjeta')) {
                methodColor = AppColors.primary;
                methodLabel = 'Tarjeta';
                methodIcon = Icons.credit_card_rounded;
              } else if (method.toLowerCase().contains('spei') || method.toLowerCase().contains('transfer')) {
                methodColor = AppColors.tertiary;
                methodLabel = 'SPEI';
                methodIcon = Icons.qr_code_2_rounded;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCancelled ? AppColors.error.withValues(alpha: 0.3) : AppColors.borderSoft,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderSoft),
                              ),
                              child: Text(
                                folio,
                                style: TextStyle(
                                  color: isCancelled ? AppColors.onSurfaceVariant : AppColors.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (isCancelled) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ANULADA',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: methodColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(methodIcon, size: 12, color: methodColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    methodLabel,
                                    style: TextStyle(
                                      color: methodColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isCancelled
                              ? '-\$0.00'
                              : '\$${total.toStringAsFixed(2)} MXN',
                          style: TextStyle(
                            color: isCancelled ? AppColors.error : AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Cliente: $client • Atendió: $barber',
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurface,
                              side: const BorderSide(color: AppColors.borderSoft),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              DigitalTicketViewerDialog.show(
                                context,
                                folio: folio,
                                total: total,
                                subtotal: subtotal,
                                discount: discount,
                                paymentMethod: methodLabel,
                                cashReceived: cashReceived,
                                changeReturned: changeReturned,
                                barberName: barber,
                                clientName: client,
                              );
                            },
                            icon: const Icon(Icons.receipt_long_rounded, size: 15),
                            label: const Text('Ver Ticket', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              SendTicketWhatsAppDialog.show(
                                context,
                                folio: folio,
                                total: total,
                                paymentMethod: methodLabel,
                                cashReceived: cashReceived,
                                changeReturned: changeReturned,
                                barberName: barber,
                                clientName: client,
                              );
                            },
                            icon: const Icon(Icons.chat_rounded, size: 15),
                            label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (PocketBaseService().canCancelSale && !isCancelled) ...[
                          const SizedBox(width: 8),
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              tooltip: 'Cancelar Ticket',
                              onPressed: () => _confirmCancelSale(saleId, folio),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}


class _PaymentBreakdownRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String tickets;
  final String amount;
  final Color color;

  const _PaymentBreakdownRow({
    required this.icon,
    required this.title,
    required this.tickets,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                tickets,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

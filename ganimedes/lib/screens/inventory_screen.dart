import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../services/pocketbase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/modals/create_product_modal.dart';
import '../widgets/scanner/barcode_scanner_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => InventoryScreenState();
}

class InventoryScreenState extends State<InventoryScreen> {
  String _selectedFilter = 'Todos';
  String _searchQuery = '';
  bool _isLoading = false;
  List<PosItem> _items = [];
  List<String> _categories = ['Todos'];

  void reloadData() {
    _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pb = PocketBaseService();
      final productsFuture = pb.getProductsServices();
      final categoriesFuture = pb.getCategories();

      final results = await Future.wait([productsFuture, categoriesFuture]);
      if (mounted) {
        setState(() {
          _items = results[0] as List<PosItem>;
          _categories = results[1] as List<String>;
        });
      }
    } catch (_) {
      // Quiet fallback: keep empty list without showing intrusive error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scanBarcodeForSearch() async {
    final scannedCode = await BarcodeScannerDialog.show(
      context,
      title: 'Buscar Producto por Código',
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() => _searchQuery = scannedCode);
    }
  }

  void _showCreateProductDialog({bool startAsPhysical = false, bool openScanner = false}) {
    CreateProductModal.show(
      context,
      initialIsService: !startAsPhysical,
      openScannerImmediately: openScanner,
      categories: _categories.where((c) => c != 'Todos').toList(),
      onCreated: (newItem) async {
        await _loadData();
        if (mounted) {
          setState(() {
            _selectedFilter = 'Todos';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newItem.isService
                    ? '✂️ Servicio "${newItem.name}" creado con ID: ${newItem.sku}'
                    : '📦 Producto "${newItem.name}" agregado al inventario',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteItem(PosItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Deseas eliminar "${item.name}" del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await PocketBaseService().deleteProductService(item.id);
      if (ok && mounted) {
        setState(() => _items.removeWhere((i) => i.id == item.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_selectedFilter == 'Bajo Stock') {
        return matchesSearch && !item.isService && item.stock <= item.minStockAlert;
      } else if (_selectedFilter != 'Todos') {
        return matchesSearch && item.category == _selectedFilter;
      }
      return matchesSearch;
    }).toList();

    // KPI Calculations
    final totalSkus = _items.length;
    final lowStockCount = _items.where((i) => !i.isService && i.stock <= i.minStockAlert).length;
    final totalInventoryValue = _items.fold<double>(
      0.0,
      (sum, i) => sum + (i.isService ? 0.0 : (i.price * i.stock)),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProductDialog,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nuevo Producto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // Subheader & PocketBase Sync Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventario & Catálogo',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Catálogo en tiempo real sincronizado',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_done_rounded, size: 12, color: AppColors.secondary),
                      SizedBox(width: 4),
                      Text(
                        'PocketBase Realtime',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3 KPI Metric Cards
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    title: 'TOTAL ITEMS',
                    value: '$totalSkus',
                    subtitle: 'Activos',
                    icon: Icons.inventory_2_rounded,
                    accentColor: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiCard(
                    title: 'BAJO STOCK',
                    value: '$lowStockCount',
                    subtitle: 'Requiere surtir',
                    icon: Icons.warning_rounded,
                    accentColor: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiCard(
                    title: 'VALOR STOCK',
                    value: '\$${totalInventoryValue.toStringAsFixed(0)}',
                    subtitle: 'MXN Valuado',
                    icon: Icons.payments_rounded,
                    accentColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar with Barcode Scanner Button
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search_rounded, color: AppColors.outline, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: _searchQuery)
                        ..selection = TextSelection.collapsed(offset: _searchQuery.length),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o código...',
                        border: InputBorder.none,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Escanear con Cámara',
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                    onPressed: _scanBarcodeForSearch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterTab(
                    label: 'Todos',
                    isSelected: _selectedFilter == 'Todos',
                    onTap: () => setState(() => _selectedFilter = 'Todos'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Bajo Stock ($lowStockCount)',
                    isSelected: _selectedFilter == 'Bajo Stock',
                    onTap: () => setState(() => _selectedFilter = 'Bajo Stock'),
                    highlightWarning: true,
                  ),
                  ..._categories.where((c) => c != 'Todos').map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterTab(
                            label: cat,
                            isSelected: _selectedFilter == cat,
                            onTap: () => setState(() => _selectedFilter = cat),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loading state
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            // Empty state
            else if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: AppColors.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay productos registrados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Empieza agregando tu primer producto o servicio con el botón de abajo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showCreateProductDialog(startAsPhysical: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.onSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Text('✂️', style: TextStyle(fontSize: 16)),
                          label: const Text(
                            'Servicio Solo Texto',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateProductDialog(startAsPhysical: true, openScanner: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerHigh,
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(color: AppColors.secondary, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                          label: const Text(
                            'Producto Físico (Cámara)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            // Products List
            else
              ...filtered.map(
                (item) {
                  final isLowStock = !item.isService && item.stock <= item.minStockAlert;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLowStock
                            ? AppColors.warning.withValues(alpha: 0.3)
                            : AppColors.borderSoft,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            color: isLowStock ? AppColors.warning : AppColors.secondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (item.sku.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.sku,
                                        style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      item.category,
                                      style: const TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.isService)
                                    const Text(
                                      ' • Servicio',
                                      style: TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLowStock
                                    ? AppColors.warning.withValues(alpha: 0.15)
                                    : AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.durationOrStock,
                                style: TextStyle(
                                  color: isLowStock ? AppColors.warning : AppColors.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.outline),
                          onSelected: (val) {
                            if (val == 'delete') _deleteItem(item);
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                  SizedBox(width: 8),
                                  Text('Eliminar', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CREATE PRODUCT MODAL


// ---------------------------------------------------------------------------
// KPI CARD & FILTER TAB WIDGETS
// ---------------------------------------------------------------------------
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 14, color: accentColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool highlightWarning;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.highlightWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (highlightWarning ? AppColors.warning : AppColors.secondary)
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.surfaceContainerLowest : AppColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mock_data.dart';
import '../services/pocketbase_service.dart';
import '../theme/app_colors.dart';
import '../utils/barcode_keyboard_listener.dart';
import '../utils/device_breakpoints.dart';
import '../widgets/auth/pin_access_dialog.dart';
import '../widgets/modals/create_product_modal.dart';
import '../widgets/pos/payment_modal.dart';
import '../widgets/scanner/barcode_scanner_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => PosScreenState();
}

class PosScreenState extends State<PosScreen> {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  Barber _currentBarber = MockData.barbers[0];
  final List<CartItem> _cart = [];
  List<PosItem> _products = [];
  List<String> _categories = ['Todos'];
  bool _isLoading = false;

  void reloadCatalog() {
    _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _initCurrentBarber();
  }

  void _initCurrentBarber() {
    final user = PocketBaseService().currentUser;
    if (user != null) {
      setState(() {
        _currentBarber = Barber(
          id: user['id'] ?? 'u1',
          name: user['name'] ?? 'Administrador',
          chair: user['chair'] != null && (user['chair'] as String).isNotEmpty
              ? user['chair']
              : 'Caja Principal',
          shift: user['shift'] != null && (user['shift'] as String).isNotEmpty
              ? user['shift']
              : 'Turno Activo',
          role: user['role'] ?? 'admin',
          isAdmin: user['role'] == 'admin',
        );
      });
    }
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
          _products = results[0] as List<PosItem>;
          _categories = results[1] as List<String>;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _cartTotal =>
      _cart.fold(0.0, (sum, cartItem) => sum + cartItem.total);

  int get _cartItemCount =>
      _cart.fold(0, (sum, cartItem) => sum + cartItem.quantity);

  void _addToCart(PosItem item) {
    setState(() {
      final existingIndex =
          _cart.indexWhere((element) => element.item.id == item.id || (element.item.sku.isNotEmpty && element.item.sku == item.sku));
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity += 1;
      } else {
        _cart.add(CartItem(item: item, quantity: 1));
      }
    });
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agregado: ${item.name}'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: AppColors.surfaceContainerHigh,
      ),
    );
  }

  void _onBarcodeScanned(String code) {
    final clean = code.trim();
    if (clean.isEmpty) return;

    // Check if barcode matches any loaded product
    final match = _products.where((p) => p.sku.toLowerCase() == clean.toLowerCase()).firstOrNull;

    if (match != null) {
      _addToCart(match);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código $clean detectado: ${match.name} agregado'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      setState(() => _searchQuery = clean);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código "$clean" no encontrado en catálogo. Filtrando...'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _openCameraScanner() async {
    final code = await BarcodeScannerDialog.show(
      context,
      title: 'Escanear Producto para POS',
    );
    if (code != null && code.isNotEmpty) {
      _onBarcodeScanned(code);
    }
  }

  void _openCreateProductModal({bool startAsPhysical = false, bool openScanner = false}) {
    CreateProductModal.show(
      context,
      initialIsService: !startAsPhysical,
      openScannerImmediately: openScanner,
      categories: _categories.where((c) => c != 'Todos').toList(),
      onCreated: (newItem) async {
        await _loadData();
        if (mounted) {
          setState(() {
            _selectedCategory = 'Todos';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newItem.isService
                    ? '✂️ "${newItem.name}" listo en POS con ID: ${newItem.sku}'
                    : '📦 "${newItem.name}" agregado al POS',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket vaciado'),
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _products.where((item) {
      final matchesCategory = _selectedCategory == 'Todos' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return BarcodeKeyboardListener(
      onBarcodeScanned: _onBarcodeScanned,
      child: Stack(
        children: [
          // Main Scrollable Area
          RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Barber Context Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: Row(
                          children: [
                            // Barber Avatar with Live Dot
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.surfaceContainerHigh,
                                  child: Text(
                                    _currentBarber.name.substring(0, 1),
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.surfaceContainer,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.secondary.withValues(alpha: 0.8),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Barber Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _currentBarber.name,
                                          style: const TextStyle(
                                            color: AppColors.onSurface,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _currentBarber.chair,
                                          style: const TextStyle(
                                            color: AppColors.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_currentBarber.shift} • Terminal Activa',
                                    style: const TextStyle(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons
                            if (PocketBaseService().canAccessInventory)
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: AppColors.secondary,
                                  size: 22,
                                ),
                                onPressed: _openCreateProductModal,
                                tooltip: 'Agregar Servicio / Producto',
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: AppColors.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: _loadData,
                              tooltip: 'Recargar Catálogo',
                            ),
                            if (PocketBaseService().canChangeOperator)
                              IconButton(
                                icon: const Icon(
                                  Icons.sync_alt_rounded,
                                  color: AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () {
                                  PinAccessDialog.show(
                                    context,
                                    onOperatorSelected: (b) {
                                      setState(() => _currentBarber = b);
                                    },
                                  );
                                },
                                tooltip: 'Cambiar Operador',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Search & Barcode Bar
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
                              child: Icon(
                                Icons.search_rounded,
                                color: AppColors.outline,
                                size: 20,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(text: _searchQuery)
                                  ..selection = TextSelection.collapsed(offset: _searchQuery.length),
                                onChanged: (val) => setState(() => _searchQuery = val),
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Buscar o escanear código...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
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
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: IconButton(
                                tooltip: 'Escanear con Cámara',
                                icon: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: AppColors.secondary,
                                  size: 22,
                                ),
                                onPressed: _openCameraScanner,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Horizontal Category Filters
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = category == _selectedCategory;

                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = category),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.secondary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.onSecondaryContainer
                                          : AppColors.onSurfaceVariant,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Loading or Empty State
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (filteredItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.point_of_sale_rounded,
                            size: 48,
                            color: AppColors.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Catálogo sin productos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Puedes agregar tus primeros productos o servicios ahora mismo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openCreateProductModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.onSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Agregar Producto o Servicio',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // Products & Services 2-Column Grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 170),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: DeviceBreakpoints.getPosColumnCount(context),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: DeviceBreakpoints.getPosAspectRatio(context),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filteredItems[index];
                        return _ProductCard(
                          item: item,
                          onAdd: () => _addToCart(item),
                        );
                      },
                      childCount: filteredItems.length,
                    ),
                  ),
                ),
            ],
            ),
          ),

          // Interactive Floating Cart / Ticket Dock
          if (_cart.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 84, // positioned above the main navigation dock
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSoft),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Client info & Total row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: AppColors.secondary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Flexible(
                                          child: Text(
                                            'Ticket Actual',
                                            style: TextStyle(
                                              color: AppColors.onSurface,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '• $_cartItemCount items',
                                          style: const TextStyle(
                                            color: AppColors.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _cart.map((e) => '${e.quantity}x ${e.item.name}').join(', '),
                                      style: const TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '\$${_cartTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Actions Group
                    Row(
                      children: [
                        // Clear Ticket
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.delete_sweep_rounded,
                              color: AppColors.onSurfaceVariant,
                              size: 18,
                            ),
                            onPressed: _clearCart,
                            tooltip: 'Vaciar Ticket',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Main Checkout Button
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryContainer,
                                  AppColors.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                PaymentModal.show(
                                  context,
                                  total: _cartTotal,
                                  cartItems: _cart,
                                  barberName: _currentBarber.name,
                                  clientName: 'Cliente General',
                                  onPaymentCompleted: () {
                                    setState(() {
                                      _cart.clear();
                                    });
                                    // Refresh products to show updated stock
                                    _loadData();
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.point_of_sale_rounded,
                                size: 18,
                                color: AppColors.surfaceContainerLowest,
                              ),
                              label: Text(
                                'Cobrar \$${_cartTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.surfaceContainerLowest,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
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
    );
  }
}

class _ProductCard extends StatelessWidget {
  final PosItem item;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.item,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail / Hero Illustration with badge
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      item.icon,
                      size: 40,
                      color: item.isPopular
                          ? AppColors.secondary
                          : AppColors.outlineVariant,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.isPopular
                            ? AppColors.secondary
                            : AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.isPopular) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: AppColors.surfaceContainerLowest,
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'Top Pack',
                              style: TextStyle(
                                color: AppColors.surfaceContainerLowest,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              item.isService
                                  ? Icons.schedule_rounded
                                  : Icons.inventory_2_rounded,
                              size: 10,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.durationOrStock,
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Titles
          Text(
            item.name,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item.subtitle.isNotEmpty ? item.subtitle : item.category,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Price & Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${item.price.toStringAsFixed(0)}.00',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/mock_data.dart';
import '../../services/pocketbase_service.dart';
import '../../theme/app_colors.dart';
import '../scanner/barcode_scanner_dialog.dart';

class CreateProductModal extends StatefulWidget {
  final List<String> categories;
  final ValueChanged<PosItem> onCreated;
  final bool initialIsService;
  final bool openScannerImmediately;

  const CreateProductModal({
    super.key,
    required this.categories,
    required this.onCreated,
    this.initialIsService = true,
    this.openScannerImmediately = false,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<PosItem> onCreated,
    List<String>? categories,
    bool initialIsService = true,
    bool openScannerImmediately = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateProductModal(
        categories: categories ?? const [],
        onCreated: onCreated,
        initialIsService: initialIsService,
        openScannerImmediately: openScannerImmediately,
      ),
    );
  }

  @override
  State<CreateProductModal> createState() => _CreateProductModalState();
}

class _CreateProductModalState extends State<CreateProductModal> {
  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController(text: '10');
  final _minStockController = TextEditingController(text: '3');
  final _durationController = TextEditingController(text: '30');

  late bool _isService;
  String _selectedCategory = '';
  bool _isSaving = false;
  bool _manualSkuEdited = false;
  bool _showManualSkuInput = false;

  final List<String> _serviceCategories = [
    'Cortes & Barba',
    'Corte de Cabello',
    'Arreglo de Barba',
    'Tratamientos',
    'Afeitado Clásico',
    'Colorimetría',
    'General',
  ];

  final List<String> _productCategories = [
    'Pomadas & Styling',
    'Cuidado de Barba',
    'Shampoos & Cuidado',
    'Bebidas / Bar',
    'Accesorios & Herramientas',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _isService = widget.initialIsService;
    _initCategory();
    _nameController.addListener(_onNameChanged);

    if (widget.openScannerImmediately && !_isService) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scanBarcode();
      });
    }
  }

  void _initCategory() {
    final list = _isService ? _serviceCategories : _productCategories;
    if (widget.categories.isNotEmpty) {
      final matching = widget.categories.firstWhere(
        (c) => c != 'Todos',
        orElse: () => list.first,
      );
      _selectedCategory = matching;
    } else {
      _selectedCategory = list.first;
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _subtitleController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  /// Automatically generates clean uppercase ID/SKU from text like "Corte de cabello" -> "CORTE-CABELLO"
  String _generateCleanId(String text) {
    if (text.trim().isEmpty) return '';

    String cleaned = text.trim();

    // Map accented characters
    const withAccents = 'áéíóúÁÉÍÓÚñÑüÜ';
    const withoutAccents = 'aeiouAEIOUnNuU';
    for (int i = 0; i < withAccents.length; i++) {
      cleaned = cleaned.replaceAll(withAccents[i], withoutAccents[i]);
    }

    // Replace non-alphanumeric with hyphens
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-');

    // Remove repeated hyphens and trim
    cleaned = cleaned.replaceAll(RegExp(r'-+'), '-');
    if (cleaned.startsWith('-')) cleaned = cleaned.substring(1);
    if (cleaned.endsWith('-')) cleaned = cleaned.substring(0, cleaned.length - 1);

    return cleaned.toUpperCase();
  }

  void _onNameChanged() {
    if (_isService && !_manualSkuEdited) {
      final generated = _generateCleanId(_nameController.text);
      _skuController.text = generated;
    }
  }

  Future<void> _scanBarcode() async {
    final code = await BarcodeScannerDialog.show(
      context,
      title: 'Escanear Código de Barras con Cámara',
    );
    if (code != null && code.isNotEmpty) {
      setState(() {
        _skuController.text = code;
        _manualSkuEdited = true;
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _generateRandomSku() {
    final prefix = _isService ? 'SRV' : 'PRD';
    final random = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    setState(() {
      _skuController.text = '$prefix-$random';
      _manualSkuEdited = true;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final cost = double.tryParse(_costController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final minStock = int.tryParse(_minStockController.text.trim()) ?? 0;
    final duration = int.tryParse(_durationController.text.trim()) ?? 30;
    String sku = _skuController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el nombre del ítem o servicio'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un precio de venta válido'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (sku.isEmpty) {
      if (_isService) {
        sku = _generateCleanId(name);
        if (sku.isEmpty) {
          sku = 'SRV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        }
      } else {
        sku = 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      }
    }

    setState(() => _isSaving = true);

    try {
      final newItem = PosItem(
        id: '',
        sku: sku,
        name: name,
        subtitle: _subtitleController.text.trim(),
        category: _selectedCategory.isNotEmpty ? _selectedCategory : 'General',
        price: price,
        cost: cost,
        stock: _isService ? 0 : stock,
        minStockAlert: _isService ? 0 : minStock,
        durationMinutes: _isService ? duration : 0,
        durationOrStock: _isService ? '${duration}m' : '$stock en stock',
        icon: _isService ? Icons.content_cut_rounded : Icons.inventory_2_rounded,
        isService: _isService,
      );

      final saved = await PocketBaseService().createProductService(newItem);
      if (mounted) {
        widget.onCreated(saved);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCategories = _isService ? _serviceCategories : _productCategories;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainer : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag indicator handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isService ? Icons.content_cut_rounded : Icons.qr_code_scanner_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isService ? '✂️ Servicio (Solo Texto)' : '📦 Producto (Con Código)',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isService
                            ? 'Cortes de cabello, barba y servicios con ID automático'
                            : 'Escanea el código de barras o ingresa el SKU',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.onSurfaceVariant : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Segmented Mode Switcher: ✂️ Solo Texto vs 📦 Producto con Lector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerHigh : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isService = true;
                          _manualSkuEdited = false;
                          _initCategory();
                          if (_nameController.text.isNotEmpty) {
                            _skuController.text = _generateCleanId(_nameController.text);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _isService ? AppColors.secondary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _isService
                              ? [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('✂️', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              'Servicio / Texto',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _isService ? AppColors.onSecondary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isService = false;
                          _initCategory();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: !_isService ? AppColors.secondary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_isService
                              ? [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📦', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              'Producto Físico',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: !_isService ? AppColors.onSecondary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // In Physical Product mode: Highlighted HERO Camera Scanner Option Card
            if (!_isService) ...[
              InkWell(
                onTap: _scanBarcode,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.secondary,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.onSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESCANEAR CÓDIGO CON CÁMARA',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _skuController.text.isNotEmpty
                                  ? 'Código detectado: ${_skuController.text}'
                                  : 'Toca aquí para abrir el lector de barras',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _skuController.text.isNotEmpty
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _skuController.text.isNotEmpty
                                    ? AppColors.success
                                    : (isDark ? AppColors.onSurfaceVariant : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _skuController.text.isNotEmpty ? 'Re-escanear' : 'Escanear',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Manual barcode input toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showManualSkuInput = !_showManualSkuInput);
                    },
                    icon: Icon(
                      _showManualSkuInput
                          ? Icons.keyboard_hide_rounded
                          : Icons.keyboard_rounded,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    label: Text(
                      _showManualSkuInput ? 'Ocultar teclado manual' : 'Escribir código manual',
                      style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _generateRandomSku,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16, color: AppColors.secondary),
                    label: const Text(
                      'Generar SKU aleatorio',
                      style: TextStyle(fontSize: 12, color: AppColors.secondary),
                    ),
                  ),
                ],
              ),

              if (_showManualSkuInput || _skuController.text.isNotEmpty) ...[
                TextField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'Código de Barras / SKU',
                    hintText: '750103131...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code_rounded),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],

            // Item Name
            TextField(
              controller: _nameController,
              autofocus: _isService,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _isService ? 'Nombre del Servicio *' : 'Nombre del Producto *',
                hintText: _isService
                    ? 'Ej. Corte de cabello, Corte de barba...'
                    : 'Ej. Cera Fijadora Mate 100g, Shampoo...',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(_isService ? Icons.cut_rounded : Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Auto-Generated ID Indicator for Services (Solo Texto)
            if (_isService) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerHigh : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.tag_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ID Asignado Automáticamente:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        const Spacer(),
                        if (!_manualSkuEdited)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Auto-Generado',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _skuController,
                      onChanged: (_) {
                        setState(() => _manualSkuEdited = true);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Ej. CORTE-CABELLO, CORTE-BARBA',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: 'Regenerar desde nombre',
                          icon: const Icon(Icons.sync_rounded, size: 20),
                          onPressed: () {
                            setState(() {
                              _manualSkuEdited = false;
                              _skuController.text = _generateCleanId(_nameController.text);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Se genera a partir del texto sin requerir código de barras físico.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.onSurfaceVariant : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Category Selector
            DropdownButtonFormField<String>(
              initialValue: currentCategories.contains(_selectedCategory)
                  ? _selectedCategory
                  : currentCategories.first,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: currentCategories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 12),

            // Price & Cost / Duration
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio de Venta (\$)*',
                      hintText: '150.00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_isService)
                  Expanded(
                    child: TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duración (min)',
                        hintText: '30',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: TextField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Costo (\$) Opcional',
                        hintText: '75.00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Stock Fields for physical products
            if (!_isService) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock Inicial',
                        hintText: '10',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Alerta Mínima',
                        hintText: '3',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notification_important_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Subtitle / Notes
            TextField(
              controller: _subtitleController,
              decoration: InputDecoration(
                labelText: _isService ? 'Descripción / Detalles' : 'Subtítulo / Marca',
                hintText: _isService ? 'Ej. Corte tradicional con navaja y toalla' : 'Ej. Acabado brillante 150ml',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.short_text_rounded),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isSaving
                      ? 'Guardando...'
                      : (_isService ? 'Guardar Servicio' : 'Guardar Producto'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

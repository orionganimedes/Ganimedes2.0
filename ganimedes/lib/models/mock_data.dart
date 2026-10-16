import 'package:flutter/material.dart';

class PosItem {
  final String id;
  final String sku;
  final String name;
  final String category;
  final double price;
  final double cost;
  final String subtitle;
  final String durationOrStock;
  final int stock;
  final int minStockAlert;
  final int durationMinutes;
  final bool isPopular;
  final IconData icon;
  final bool isService;
  final String branchCode;
  final String businessName;

  const PosItem({
    required this.id,
    this.sku = '',
    required this.name,
    required this.category,
    required this.price,
    this.cost = 0.0,
    required this.subtitle,
    required this.durationOrStock,
    this.stock = 0,
    this.minStockAlert = 0,
    this.durationMinutes = 0,
    this.isPopular = false,
    required this.icon,
    this.isService = true,
    this.branchCode = '',
    this.businessName = '',
  });

  factory PosItem.fromJson(Map<String, dynamic> json) {
    final bool isServ = json['is_service'] == true;
    final int stockVal = (json['stock'] as num?)?.toInt() ?? 0;
    final int durMin = (json['duration_minutes'] as num?)?.toInt() ?? 0;
    final String durStockStr = isServ
        ? (durMin > 0 ? '${durMin}m' : 'Servicio')
        : '$stockVal en stock';

    IconData itemIcon;
    final cat = (json['category_name'] ?? '').toString().toLowerCase();
    if (isServ) {
      if (cat.contains('barba')) {
        itemIcon = Icons.face_retouching_natural_rounded;
      } else if (cat.contains('tratamiento')) {
        itemIcon = Icons.spa_rounded;
      } else {
        itemIcon = Icons.content_cut_rounded;
      }
    } else {
      if (cat.contains('bebida') || cat.contains('bar')) {
        itemIcon = Icons.local_cafe_rounded;
      } else if (cat.contains('tratamiento') || cat.contains('aceite')) {
        itemIcon = Icons.water_drop_rounded;
      } else if (cat.contains('insumo') || cat.contains('navaja')) {
        itemIcon = Icons.hardware_rounded;
      } else {
        itemIcon = Icons.brush_rounded;
      }
    }

    return PosItem(
      id: json['id'] ?? '',
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      category: json['category_name'] ?? 'General',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      subtitle: json['subtitle'] ?? '',
      durationOrStock: durStockStr,
      stock: stockVal,
      minStockAlert: (json['min_stock_alert'] as num?)?.toInt() ?? 0,
      durationMinutes: durMin,
      isPopular: json['is_popular'] == true,
      icon: itemIcon,
      isService: isServ,
      branchCode: json['branch_code'] ?? '',
      businessName: json['business_name'] ?? '',
    );
  }

  Map<String, dynamic> toPocketBaseMap() {
    return {
      'sku': sku,
      'name': name,
      'subtitle': subtitle,
      'category_name': category,
      'price': price,
      'cost': cost,
      'is_service': isService,
      'duration_minutes': durationMinutes,
      'stock': stock,
      'min_stock_alert': minStockAlert,
      'is_popular': isPopular,
      'is_active': true,
      'branch_code': branchCode,
      'business_name': businessName,
    };
  }

  PosItem copyWith({
    String? id,
    String? sku,
    String? name,
    String? category,
    double? price,
    double? cost,
    String? subtitle,
    String? durationOrStock,
    int? stock,
    int? minStockAlert,
    int? durationMinutes,
    bool? isPopular,
    IconData? icon,
    bool? isService,
    String? branchCode,
    String? businessName,
  }) {
    return PosItem(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      subtitle: subtitle ?? this.subtitle,
      durationOrStock: durationOrStock ?? this.durationOrStock,
      stock: stock ?? this.stock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isPopular: isPopular ?? this.isPopular,
      icon: icon ?? this.icon,
      isService: isService ?? this.isService,
      branchCode: branchCode ?? this.branchCode,
      businessName: businessName ?? this.businessName,
    );
  }
}

class CartItem {
  final PosItem item;
  int quantity;

  CartItem({
    required this.item,
    this.quantity = 1,
  });

  double get total => item.price * quantity;
}

class Barber {
  final String id;
  final String name;
  final String chair;
  final String shift;
  final String role;
  final bool isAdmin;

  const Barber({
    required this.id,
    required this.name,
    required this.chair,
    required this.shift,
    required this.role,
    this.isAdmin = false,
  });
}

class MockData {
  MockData._();

  static const List<String> categories = [
    'Todos',
    'Cortes & Barba',
    'Tratamientos',
    'Pomadas & Styling',
    'Bebidas / Bar',
  ];

  static const List<PosItem> items = [
    PosItem(
      id: 'item_1',
      name: 'Fade Clásico',
      category: 'Cortes & Barba',
      price: 280.0,
      subtitle: 'Navaja & Toalla',
      durationOrStock: '35m',
      icon: Icons.content_cut_rounded,
      isService: true,
    ),
    PosItem(
      id: 'item_2',
      name: 'Ritual de Barba',
      category: 'Cortes & Barba',
      price: 200.0,
      subtitle: 'Bálsamo & Vapor',
      durationOrStock: '25m',
      icon: Icons.face_retouching_natural_rounded,
      isService: true,
    ),
    PosItem(
      id: 'item_3',
      name: 'Corte + Barba',
      category: 'Cortes & Barba',
      price: 450.0,
      subtitle: 'Servicio VIP Integral',
      durationOrStock: '60m',
      isPopular: true,
      icon: Icons.auto_awesome_rounded,
      isService: true,
    ),
    PosItem(
      id: 'item_4',
      name: 'Pomada Matte',
      category: 'Pomadas & Styling',
      price: 320.0,
      subtitle: 'Fijación Fuerte 4oz',
      durationOrStock: '14 en stock',
      icon: Icons.brush_rounded,
      isService: false,
    ),
    PosItem(
      id: 'item_5',
      name: 'Aceite Wood & Oak',
      category: 'Tratamientos',
      price: 240.0,
      subtitle: 'Nutrición & Brillo 30ml',
      durationOrStock: '6 en stock',
      icon: Icons.water_drop_rounded,
      isService: false,
    ),
    PosItem(
      id: 'item_6',
      name: 'Cold Brew Artesanal',
      category: 'Bebidas / Bar',
      price: 50.0,
      subtitle: 'Tostado de Origen',
      durationOrStock: '28 en stock',
      icon: Icons.local_cafe_rounded,
      isService: false,
    ),
  ];

  static const List<Barber> barbers = [
    Barber(
      id: 'b1',
      name: 'Carlos Mendoza',
      chair: 'Sillón 01',
      shift: 'Turno Mañana',
      role: 'Master Barber',
      isAdmin: true,
    ),
    Barber(
      id: 'b2',
      name: 'Mateo Style',
      chair: 'Sillón 02',
      shift: 'Turno Mañana',
      role: 'Estilista Senior',
    ),
    Barber(
      id: 'b3',
      name: 'David Cortes',
      chair: 'Sillón 03',
      shift: 'Turno Mañana',
      role: 'Especialista Barba',
    ),
  ];
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mock_data.dart';

class PocketBaseService {
  PocketBaseService._internal() {
    _initDefaultBaseUrl();
  }

  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;

  late String _baseUrl;
  String? _token;
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _primaryAdminUser;
  Map<String, dynamic>? get primaryAdminUser => _primaryAdminUser;

  static const List<String> _candidateUrls = [
    'http://37.60.242.14:8090',  // VPS producción (PocketBase)
    'http://127.0.0.1:8090',    // Desktop, Web, and USB Android phone via adb reverse
    'http://192.168.1.10:8090',  // Local Wi-Fi LAN
    'http://192.168.1.13:8090',  // Local Wi-Fi LAN alternative
    'http://10.0.2.2:8090',     // Android Studio Emulator
  ];

  void _initDefaultBaseUrl() {
    // Default al VPS de producción (PocketBase)
    _baseUrl = 'http://37.60.242.14:8090';
  }

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    String cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    _baseUrl = cleaned;
  }

  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  String get userName => _currentUser?['name'] ?? 'Administrador';
  String get businessName =>
      _currentUser?['business_name'] ?? _currentUser?['name'] ?? 'Ganimedes';
  String get branchCode => _currentUser?['branch_code'] ?? 'central';
  String get userRole => _currentUser?['role'] ?? 'admin';
  bool get isAdmin =>
      userRole.toLowerCase().trim() == 'admin' || userRole.trim().isEmpty;

  bool get isMasterBarber =>
      userRole.toLowerCase().trim() == 'master_barber' ||
      userRole.toLowerCase().trim() == 'master barber';

  bool get isBarber =>
      userRole.toLowerCase().trim() == 'barber' ||
      userRole.toLowerCase().trim() == 'barbero';

  bool get isCashier =>
      userRole.toLowerCase().trim() == 'cashier' ||
      userRole.toLowerCase().trim() == 'cajero' ||
      userRole.toLowerCase().trim() == 'cajera';

  // Permisos según matriz POS:
  bool get canCreateSale => true;
  bool get canViewAllSales => isAdmin || isMasterBarber;
  bool get canCancelSale => isAdmin || isMasterBarber;
  bool get canApplyDiscount => isAdmin || isMasterBarber;
  bool get canAccessInventory => isAdmin || isMasterBarber;
  bool get canViewReports => isAdmin || isMasterBarber;
  bool get canChangeOperator => isAdmin;

  Map<String, String> _headers([bool withAuth = true]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- HEALTH & CONNECTIVITY ---
  Future<bool> testConnection([String? testUrl]) async {
    final url = (testUrl != null && testUrl.isNotEmpty) ? testUrl : _baseUrl;
    try {
      final res = await http
          .get(Uri.parse('$url/api/health'))
          .timeout(const Duration(milliseconds: 2500));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> autoDiscoverServer() async {
    // If current baseUrl works, keep it
    if (await testConnection(_baseUrl)) {
      return true;
    }
    // Try candidates in order
    for (final candidate in _candidateUrls) {
      if (candidate == _baseUrl) continue;
      if (await testConnection(candidate)) {
        _baseUrl = candidate;
        return true;
      }
    }
    return false;
  }

  // --- AUTHENTICATION ---
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    String? businessName,
    String? branchCode,
    String? phone,
    String? pin,
    String role = 'admin',
  }) async {
    await autoDiscoverServer();

    final cleanBiz = (businessName != null && businessName.trim().isNotEmpty)
        ? businessName.trim()
        : 'Mi Negocio';

    final cleanCode = (branchCode != null && branchCode.trim().isNotEmpty)
        ? branchCode.trim()
        : cleanBiz.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    final url = Uri.parse('$_baseUrl/api/collections/users/records');
    final body = jsonEncode({
      'email': email.trim().toLowerCase(),
      'password': password,
      'passwordConfirm': password,
      'name': name.trim(),
      'business_name': cleanBiz,
      'role': role,
      'branch_code': cleanCode,
      'phone': phone?.trim() ?? '',
      'pin': pin?.trim() ?? '',
      'is_active': true,
    });

    final http.Response res;
    try {
      res = await http
          .post(url, headers: _headers(false), body: body)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw Exception(
          'No se pudo conectar a PocketBase ($_baseUrl). Revisa tu conexión a internet.');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // Create primary branch for this business if not existing
      try {
        final branchUrl = Uri.parse('$_baseUrl/api/collections/branches/records');
        final branchBody = jsonEncode({
          'name': '$cleanBiz (Matriz)',
          'code': cleanCode,
          'business_name': cleanBiz,
          'phone': phone?.trim() ?? '',
          'is_active': true,
        });
        await http
            .post(branchUrl, headers: _headers(false), body: branchBody)
            .timeout(const Duration(seconds: 20));
      } catch (_) {}

      // Automatically login after successful sign up
      return await login(email: email, password: password);
    } else {
      String errorMsg = 'Error al registrar usuario en el servidor';
      try {
        final err = jsonDecode(res.body);
        if (err['message'] != null) {
          errorMsg = err['message'];
        }
        if (err['data'] != null && err['data'] is Map) {
          final details = (err['data'] as Map).values.map((v) => v['message']).join(', ');
          if (details.isNotEmpty) errorMsg = details;
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await autoDiscoverServer();

    final url = Uri.parse('$_baseUrl/api/collections/users/auth-with-password');
    final body = jsonEncode({
      'identity': email.trim().toLowerCase(),
      'password': password,
    });

    final http.Response res;
    try {
      res = await http
          .post(url, headers: _headers(false), body: body)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw Exception(
          'No se pudo conectar a PocketBase ($_baseUrl). Revisa tu conexión a internet.');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _token = data['token'];
      _currentUser = data['record'];
      final r = (_currentUser?['role'] ?? '').toString().toLowerCase().trim();
      if (r == 'admin' || r.isEmpty) {
        _primaryAdminUser = _currentUser;
      }
      return data;
    } else {
      String errorMsg = 'Credenciales inválidas o servidor inaccesible';
      try {
        final err = jsonDecode(res.body);
        if (err['message'] != null) {
          errorMsg = err['message'];
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }

  Future<Map<String, dynamic>?> loginWithPin(String pin, [String? targetUserId]) async {
    await autoDiscoverServer();
    final cleanPin = pin.trim();
    String filter;
    if (targetUserId != null && targetUserId.isNotEmpty) {
      filter = Uri.encodeComponent("id='$targetUserId' && pin='$cleanPin' && is_active=true");
    } else {
      filter = Uri.encodeComponent("pin='$cleanPin' && is_active=true");
    }
    final url = Uri.parse('$_baseUrl/api/collections/users/records?filter=$filter');

    final res = await http.get(url, headers: _headers(false));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      final items = data['items'] as List?;
      if (items != null && items.isNotEmpty) {
        final selected = items.first as Map<String, dynamic>;
        switchOperator(selected);
        return _currentUser;
      }
    }
    return null;
  }

  void switchOperator(Map<String, dynamic> operator) {
    if (isAdmin && _primaryAdminUser == null) {
      _primaryAdminUser = _currentUser;
    }
    _currentUser = Map<String, dynamic>.from(operator);
  }

  void restoreAdminOperator() {
    if (_primaryAdminUser != null) {
      _currentUser = _primaryAdminUser;
    }
  }

  void logout() {
    _token = null;
    _currentUser = null;
    _primaryAdminUser = null;
  }

  // --- TEAM & ROLE MANAGEMENT ---
  Future<List<Map<String, dynamic>>> getTeamMembers() async {
    await autoDiscoverServer();
    try {
      String filterQuery = '';
      if (branchCode.isNotEmpty && branchCode != 'central') {
        filterQuery = '&filter=${Uri.encodeComponent("branch_code='$branchCode' && is_active=true")}';
      } else if (businessName.isNotEmpty && businessName != 'Ganimedes') {
        filterQuery = '&filter=${Uri.encodeComponent("business_name='$businessName' && is_active=true")}';
      } else {
        filterQuery = '&filter=${Uri.encodeComponent("is_active=true")}';
      }
      final url = Uri.parse('$_baseUrl/api/collections/users/records?sort=-created$filterQuery');
      final res = await http.get(url, headers: _headers(false));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    // Fallback: If no users returned, include active user so list is never empty
    if (_currentUser != null) {
      return [_currentUser!];
    }
    return [];
  }

  Future<Map<String, dynamic>> createTeamMember({
    required String name,
    required String role,
    required String pin,
    String? phone,
    String? email,
    String? password,
  }) async {
    await autoDiscoverServer();
    final cleanName = name.trim();
    final cleanRole = role.trim().toLowerCase();
    final cleanPin = pin.trim();
    final safeBiz = businessName;
    final safeBranch = branchCode;

    final userEmail = (email != null && email.trim().isNotEmpty)
        ? email.trim().toLowerCase()
        : '${cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}_${DateTime.now().millisecondsSinceEpoch % 100000}@${safeBranch.isNotEmpty ? safeBranch : 'central'}.ganimedes.pos';

    final userPass = (password != null && password.trim().length >= 8)
        ? password.trim()
        : (cleanPin.length >= 8 ? cleanPin : '${cleanPin}123456');

    final url = Uri.parse('$_baseUrl/api/collections/users/records');
    final body = jsonEncode({
      'email': userEmail,
      'password': userPass,
      'passwordConfirm': userPass,
      'name': cleanName,
      'role': cleanRole,
      'pin': cleanPin,
      'phone': phone?.trim() ?? '',
      'business_name': safeBiz,
      'branch_code': safeBranch,
      'is_active': true,
    });

    final res = await http.post(url, headers: _headers(false), body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      String errorMsg = 'Error al registrar operador';
      try {
        final err = jsonDecode(res.body);
        if (err['message'] != null) errorMsg = err['message'];
        if (err['data'] != null && err['data'] is Map) {
          final details = (err['data'] as Map).values.map((v) => v['message']).join(', ');
          if (details.isNotEmpty) errorMsg = details;
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }

  Future<Map<String, dynamic>> updateTeamMember(String id, Map<String, dynamic> data) async {
    await autoDiscoverServer();
    final url = Uri.parse('$_baseUrl/api/collections/users/records/$id');
    final res = await http.patch(url, headers: _headers(true), body: jsonEncode(data));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error al actualizar operador');
  }

  Future<bool> deleteTeamMember(String id) async {
    await autoDiscoverServer();
    try {
      final url = Uri.parse('$_baseUrl/api/collections/users/records/$id');
      final res = await http.patch(
        url,
        headers: _headers(true),
        body: jsonEncode({'is_active': false}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // --- BRANCHES & SUB-BRANCHES ("SUB CARPETAS") ---
  Future<List<Map<String, dynamic>>> getBranches([String? filterBusiness]) async {
    try {
      final biz = filterBusiness ?? (businessName != 'Ganimedes' ? businessName : '');
      String filterQuery = '';
      if (biz.isNotEmpty) {
        filterQuery = '&filter=${Uri.encodeComponent("business_name='$biz' || business_name=''")}';
      }
      final url = Uri.parse('$_baseUrl/api/collections/branches/records?sort=name$filterQuery');
      final res = await http.get(url, headers: _headers(false));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> createBranch({
    required String name,
    required String code,
    String? address,
    String? phone,
    String? businessName,
    String? parentId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/collections/branches/records');
      final body = jsonEncode({
        'name': name.trim(),
        'code': code.trim().toLowerCase(),
        'address': address?.trim() ?? '',
        'phone': phone?.trim() ?? '',
        'business_name': businessName ?? this.businessName,
        'parent_id': parentId ?? '',
        'is_active': true,
      });
      final res = await http.post(url, headers: _headers(false), body: body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // --- CATEGORIES ---
  Future<List<String>> getCategories() async {
    try {
      final url = Uri.parse('$_baseUrl/api/collections/categories/records?sort=order');
      final res = await http.get(url, headers: _headers(false));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        final names = <String>['Todos'];
        for (final item in items) {
          final n = item['name'] as String?;
          if (n != null && n.isNotEmpty && !names.contains(n)) {
            names.add(n);
          }
        }
        return names;
      }
    } catch (_) {}
    return MockData.categories;
  }

  Future<bool> createCategory(String name, {bool isService = false}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/collections/categories/records');
      final body = jsonEncode({
        'name': name.trim(),
        'slug': name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
        'order': 99,
        'is_service': isService,
      });
      final res = await http.post(url, headers: _headers(false), body: body);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // --- PRODUCTS & SERVICES (INVENTORY) ---
  Future<List<PosItem>> getProductsServices({
    String? category,
    String? search,
  }) async {
    final filters = <String>[];

    // Multi-tenant business isolation: each business/user only sees their own inventory
    if (branchCode.isNotEmpty) {
      filters.add("(branch_code='$branchCode')");
    }

    if (category != null && category.isNotEmpty && category != 'Todos') {
      filters.add("(category_name='$category')");
    }

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim();
      filters.add("(name~'$q' || sku~'$q')");
    }

    final filterQuery = filters.isNotEmpty
        ? '&filter=${Uri.encodeComponent(filters.join(' && '))}'
        : '';
    final url = Uri.parse(
        '$_baseUrl/api/collections/products_services/records?perPage=200$filterQuery');

    try {
      final res = await http.get(url, headers: _headers(false));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        return items.map((json) => PosItem.fromJson(json)).toList();
      } else {
        // Return empty list quietly when collection is empty or initial state
        return [];
      }
    } catch (_) {
      // Quiet fallback: return empty list without throwing UI-blocking error
      return [];
    }
  }

  Future<PosItem> createProductService(PosItem item) async {
    final map = item.toPocketBaseMap();
    if ((map['branch_code'] ?? '').toString().isEmpty) {
      map['branch_code'] = branchCode;
    }
    if ((map['business_name'] ?? '').toString().isEmpty) {
      map['business_name'] = businessName;
    }

    final url = Uri.parse('$_baseUrl/api/collections/products_services/records');
    final body = jsonEncode(map);

    final res = await http.post(url, headers: _headers(false), body: body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      return PosItem.fromJson(data);
    } else {
      String msg = 'Error al guardar producto';
      try {
        final err = jsonDecode(res.body);
        if (err['message'] != null) msg = err['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<bool> updateProductService(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/api/collections/products_services/records/$id');
    final res = await http.patch(url, headers: _headers(false), body: jsonEncode(data));
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> deleteProductService(String id) async {
    final url = Uri.parse('$_baseUrl/api/collections/products_services/records/$id');
    final res = await http.delete(url, headers: _headers(false));
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<PosItem?> findProductByBarcode(String barcode) async {
    final clean = barcode.trim();
    if (clean.isEmpty) return null;

    final filterParts = ["sku='$clean'", "is_active=true"];
    if (branchCode.isNotEmpty) {
      filterParts.add("branch_code='$branchCode'");
    }
    final filter = Uri.encodeComponent(filterParts.join(' && '));
    final url = Uri.parse(
        '$_baseUrl/api/collections/products_services/records?filter=$filter');

    final res = await http.get(url, headers: _headers(false));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final items = data['items'] as List?;
      if (items != null && items.isNotEmpty) {
        return PosItem.fromJson(items.first as Map<String, dynamic>);
      }
    }
    return null;
  }

  // --- SALES & TICKETS ---
  Future<Map<String, dynamic>> createSale({
    required String folio,
    required double subtotal,
    required double discount,
    required double total,
    required String paymentMethod,
    double? cashReceived,
    double? changeReturned,
    required List<CartItem> cartItems,
    String? clientName,
    String? barberName,
    String? branch,
  }) async {
    final url = Uri.parse('$_baseUrl/api/collections/sales/records');
    final saleBody = jsonEncode({
      'folio': folio,
      'branch_code': branch ?? branchCode,
      'business_name': businessName,
      'barber_name': barberName ?? userName,
      'client_name': clientName ?? 'Cliente General',
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'cash_received': cashReceived ?? total,
      'change_returned': changeReturned ?? 0.0,
      'status': 'completed',
    });

    final res = await http.post(url, headers: _headers(false), body: saleBody);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final saleRecord = jsonDecode(res.body) as Map<String, dynamic>;

      // Insert line items and decrement stock for physical products
      for (final cartItem in cartItems) {
        final itemUrl = Uri.parse('$_baseUrl/api/collections/sale_items/records');
        final itemBody = jsonEncode({
          'sale_folio': folio,
          'business_name': businessName,
          'product_name': cartItem.item.name,
          'unit_price': cartItem.item.price,
          'quantity': cartItem.quantity,
          'total': cartItem.total,
        });
        await http.post(itemUrl, headers: _headers(false), body: itemBody);

        // Decrement stock if product is physical and has an ID
        if (!cartItem.item.isService && cartItem.item.id.isNotEmpty) {
          final newStock = (cartItem.item.stock - cartItem.quantity).clamp(0, 999999);
          await updateProductService(cartItem.item.id, {'stock': newStock});
        }
      }

      return saleRecord;
    } else {
      throw Exception('Error al registrar venta: ${res.statusCode}');
    }
  }

  Future<String> getNextFolio() async {
    try {
      final branchFilter = branchCode.isNotEmpty
          ? '&filter=${Uri.encodeComponent("branch_code='$branchCode'")}'
          : '';
      final url = Uri.parse('$_baseUrl/api/collections/sales/records?perPage=1$branchFilter');
      final res = await http.get(url, headers: _headers(false));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final totalItems = (data['totalItems'] as num?)?.toInt() ?? 0;
        final nextNum = 1001 + totalItems;
        return '#TK-$nextNum';
      }
    } catch (_) {}
    final randomPart = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '#TK-$randomPart';
  }

  Future<List<Map<String, dynamic>>> getSales({
    int limit = 100,
    String? barberName,
  }) async {
    try {
      final List<String> filters = [];
      if (branchCode.isNotEmpty) {
        filters.add("branch_code='$branchCode'");
      }
      if (barberName != null && barberName.isNotEmpty) {
        filters.add("barber_name='$barberName'");
      } else if (!canViewAllSales && userName.isNotEmpty) {
        filters.add("barber_name='$userName'");
      }

      final filterQuery = filters.isNotEmpty
          ? '?filter=${Uri.encodeComponent(filters.join(' && '))}&perPage=$limit'
          : '?perPage=$limit';
      final url = Uri.parse('$_baseUrl/api/collections/sales/records$filterQuery');
      final res = await http.get(url, headers: _headers(false));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = List<Map<String, dynamic>>.from(data['items'] ?? []);
        // In PocketBase without sort, newest items are at the end; reverse so newest appear first
        return list.reversed.toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> cancelSale(String saleId, {String? folio}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/collections/sales/records/$saleId');
      final res = await http.patch(
        url,
        headers: _headers(false),
        body: jsonEncode({'status': 'cancelled'}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        // If folio is provided, restore product stock for physical sale items
        if (folio != null && folio.isNotEmpty) {
          final items = await getSaleItems(folio);
          for (final item in items) {
            final productName = item['product_name']?.toString() ?? '';
            final qty = (item['quantity'] as num?)?.toInt() ?? 0;
            if (qty > 0 && productName.isNotEmpty) {
              try {
                final searchRes = await http.get(
                  Uri.parse(
                    '$_baseUrl/api/collections/products/records?filter=${Uri.encodeComponent("name='$productName'")}&perPage=1',
                  ),
                  headers: _headers(false),
                );
                if (searchRes.statusCode == 200) {
                  final sData = jsonDecode(searchRes.body);
                  final pItems = sData['items'] as List?;
                  if (pItems != null && pItems.isNotEmpty) {
                    final p = pItems[0];
                    final isService = p['is_service'] == true;
                    if (!isService) {
                      final currStock = (p['stock'] as num?)?.toInt() ?? 0;
                      await updateProductService(p['id'], {'stock': currStock + qty});
                    }
                  }
                }
              } catch (_) {}
            }
          }
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<Map<String, dynamic>>> getSaleItems(String folio) async {
    try {
      final filter = Uri.encodeComponent("sale_folio='$folio'");
      final url = Uri.parse(
          '$_baseUrl/api/collections/sale_items/records?filter=$filter&perPage=100');
      final res = await http.get(url, headers: _headers(false));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  // --- CASH SHIFT & REGISTER ---
  double _initialFund = 0.0;
  DateTime _shiftStartTime = DateTime.now();

  double get initialFund => _initialFund;
  DateTime get shiftStartTime => _shiftStartTime;

  void setInitialFund(double fund) {
    _initialFund = fund;
  }

  void resetShift({double newFund = 0.0}) {
    _initialFund = newFund;
    _shiftStartTime = DateTime.now();
  }

  Future<Map<String, dynamic>> getCashRegisterSummary() async {
    try {
      final sales = await getSales(limit: 200);

      double totalSales = 0.0;
      int ticketCount = 0;

      double cashTotal = 0.0;
      int cashCount = 0;

      double cardTotal = 0.0;
      int cardCount = 0;

      double transferTotal = 0.0;
      int transferCount = 0;

      for (final sale in sales) {
        final status = sale['status']?.toString().toLowerCase();
        if (status != null && status != 'completed') continue;

        final total = (sale['total'] as num?)?.toDouble() ?? 0.0;
        totalSales += total;
        ticketCount++;

        final method = (sale['payment_method'] ?? '').toString().toLowerCase();
        if (method.contains('cash') || method.contains('efectivo')) {
          cashTotal += total;
          cashCount++;
        } else if (method.contains('card') || method.contains('tarjeta')) {
          cardTotal += total;
          cardCount++;
        } else {
          transferTotal += total;
          transferCount++;
        }
      }

      return {
        'totalSales': totalSales,
        'ticketCount': ticketCount,
        'cashTotal': cashTotal,
        'cashCount': cashCount,
        'cardTotal': cardTotal,
        'cardCount': cardCount,
        'transferTotal': transferTotal,
        'transferCount': transferCount,
        'initialFund': _initialFund,
        'cashInDrawer': _initialFund + cashTotal,
      };
    } catch (_) {
      return {
        'totalSales': 0.0,
        'ticketCount': 0,
        'cashTotal': 0.0,
        'cashCount': 0,
        'cardTotal': 0.0,
        'cardCount': 0,
        'transferTotal': 0.0,
        'transferCount': 0,
        'initialFund': _initialFund,
        'cashInDrawer': _initialFund,
      };
    }
  }

  Future<Map<String, dynamic>> closeCashShift({
    required double initialCash,
    required double expectedCash,
    required double actualCash,
    required double totalSales,
    required double cashSales,
    required double cardSales,
    required double speiSales,
    required int ticketsCount,
    String? notes,
  }) async {
    final url = Uri.parse('$_baseUrl/api/collections/cash_shifts/records');
    final diff = actualCash - expectedCash;
    final now = DateTime.now();
    final shiftName = now.hour < 15 ? 'Turno Matutino' : 'Turno Vespertino';
    final body = jsonEncode({
      'branch_code': branchCode.isNotEmpty ? branchCode : 'matriz',
      'business_name': businessName,
      'shift_name': shiftName,
      'operator_name': userName.isNotEmpty ? userName : 'Operador',
      'status': 'closed',
      'initial_cash': initialCash,
      'expected_cash': expectedCash,
      'actual_cash': actualCash,
      'total_sales': totalSales,
      'cash_sales': cashSales,
      'card_sales': cardSales,
      'spei_sales': speiSales,
      'tickets_count': ticketsCount,
      'difference': diff,
      'opened_at': shiftStartTime.toUtc().toIso8601String(),
      'closed_at': now.toUtc().toIso8601String(),
      'notes': notes ?? '',
    });

    final res = await http.post(url, headers: _headers(false), body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      resetShift();
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al registrar corte de caja en servidor (${res.statusCode})');
    }
  }

  // --- PERFIL DE IA (alimentación del agente por negocio) ---
  Future<Map<String, dynamic>?> _findAiProfile() async {
    try {
      final filter = Uri.encodeComponent("business_name='$businessName'");
      final url = Uri.parse(
          '$_baseUrl/api/collections/ai_profiles/records?filter=$filter&perPage=1');
      final res = await http
          .get(url, headers: _headers(false))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          return items.first as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Guarda el perfil de "alimentación" de la IA del negocio.
  /// Lo persiste localmente (offline-first) y lo sincroniza con PocketBase.
  Future<bool> saveAiProfile({
    required String ownerName,
    required String businessType,
    required String servicesSummary,
    required String tone,
    required String specialInstructions,
  }) async {
    final profile = {
      'business_name': businessName,
      'owner_name': ownerName,
      'business_type': businessType,
      'services_summary': servicesSummary,
      'tone': tone,
      'special_instructions': specialInstructions,
    };

    // 1) Guardar local (para modo offline)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_profile_$businessName', jsonEncode(profile));
    } catch (_) {}

    // 2) Sincronizar con PocketBase (upsert por business_name)
    try {
      final existing = await _findAiProfile();
      if (existing != null) {
        final id = existing['id'];
        final url =
            Uri.parse('$_baseUrl/api/collections/ai_profiles/records/$id');
        final res = await http
            .patch(
              url,
              headers: _headers(false),
              body: jsonEncode(profile),
            )
            .timeout(const Duration(seconds: 15));
        return res.statusCode >= 200 && res.statusCode < 300;
      } else {
        final url =
            Uri.parse('$_baseUrl/api/collections/ai_profiles/records');
        final res = await http
            .post(
              url,
              headers: _headers(false),
              body: jsonEncode(profile),
            )
            .timeout(const Duration(seconds: 15));
        return res.statusCode >= 200 && res.statusCode < 300;
      }
    } catch (_) {
      // Sin conexión: ya quedó guardado localmente para sincronizar después.
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAiProfile() async {
    final remote = await _findAiProfile();
    if (remote != null) return remote;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ai_profile_$businessName');
      if (raw != null) return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }
}


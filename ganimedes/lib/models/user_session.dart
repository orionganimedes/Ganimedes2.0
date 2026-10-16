class UserSession {
  final String id;
  final String name;
  final String email;
  final String role;
  final String branchCode;
  final String businessName;
  final String? phone;
  final String? avatar;

  const UserSession({
    required this.id,
    required this.name,
    this.email = '',
    required this.role,
    required this.branchCode,
    required this.businessName,
    this.phone,
    this.avatar,
  });

  bool get isAdmin =>
      role.toLowerCase().trim() == 'admin' || role.trim().isEmpty;

  bool get isMasterBarber =>
      role.toLowerCase().trim() == 'master_barber' ||
      role.toLowerCase().trim() == 'master barber';

  bool get isBarber =>
      role.toLowerCase().trim() == 'barber' ||
      role.toLowerCase().trim() == 'barbero';

  bool get isCashier =>
      role.toLowerCase().trim() == 'cashier' ||
      role.toLowerCase().trim() == 'cajero' ||
      role.toLowerCase().trim() == 'cajera';

  // Permisos según matriz POS:
  bool get canCreateSale => true;
  bool get canViewAllSales => isAdmin || isMasterBarber;
  bool get canCancelSale => isAdmin || isMasterBarber;
  bool get canApplyDiscount => isAdmin || isMasterBarber;
  bool get canAccessInventory => isAdmin || isMasterBarber;
  bool get canViewReports => isAdmin || isMasterBarber;
  bool get canChangeOperator => isAdmin;

  factory UserSession.fromPocketBase(Map<String, dynamic>? record) {
    if (record == null) {
      return const UserSession(
        id: '',
        name: 'Administrador',
        role: 'admin',
        branchCode: 'matriz',
        businessName: 'Mi Negocio',
      );
    }
    return UserSession(
      id: record['id'] ?? '',
      name: record['name'] ?? 'Administrador',
      email: record['email'] ?? '',
      role: record['role'] ?? 'admin',
      branchCode: record['branch_code'] ?? 'central',
      businessName: record['business_name'] ?? record['name'] ?? 'Ganimedes POS',
      phone: record['phone'],
      avatar: record['avatar'],
    );
  }
}

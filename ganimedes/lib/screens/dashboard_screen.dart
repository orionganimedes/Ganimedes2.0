import 'package:flutter/material.dart';
import '../services/pocketbase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/modals/team_management_modal.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigateToTab;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _productCount = 0;
  double _todaySales = 0.0;
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    reloadMetrics();
  }

  Future<void> reloadMetrics() async {
    try {
      final pb = PocketBaseService();
      final productsFuture = pb.getProductsServices();
      final registerFuture = pb.getCashRegisterSummary();
      final teamFuture = pb.getTeamMembers();

      final results = await Future.wait([productsFuture, registerFuture, teamFuture]);
      if (mounted) {
        final products = results[0] as List;
        final summary = results[1] as Map<String, dynamic>;
        final team = results[2] as List<Map<String, dynamic>>;
        setState(() {
          _productCount = products.length;
          _todaySales = (summary['totalSales'] as num?)?.toDouble() ?? 0.0;
          _teamMembers = team;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pb = PocketBaseService();
    final name = pb.userName.isNotEmpty ? pb.userName : 'Bienvenido';
    final biz = pb.businessName.isNotEmpty ? pb.businessName : 'Mi Negocio';
    final branch = pb.branchCode.isNotEmpty ? pb.branchCode.toUpperCase() : 'CENTRAL';

    return RefreshIndicator(
      onRefresh: reloadMetrics,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // Welcome Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceContainerHigh,
                  AppColors.surfaceContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PANEL OPERATIVO',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Activo',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Hola, $name',
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$biz • Sucursal $branch • Terminal POS Activa',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Quick POS CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => widget.onNavigateToTab(1), // Go to POS tab
                    icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                    label: const Text('Abrir Terminal POS'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Team & Operators Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EQUIPO Y ROLES EN SUCURSAL',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              if (pb.isAdmin)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.secondary,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => TeamManagementModal.show(context).then((_) => reloadMetrics()),
                  icon: const Icon(Icons.group_add_rounded, size: 15),
                  label: const Text('Administrar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_teamMembers.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline_rounded, color: AppColors.secondary, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No hay operadores registrados aún.',
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                  if (pb.isAdmin)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => TeamManagementModal.show(context).then((_) => reloadMetrics()),
                      child: const Text('Agregar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            )
          else
            ..._teamMembers.map((member) {
              final memberName = (member['name'] ?? 'Operador').toString();
              final role = (member['role'] ?? 'barber').toString().toLowerCase().trim();
              final pin = (member['pin'] ?? '****').toString();

              Color roleColor = AppColors.secondary;
              String roleLabel = 'ADMIN';
              IconData roleIcon = Icons.workspace_premium_rounded;

              if (role == 'master_barber') {
                roleColor = AppColors.primary;
                roleLabel = 'MASTER BARBER';
                roleIcon = Icons.content_cut_rounded;
              } else if (role == 'barber') {
                roleColor = AppColors.tertiary;
                roleLabel = 'BARBER';
                roleIcon = Icons.brush_rounded;
              } else if (role == 'cashier') {
                roleColor = AppColors.success;
                roleLabel = 'CASHIER';
                roleIcon = Icons.point_of_sale_rounded;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(roleIcon, color: roleColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                memberName,
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PIN Acceso POS: $pin',
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),

          // Quick Shortcuts
          const Text(
            'ACCESOS RÁPIDOS',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.inventory_2_rounded,
                  title: 'Inventario',
                  subtitle: _isLoading
                      ? 'Cargando...'
                      : '$_productCount productos',
                  onTap: () => widget.onNavigateToTab(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.payments_rounded,
                  title: 'Corte de Caja',
                  subtitle: _isLoading
                      ? 'Cargando...'
                      : '\$${_todaySales.toStringAsFixed(2)} hoy',
                  onTap: () => widget.onNavigateToTab(3),
                ),
              ),
              if (pb.isAdmin) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.badge_rounded,
                    title: 'Equipo',
                    subtitle: _isLoading
                        ? 'Cargando...'
                        : '${_teamMembers.length} operadores',
                    onTap: () => TeamManagementModal.show(context).then((_) => reloadMetrics()),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.secondary, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

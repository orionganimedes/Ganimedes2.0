import 'package:flutter/material.dart';
import '../services/pocketbase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/auth/pin_access_dialog.dart';
import '../widgets/floating_dock.dart';
import 'cash_register_screen.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'pos_screen.dart';
import 'ai_assistant_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1; // Default to POS tab as requested by POS workflow
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();
  final GlobalKey<PosScreenState> _posKey = GlobalKey<PosScreenState>();
  final GlobalKey<InventoryScreenState> _inventoryKey = GlobalKey<InventoryScreenState>();
  final GlobalKey<CashRegisterScreenState> _cashRegisterKey = GlobalKey<CashRegisterScreenState>();

  void _onSwitchOperator() {
    PinAccessDialog.show(
      context,
      onOperatorSelected: (barber) {
        setState(() {
          final pb = PocketBaseService();
          if (!pb.isAdmin && _currentIndex == 4) _currentIndex = 1;
          if (!pb.canAccessInventory && _currentIndex == 2) _currentIndex = 1;
          if (!pb.canViewReports && _currentIndex == 0) _currentIndex = 1;
        });
        _posKey.currentState?.reloadCatalog();
        _cashRegisterKey.currentState?.reloadSummary();
      },
    );
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      _dashboardKey.currentState?.reloadMetrics();
    } else if (index == 1) {
      _posKey.currentState?.reloadCatalog();
    } else if (index == 2) {
      _inventoryKey.currentState?.reloadData();
    } else if (index == 3) {
      _cashRegisterKey.currentState?.reloadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pb = PocketBaseService();
    final isAdmin = pb.isAdmin;
    final canAccessInventory = pb.canAccessInventory;
    final canViewReports = pb.canViewReports;

    // Sanitize current index according to permissions
    int safeIndex = _currentIndex;
    if (!isAdmin && safeIndex == 4) safeIndex = 1;
    if (!canAccessInventory && safeIndex == 2) safeIndex = 1;
    if (!canViewReports && safeIndex == 0) safeIndex = 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        onSwitchOperator: pb.canChangeOperator ? _onSwitchOperator : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: safeIndex,
              children: [
                DashboardScreen(
                  key: _dashboardKey,
                  onNavigateToTab: _onTabSelected,
                ),
                PosScreen(key: _posKey),
                InventoryScreen(key: _inventoryKey),
                CashRegisterScreen(
                  key: _cashRegisterKey,
                  onNavigateToPos: () => _onTabSelected(1),
                ),
                AiAssistantScreen(
                  onNavigateToTab: _onTabSelected,
                ),
              ],
            ),
          ),
          FloatingDock(
            currentIndex: safeIndex,
            isAdmin: isAdmin,
            canAccessInventory: canAccessInventory,
            canViewReports: canViewReports,
            onTabSelected: _onTabSelected,
          ),
        ],
      ),
    );
  }
}

class _SettingsDraftScreen extends StatefulWidget {
  const _SettingsDraftScreen();

  @override
  State<_SettingsDraftScreen> createState() => _SettingsDraftScreenState();
}

class _SettingsDraftScreenState extends State<_SettingsDraftScreen> {
  List<Map<String, dynamic>> _branches = [];
  bool _isLoadingBranches = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoadingBranches = true);
    final branches = await PocketBaseService().getBranches();
    if (mounted) {
      setState(() {
        _branches = branches;
        _isLoadingBranches = false;
      });
    }
  }

  void _showAddBranchDialog() {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceContainer : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.add_business_rounded, color: AppColors.secondary, size: 22),
                SizedBox(width: 10),
                Text('Nueva Sucursal / Carpeta', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombre de la Sucursal o Sub-área *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Sucursal Roma Norte o Cabina VIP',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Dirección', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Av. Álvaro Obregón 120',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Teléfono', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '55 1234 5678',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        setDlgState(() => isSaving = true);
                        final code = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                        final res = await PocketBaseService().createBranch(
                          name: name,
                          code: code,
                          address: addressCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                        );
                        if (res != null) {
                          await _loadBranches();
                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('¡Sucursal "$name" creada exitosamente!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          setDlgState(() => isSaving = false);
                        }
                      },
                child: Text(isSaving ? 'Guardando...' : 'Crear Sucursal'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBranchesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final pb = PocketBaseService();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pb.businessName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Text(
                        'Sucursales y Sub-carpetas de Negocio',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddBranchDialog();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nueva', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoadingBranches)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.secondary),
                ))
              else if (_branches.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No hay sucursales registradas.'),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _branches.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final b = _branches[idx];
                      final name = b['name'] ?? 'Sucursal';
                      final code = b['code'] ?? '';
                      final isCurrent = code == pb.branchCode;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.secondary.withValues(alpha: 0.12)
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? AppColors.secondary : AppColors.borderSoft,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              color: isCurrent ? AppColors.secondary : AppColors.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isCurrent ? AppColors.secondary : AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Código: $code',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ACTIVA',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pb = PocketBaseService();
    final biz = pb.businessName;
    final branch = pb.branchCode.toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        const Text(
          'Configuración & Terminal',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Negocio: $biz • Terminal POS',
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        _SettingsTile(
          icon: Icons.storefront_rounded,
          title: 'Sucursales & Carpetas',
          subtitle: 'Sucursal activa: $branch (${_branches.length} registradas)',
          trailing: 'Administrar',
          onTap: _showBranchesModal,
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.print_rounded,
          title: 'Impresora Térmica 80mm',
          subtitle: 'Bluetooth POS-80 conectada',
          trailing: 'Configurar',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.lock_rounded,
          title: 'Gaveta de Dinero RJ11',
          subtitle: 'Apertura automática tras cobro',
          trailing: 'Activo',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.cloud_sync_rounded,
          title: 'Sincronización PocketBase',
          subtitle: 'Modo Offline-First habilitado',
          trailing: 'Sync',
          onTap: () async {
            await PocketBaseService().autoDiscoverServer();
            final ok = await PocketBaseService().testConnection();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok ? 'Conectado a PocketBase en ${PocketBaseService().baseUrl}' : 'PocketBase no disponible'),
                backgroundColor: ok ? AppColors.success : AppColors.error,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 20),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

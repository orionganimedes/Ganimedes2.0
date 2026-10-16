import 'package:flutter/material.dart';
import '../../services/pocketbase_service.dart';
import '../../theme/app_colors.dart';

class TeamManagementModal extends StatefulWidget {
  const TeamManagementModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const TeamManagementModal(),
    );
  }

  @override
  State<TeamManagementModal> createState() => _TeamManagementModalState();
}

class _TeamManagementModalState extends State<TeamManagementModal> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  bool _showCreateForm = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'barber';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final members = await PocketBaseService().getTeamMembers();
    if (mounted) {
      setState(() {
        _members = members;
        _isLoading = false;
      });
    }
  }

  Future<void> _onCreateMember() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Ingresa el nombre del operador');
      return;
    }
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _errorMessage = 'El PIN debe ser exactamente de 4 dígitos numéricos');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await PocketBaseService().createTeamMember(
        name: name,
        role: _selectedRole,
        pin: pin,
        phone: _phoneController.text.trim(),
      );

      _nameController.clear();
      _pinController.clear();
      _phoneController.clear();
      _selectedRole = 'barber';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Operador "$name" agregado con éxito!'),
          backgroundColor: AppColors.success,
        ),
      );

      setState(() {
        _showCreateForm = false;
        _isSaving = false;
      });
      _loadMembers();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _onDeleteMember(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('Desactivar Operador'),
        content: Text('¿Seguro que deseas dar de baja a $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PocketBaseService().deleteTeamMember(id);
      _loadMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              children: [
                // Modal Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.badge_rounded, color: AppColors.secondary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestión de Equipo y Roles',
                                style: TextStyle(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Control de operadores y permisos POS',
                                style: TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 11,
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
                ),
                const Divider(height: 1),

                // View Toggle / Action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !_showCreateForm
                                ? AppColors.secondary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            foregroundColor: !_showCreateForm ? AppColors.secondary : AppColors.onSurface,
                            side: BorderSide(
                              color: !_showCreateForm ? AppColors.secondary : AppColors.borderSoft,
                            ),
                          ),
                          onPressed: () => setState(() => _showCreateForm = false),
                          icon: const Icon(Icons.people_alt_rounded, size: 16),
                          label: Text('Miembros (${_members.length})'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showCreateForm ? AppColors.secondary : AppColors.surfaceContainerHigh,
                            foregroundColor: _showCreateForm ? Colors.black : AppColors.onSurface,
                          ),
                          onPressed: () => setState(() => _showCreateForm = true),
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                          label: const Text('Nuevo Operador'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body Content
                Expanded(
                  child: _showCreateForm ? _buildCreateForm() : _buildMembersList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text(
              'No hay operadores registrados aún',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.black,
              ),
              onPressed: () => setState(() => _showCreateForm = true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar Primer Operador'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final id = member['id']?.toString() ?? '';
        final name = (member['name'] ?? 'Operador').toString();
        final role = (member['role'] ?? 'barber').toString().toLowerCase().trim();
        final pin = (member['pin'] ?? '****').toString();
        final phone = (member['phone'] ?? '').toString();

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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: roleColor.withValues(alpha: 0.5)),
                ),
                child: Icon(roleIcon, color: roleColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.borderSoft),
                          ),
                          child: Text(
                            'PIN: $pin',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            phone,
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (role != 'admin')
                IconButton(
                  tooltip: 'Desactivar',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: () => _onDeleteMember(id, name),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Name
          const Text('NOMBRE DEL OPERADOR', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Ej. Mateo Style',
              prefixIcon: const Icon(Icons.person_rounded, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),

          // Role Selection Cards
          const Text('ROL Y PERMISOS EN SISTEMA', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _roleCard(
            role: 'master_barber',
            title: 'Master Barber',
            description: 'Ventas, todas las órdenes, cancelar ticket, descuentos e inventario.',
            icon: Icons.content_cut_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: 6),
          _roleCard(
            role: 'barber',
            title: 'Barber (Barbero)',
            description: 'Vender y ver exclusivamente sus propias ventas.',
            icon: Icons.brush_rounded,
            color: AppColors.tertiary,
          ),
          const SizedBox(height: 6),
          _roleCard(
            role: 'cashier',
            title: 'Cashier (Cajero)',
            description: 'Cobrar en terminal y ver exclusivamente sus propias ventas.',
            icon: Icons.point_of_sale_rounded,
            color: AppColors.success,
          ),
          const SizedBox(height: 6),
          _roleCard(
            role: 'admin',
            title: 'Administrador',
            description: 'Acceso total y autorización para cambiar de operador.',
            icon: Icons.workspace_premium_rounded,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 14),

          // PIN & Phone
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PIN (4 DÍGITOS)', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        hintText: '1234',
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TELÉFONO (OPCIONAL)', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '5512345678',
                        prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _onCreateMember,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(
                _isSaving ? 'Guardando en PocketBase...' : 'Registrar Operador',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _roleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.borderSoft,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? color : AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

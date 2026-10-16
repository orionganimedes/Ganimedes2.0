import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../services/pocketbase_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import 'modals/team_management_modal.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSwitchOperator;

  const AppTopBar({
    super.key,
    this.onSwitchOperator,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  void _onLogout(BuildContext context) {
    PocketBaseService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeController.instance.isDarkMode;
    final pb = PocketBaseService();
    final userName = pb.userName;
    final branch = pb.branchCode.toUpperCase();
    final businessTitle = pb.businessName.isNotEmpty ? pb.businessName.toUpperCase() : 'GANIMEDES';
    final initials = userName.isNotEmpty
        ? (userName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join())
        : 'OP';

    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderSoft : AppColors.lightBorderSoft,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderSoft : AppColors.lightBorderSoft,
              ),
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: AppColors.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Titles
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        businessTitle,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'POS',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sucursal $branch • $userName',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Theme Toggle Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderSoft : AppColors.lightBorderSoft,
              ),
            ),
            child: IconButton(
              tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
              padding: EdgeInsets.zero,
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
              onPressed: () {
                ThemeController.instance.toggleTheme();
              },
            ),
          ),
          const SizedBox(width: 8),
          // Operator Avatar / Menu
          PopupMenuButton<String>(
            tooltip: 'Opciones de Usuario',
            offset: const Offset(0, 48),
            onSelected: (val) {
              if (val == 'switch') {
                onSwitchOperator?.call();
              } else if (val == 'team') {
                TeamManagementModal.show(context);
              } else if (val == 'logout') {
                _onLogout(context);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(pb.userRole.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              if (pb.isAdmin)
                const PopupMenuItem(
                  value: 'team',
                  child: Row(
                    children: [
                      Icon(Icons.badge_rounded, size: 18, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Text('Equipo y Roles'),
                    ],
                  ),
                ),
              if (pb.canChangeOperator)
                const PopupMenuItem(
                  value: 'switch',
                  child: Row(
                    children: [
                      Icon(Icons.pin_rounded, size: 18, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Text('Cambiar Operador (PIN)'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

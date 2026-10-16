import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/device_breakpoints.dart';

class FloatingDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isAdmin;
  final bool canAccessInventory;
  final bool canViewReports;

  const FloatingDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.isAdmin = true,
    this.canAccessInventory = true,
    this.canViewReports = true,
  });

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = DeviceBreakpoints.isKeyboardOpen(context);
    final isCompact = DeviceBreakpoints.isLandscapeCompact(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnimatedSlide(
      offset: isKeyboardOpen ? const Offset(0, 1.5) : Offset.zero,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: isKeyboardOpen ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: isCompact ? 4 : (bottomInset > 0 ? bottomInset + 8 : 16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: isCompact ? 3 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.borderSoft),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 32,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (canViewReports)
                        _DockItem(
                          index: 0,
                          currentIndex: currentIndex,
                          icon: Icons.dashboard_rounded,
                          label: 'Inicio',
                          isCompact: isCompact,
                          onTap: () => onTabSelected(0),
                        ),
                      _DockItem(
                        index: 1,
                        currentIndex: currentIndex,
                        icon: Icons.point_of_sale_rounded,
                        label: 'POS',
                        isCompact: isCompact,
                        onTap: () => onTabSelected(1),
                      ),
                      if (canAccessInventory)
                        _DockItem(
                          index: 2,
                          currentIndex: currentIndex,
                          icon: Icons.inventory_2_rounded,
                          label: 'Inventario',
                          isCompact: isCompact,
                          onTap: () => onTabSelected(2),
                        ),
                      _DockItem(
                        index: 3,
                        currentIndex: currentIndex,
                        icon: Icons.payments_rounded,
                        label: 'Caja',
                        isCompact: isCompact,
                        onTap: () => onTabSelected(3),
                      ),
                      if (isAdmin)
                        _DockItem(
                          index: 4,
                          currentIndex: currentIndex,
                          icon: Icons.auto_awesome_rounded,
                          label: 'Copilot',
                          isAi: true,
                          isCompact: isCompact,
                          onTap: () => onTabSelected(4),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final bool isAi;
  final bool isCompact;
  final VoidCallback onTap;

  const _DockItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    this.isAi = false,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isCompact ? 18 : 22,
                color: isSelected
                    ? AppColors.secondary
                    : (isAi
                        ? AppColors.secondary.withValues(alpha: 0.7)
                        : AppColors.onSurfaceVariant),
              ),
              SizedBox(height: isCompact ? 1 : 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 9 : 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.secondary
                      : (isAi
                          ? AppColors.secondary.withValues(alpha: 0.7)
                          : AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

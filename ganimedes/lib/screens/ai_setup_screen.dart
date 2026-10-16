import 'dart:async';
import 'package:flutter/material.dart';

import '../services/pocketbase_service.dart';
import '../theme/app_colors.dart';
import 'main_shell.dart';

/// Pantalla slide (onboarding) que hace preguntas sencillas para
/// "alimentar" la IA del negocio. Navegación por botones, responsive.
class AiSetupScreen extends StatefulWidget {
  const AiSetupScreen({super.key});

  @override
  State<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends State<AiSetupScreen> {
  int _currentPage = 0;
  static const int _totalPages = 5;

  final TextEditingController _nameController = TextEditingController();
  String _businessType = 'barber';
  final TextEditingController _servicesController = TextEditingController();
  String _tone = 'profesional';
  final TextEditingController _instructionsController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final name = PocketBaseService().userName;
    if (name.isNotEmpty && name != 'Administrador') {
      _nameController.text = name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servicesController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    // Guardamos el perfil en segundo plano para no bloquear la entrada.
    unawaited(
      PocketBaseService().saveAiProfile(
        ownerName: _nameController.text.trim(),
        businessType: _businessType,
        servicesSummary: _servicesController.text.trim(),
        tone: _tone,
        specialInstructions: _instructionsController.text.trim(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _back,
              )
            : null,
        title: const Text(
          'Configura tu IA',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _skip,
            child: const Text('Saltar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _totalPages,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                ),
              ),
            ),
            Expanded(child: _buildSlide()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide() {
    switch (_currentPage) {
      case 0:
        return _Slide(
          icon: Icons.badge_rounded,
          title: '¿Cuál es tu nombre?',
          subtitle: 'Así te llamará tu asistente de IA.',
          child: TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              hintText: 'Ej. Carlos Mendoza',
            ),
          ),
        );
      case 1:
        return _Slide(
          icon: Icons.storefront_rounded,
          title: '¿Cuál es el giro de tu negocio?',
          subtitle: 'La IA usará esto para entender tu contexto.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OptionChip(
                label: 'Barbería',
                icon: Icons.content_cut_rounded,
                selected: _businessType == 'barber',
                onTap: () => setState(() => _businessType = 'barber'),
              ),
              _OptionChip(
                label: 'Comercio',
                icon: Icons.shopping_bag_outlined,
                selected: _businessType == 'retail',
                onTap: () => setState(() => _businessType = 'retail'),
              ),
              _OptionChip(
                label: 'Servicios',
                icon: Icons.handyman_outlined,
                selected: _businessType == 'services',
                onTap: () => setState(() => _businessType = 'services'),
              ),
            ],
          ),
        );
      case 2:
        return _Slide(
          icon: Icons.spa_rounded,
          title: '¿Qué servicios o productos ofreces?',
          subtitle: 'Ej. Cortes, barba, tintes, pomadas, bebidas…',
          child: TextField(
            controller: _servicesController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Describe brevemente tu catálogo…',
            ),
          ),
        );
      case 3:
        return _Slide(
          icon: Icons.record_voice_over_rounded,
          title: '¿Cómo quieres que te hable tu asistente?',
          subtitle: 'Así se comunicará la IA contigo.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OptionChip(
                label: 'Profesional',
                icon: Icons.business_center_rounded,
                selected: _tone == 'profesional',
                onTap: () => setState(() => _tone = 'profesional'),
              ),
              _OptionChip(
                label: 'Amigable',
                icon: Icons.sentiment_satisfied_rounded,
                selected: _tone == 'amigable',
                onTap: () => setState(() => _tone = 'amigable'),
              ),
              _OptionChip(
                label: 'Cercano',
                icon: Icons.emoji_people_rounded,
                selected: _tone == 'cercano',
                onTap: () => setState(() => _tone = 'cercano'),
              ),
              _OptionChip(
                label: 'Formal',
                icon: Icons.gavel_rounded,
                selected: _tone == 'formal',
                onTap: () => setState(() => _tone = 'formal'),
              ),
            ],
          ),
        );
      default:
        return _Slide(
          icon: Icons.auto_awesome_rounded,
          title: '¿Algo más que deba saber tu IA?',
          subtitle: 'Opcional. Ej. "Saluda como Mi rey", "Ofrece promos los viernes".',
          child: TextField(
            controller: _instructionsController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Escribe aquí tus reglas o preferencias…',
            ),
          ),
        );
    }
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final isLast = _currentPage == _totalPages - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          // Indicador de puntos (toma el espacio disponible)
          Expanded(
            child: Row(
              children: List.generate(_totalPages, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _currentPage ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.secondary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          if (_currentPage > 0) ...[
            TextButton(onPressed: _back, child: const Text('Atrás')),
            const SizedBox(width: 8),
          ],
          if (!isLast)
            FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Siguiente'),
            )
          else
            FilledButton.icon(
              onPressed: _saving ? null : _finish,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Comenzar'),
            ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondaryContainer : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.secondary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

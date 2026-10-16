import 'package:flutter/material.dart';

import '../../services/pocketbase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../ai_setup_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _adminNameController = TextEditingController();
  final _bizNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  String _selectedCategory = 'barber'; // 'barber', 'retail', 'services'
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _adminNameController.dispose();
    _bizNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    final name = _adminNameController.text.trim();
    final biz = _bizNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final pin = _pinController.text.trim();

    if (name.isEmpty) {
      _showError('Por favor ingresa tu nombre de administrador');
      return;
    }
    if (biz.isEmpty) {
      _showError('Por favor ingresa el nombre de tu negocio o barbería');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError('Por favor ingresa un correo electrónico válido');
      return;
    }
    if (password.length < 8) {
      _showError('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await PocketBaseService().signUp(
        name: name,
        email: email,
        password: password,
        businessName: biz,
        phone: phone,
        pin: pin.isNotEmpty ? pin : '1234',
        role: 'admin',
      );

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AiSetupScreen()));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Bienvenido $name! Tu cuenta ha sido registrada con éxito.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeController.instance.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Theme Toggle Icon
          IconButton(
            tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppColors.secondary,
            ),
            onPressed: () {
              setState(() {
                ThemeController.instance.toggleTheme();
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              // Logo & Stepper Indicator
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.secondary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: AppColors.secondary),
                    SizedBox(width: 6),
                    Text(
                      'ALTA DE NEGOCIO Y ADMINISTRADOR',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Crea tu Cuenta de Negocio',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tus datos se sincronizarán directamente en PocketBase.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Step 1: Owner and Store Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderSoft
                        : AppColors.lightBorderSoft,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Identidad del Propietario',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Admin name
                    Text(
                      'Nombre del Administrador *',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _adminNameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                        ),
                        hintText: 'Ej. Carlos Mendoza',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Store name
                    Text(
                      'Nombre del Negocio o Barbería *',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _bizNameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                        hintText: 'Ej. Barbería Don Juan',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Business Category Selector
                    Text(
                      'Giro de Negocio / Categoría',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _CategoryOption(
                          label: 'Barbería',
                          icon: Icons.content_cut_rounded,
                          isSelected: _selectedCategory == 'barber',
                          onTap: () =>
                              setState(() => _selectedCategory = 'barber'),
                        ),
                        const SizedBox(width: 8),
                        _CategoryOption(
                          label: 'Comercio',
                          icon: Icons.shopping_bag_outlined,
                          isSelected: _selectedCategory == 'retail',
                          onTap: () =>
                              setState(() => _selectedCategory = 'retail'),
                        ),
                        const SizedBox(width: 8),
                        _CategoryOption(
                          label: 'Servicios',
                          icon: Icons.handyman_outlined,
                          isSelected: _selectedCategory == 'services',
                          onTap: () =>
                              setState(() => _selectedCategory = 'services'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Step 2: Contact and Credentials Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderSoft
                        : AppColors.lightBorderSoft,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Credenciales y Seguridad',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email
                    Text(
                      'Correo Electrónico *',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          size: 20,
                        ),
                        hintText: 'admin@tunegocio.com',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone / WhatsApp
                    Text(
                      'Teléfono / WhatsApp',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Text(
                            '🇲🇽 +52',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        hintText: '55 1234 5678',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password
                    Text(
                      'Contraseña (mínimo 8 caracteres) *',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                        ),
                        hintText: '••••••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick PIN (4 digits)
                    Text(
                      'PIN de Acceso Rápido para Caja (4 dígitos)',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.pin_rounded, size: 20),
                        hintText: '1234',
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _onSignUp,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isLoading
                      ? 'Creando cuenta...'
                      : 'Crear Cuenta y Entrar al POS',
                ),
              ),
              const SizedBox(height: 16),

              // Back to Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿Ya tienes cuenta? ',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _CategoryOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.secondary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

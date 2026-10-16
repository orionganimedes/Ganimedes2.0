import 'dart:async';
import 'package:flutter/material.dart';
import '../services/pocketbase_service.dart';
import '../theme/app_colors.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _statusText = 'Verificando sesión activa y sucursal...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    PocketBaseService().autoDiscoverServer();
    _startLoadingSequence();
  }

  void _startLoadingSequence() {
    const totalSteps = 40;
    int currentStep = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep++;
      final percent = currentStep / totalSteps;

      setState(() {
        _progress = percent.clamp(0.0, 1.0);
        if (_progress < 0.30) {
          _statusText = 'Verificando sesión activa y sucursal...';
        } else if (_progress < 0.65) {
          _statusText = 'Sincronizando catálogo con PocketBase...';
        } else if (_progress < 0.90) {
          _statusText = 'Cargando inventario y listas de precios...';
        } else {
          _statusText = 'Preparando interfaz de alta velocidad...';
        }
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            _navigateToLogin();
          }
        });
      }
    });
  }

  void _navigateToLogin() {
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GestureDetector(
        onTap: _navigateToLogin, // Tap to skip directly to login
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Ambient neon background glows
            Positioned(
              top: -80,
              left: -40,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: isDark ? 0.08 : 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: isDark ? 0.12 : 0.06),
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Top Status Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: AppColors.secondary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'POCKETBASE SYNC',
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 12,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'TLS 1.3 CIFRADO',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Center Brand & Loading Centerpiece
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo Card with Cyber Elevation
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.point_of_sale_rounded,
                              size: 54,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'GANIMEDES',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 1,
                              color: AppColors.secondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ECOSISTEMA DE NEGOCIOS',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 20,
                              height: 1,
                              color: AppColors.secondary.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // Progress Bar Container
                        Container(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _progress,
                                  minHeight: 6,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _statusText,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${(_progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom Terminal Info & Version
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.borderSoft,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.storefront_rounded,
                                      size: 16,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SISTEMA',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Terminal Activa',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.borderSoft,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.point_of_sale_rounded,
                                      size: 16,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TERMINAL',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'POS #01 Activo',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Build 2024.11 • Flutter Engine',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                            const Text(
                              'v2.4.0',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

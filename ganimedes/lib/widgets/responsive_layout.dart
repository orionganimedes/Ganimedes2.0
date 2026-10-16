import 'package:flutter/material.dart';
import '../utils/device_breakpoints.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
);

class ResponsiveLayout extends StatelessWidget {
  final ResponsiveWidgetBuilder mobile;
  final ResponsiveWidgetBuilder? tablet;
  final ResponsiveWidgetBuilder? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= DeviceBreakpoints.tabletMax && desktop != null) {
          return desktop!(context, constraints);
        }
        if (w >= DeviceBreakpoints.mobileMax && tablet != null) {
          return tablet!(context, constraints);
        }
        return mobile(context, constraints);
      },
    );
  }
}

/// Contenedor que restringe el ancho en pantallas grandes para evitar estiramientos antiestéticos
class CenteredAdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const CenteredAdaptiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

class DeviceBreakpoints {
  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  static DeviceType getDeviceType(BuildContext context) {
    final w = width(context);
    if (w < mobileMax) return DeviceType.mobile;
    if (w < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) => width(context) < mobileMax;
  static bool isTablet(BuildContext context) {
    final w = width(context);
    return w >= mobileMax && w < tabletMax;
  }
  static bool isDesktop(BuildContext context) => width(context) >= tabletMax;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool isLandscapeCompact(BuildContext context) =>
      isLandscape(context) && height(context) < 520;

  /// Detecta si el teclado virtual está desplegado en pantalla
  static bool isKeyboardOpen(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0;

  /// Retorna el número óptimo de columnas para el catálogo POS según ancho
  static int getPosColumnCount(BuildContext context) {
    final w = width(context);
    if (w < 600) return 2;
    if (w < 840) return 3;
    if (w < 1200) return 4;
    if (w < 1600) return 5;
    return 6;
  }

  /// Retorna el aspect ratio óptimo para las tarjetas del POS
  static double getPosAspectRatio(BuildContext context) {
    final w = width(context);
    final h = height(context);
    if (isLandscape(context) && h < 520) {
      return 1.05;
    }
    if (w >= 1024) {
      return 0.95;
    }
    return 0.88;
  }
}

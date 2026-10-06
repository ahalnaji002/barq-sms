import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFFB300);

  static Color background(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color card(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color text(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color subtitle(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }

  static Color shadow(BuildContext context) {
    return Theme.of(context).shadowColor.withValues(alpha: 0.10);
  }
}

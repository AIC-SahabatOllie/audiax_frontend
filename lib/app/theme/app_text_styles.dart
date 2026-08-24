import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text styles for the AUDIAX visual language.
///
/// The mockup pairs Plus Jakarta Sans (UI text) with IBM Plex Mono
/// (data/metrics — z-scores, timestamps, eyebrow labels). To keep the app
/// fully usable offline (no runtime font download), we use the platform
/// default font for UI text and the generic `monospace` family — matched on
/// weight/letter-spacing/size — for the "instrument reading" data displays.
class AppTextStyles {
  AppTextStyles._();

  static const String monoFamily = 'monospace';

  static const TextStyle eyebrow = TextStyle(
    fontFamily: monoFamily,
    fontSize: 9.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: AppColors.textMuted,
  );

  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: AppColors.ink,
    height: 1.15,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double letterSpacing = -0.4,
  }) {
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}

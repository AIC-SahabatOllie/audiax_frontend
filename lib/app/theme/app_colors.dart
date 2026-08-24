import 'package:flutter/material.dart';

/// Color tokens for the AUDIAX visual language (dashboard/detail/calibration
/// screens) — see docs/design.md and the AUDIAX brand palette (teal/slate
/// primaries, semantic red/amber/green for machine status).
class AppColors {
  AppColors._();

  static const Color pageBackground = Color(0xFFE2E8F0);
  static const Color screenBackground = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dashedBorder = Color(0xFFCBD5E1);

  static const Color ink = Color(0xFF0F172A);
  static const Color inkSoft = Color(0xFF334155);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textFaint = Color(0xFF94A3B8);

  /// Brand identity — distinct from [ok] on purpose: brand is "this is
  /// AUDIAX" (buttons, focus rings, recording UI); ok is "this machine
  /// reads normal" (status badges/chips). They used to be the same green;
  /// the brand palette now separates identity teal from status green.
  static const Color brand = Color(0xFF0D9488);
  static const Color brandBright = Color(0xFF14B8A6);
  static const Color brandAccent = Color(0xFF5EEAD4);
  static const Color brandTint = Color(0xFFF0FDFA);

  static const Color ok = Color(0xFF22C55E);
  static const Color okDeep = Color(0xFF15803D);
  static const Color okTint = Color(0xFFF0FDF4);
  static const Color okChip = Color(0x2922C55E);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDeep = Color(0xFFB45309);
  static const Color warningTint = Color(0xFFFFFBEB);
  static const Color warningChip = Color(0x29F59E0B);

  static const Color critical = Color(0xFFEF4444);
  static const Color criticalDeep = Color(0xFFB91C1C);
  static const Color criticalTint = Color(0xFFFEF2F2);
  static const Color criticalChip = Color(0x29EF4444);

  /// "Not inspected yet" — deliberately outside the normal/warning/critical
  /// scale: a machine with no inspection is unknown, not healthy, so it must
  /// never borrow [ok] green on the dashboard.
  static const Color neutral = Color(0xFF94A3B8);
  static const Color neutralDeep = Color(0xFF475569);
  static const Color neutralTint = Color(0xFFF8FAFC);
  static const Color neutralChip = Color(0x1F64748B);

  static const Color dark = Color(0xFF0F172A);
  static const Color darkOverlay = Color(0x1AFFFFFF);

  /// Home hero header — Deep Navy → Ocean Teal, per design.md §1.1
  /// ("Deep Navy … hero gradients", "Ocean Teal … gradient partner").
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF0D9488)],
  );

  /// Filled primary tiles/CTAs — Bright Teal → Ocean Teal, per design.md §4
  /// (`QuickActionTile` primary, `PrimaryCTAButton`).
  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
  );
}

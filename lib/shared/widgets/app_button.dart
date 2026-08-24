import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

/// Full-width rounded action button used across calibration/inspection/result
/// flows (`AppButton`, per project_structure.md naming convention for shared
/// widgets that need a prefix to avoid clashing with Flutter's own Button).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.enabled = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool enabled;

  /// Shows a spinner in place of the label and blocks taps, without the
  /// dimmed look of [enabled]: false — used while an async submit is
  /// in flight so the button stays visually "active".
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (variant) {
      AppButtonVariant.primary => (AppColors.brand, Colors.white),
      AppButtonVariant.secondary => (AppColors.surfaceMuted, AppColors.ink),
      AppButtonVariant.ghost => (AppColors.surface, AppColors.inkSoft),
      AppButtonVariant.danger => (AppColors.critical, Colors.white),
    };
    final canTap = enabled && !loading;

    return Opacity(
      opacity: canTap || loading ? 1 : 0.5,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: canTap ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

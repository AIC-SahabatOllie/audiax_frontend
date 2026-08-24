import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// Renders an inspection's `dominant_indicator` + `reason`
/// (`docs/api_contract.md` §6) — the API gives a single indicator name and
/// an explanatory sentence, not a ranked list with numeric before/after
/// values, so this stays honest to that shape instead of fabricating one.
/// Used by both `MachineDetailScreen` and `ResultScreen`.
class IndicatorInsightCard extends StatelessWidget {
  const IndicatorInsightCard({super.key, this.dominantIndicator, this.reason});

  final String? dominantIndicator;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    if (dominantIndicator == null && reason == null) {
      return const Text(
        'Tidak ada indikator dominan — sesuai baseline.',
        style: TextStyle(fontSize: 13, height: 1.55, color: AppColors.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dominantIndicator != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(8)),
            child: Text(dominantIndicator!, style: AppTextStyles.mono(size: 11.5, color: AppColors.warningDeep)),
          ),
        if (dominantIndicator != null && reason != null) const SizedBox(height: 10),
        if (reason != null)
          Text(reason!, style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.ink)),
      ],
    );
  }
}

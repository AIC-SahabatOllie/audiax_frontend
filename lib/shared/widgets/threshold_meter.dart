import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../models/machine_status.dart';

/// Horizontal 0→8 z-score meter with tick marks at the WARNING (3,0) and
/// CRITICAL (6,0) thresholds — a fixed visual constant reused on the
/// dashboard, detail, and result screens (docs/design.md §1.4/§5).
class ThresholdMeter extends StatelessWidget {
  const ThresholdMeter({
    super.key,
    required this.value,
    required this.color,
    this.trackColor,
    this.height = 6,
  });

  final double value;
  final Color color;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pct = (value / MachineStatusLabel.scaleMax).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: height + 6,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: trackColor ?? AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              _tick(constraints.maxWidth, 0.375),
              _tick(constraints.maxWidth, 0.75),
            ],
          ),
        );
      },
    );
  }

  Widget _tick(double width, double fraction) {
    return Positioned(
      left: (width * fraction).clamp(0, width) - 0.5,
      child: Container(
        width: 1,
        height: height + 6,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../models/machine_status.dart';

/// Maps a [MachineStatus] to its color/tint/chip presentation, kept in one
/// place so status always reads as color + tint + label together (never
/// color alone), per docs/design.md §1.3.
class StatusStyle {
  final Color color;
  final Color deep;
  final Color tint;
  final Color chip;

  const StatusStyle({
    required this.color,
    required this.deep,
    required this.tint,
    required this.chip,
  });

  factory StatusStyle.of(MachineStatus status) {
    return switch (status) {
      MachineStatus.critical => const StatusStyle(
        color: AppColors.critical,
        deep: AppColors.criticalDeep,
        tint: AppColors.criticalTint,
        chip: AppColors.criticalChip,
      ),
      MachineStatus.warning => const StatusStyle(
        color: AppColors.warning,
        deep: AppColors.warningDeep,
        tint: AppColors.warningTint,
        chip: AppColors.warningChip,
      ),
      MachineStatus.normal => const StatusStyle(
        color: AppColors.ok,
        deep: AppColors.okDeep,
        tint: AppColors.okTint,
        chip: AppColors.okChip,
      ),
    };
  }
}

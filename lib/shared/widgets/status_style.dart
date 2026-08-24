import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../models/machine_status.dart';

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
static const StatusStyle unknown = StatusStyle(
    color: AppColors.neutral,
    deep: AppColors.neutralDeep,
    tint: AppColors.neutralTint,
    chip: AppColors.neutralChip,
  );

  /// [status] presentation, or [unknown] when [inspected] is false.
  static StatusStyle forMachine(MachineStatus status, {required bool inspected}) =>
      inspected ? StatusStyle.of(status) : unknown;

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

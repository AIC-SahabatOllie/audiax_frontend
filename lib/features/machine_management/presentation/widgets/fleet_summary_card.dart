import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/machine.dart';
import '../../../../shared/models/machine_status.dart';

/// The dashboard's one-glance rollup of the fleet: how many machines read
/// normal, how many need action, how many have never been inspected.
class FleetSnapshot {
  FleetSnapshot._({
    required this.total,
    required this.normal,
    required this.warning,
    required this.critical,
    required this.unchecked,
    required this.lastInspectedAt,
  });

  factory FleetSnapshot.of(List<Machine> machines) {
    var normal = 0, warning = 0, critical = 0, unchecked = 0;
    DateTime? lastInspectedAt;

    for (final machine in machines) {
      if (!machine.inspected) {
        unchecked++;
      } else {
        switch (machine.status) {
          case MachineStatus.critical:
            critical++;
          case MachineStatus.warning:
            warning++;
          case MachineStatus.normal:
            normal++;
        }
      }

      final at = machine.lastInspectedAt;
      if (at != null &&
          (lastInspectedAt == null || at.isAfter(lastInspectedAt))) {
        lastInspectedAt = at;
      }
    }

    return FleetSnapshot._(
      total: machines.length,
      normal: normal,
      warning: warning,
      critical: critical,
      unchecked: unchecked,
      lastInspectedAt: lastInspectedAt,
    );
  }

  final int total;
  final int normal;
  final int warning;
  final int critical;
  final int unchecked;
  final DateTime? lastInspectedAt;

  int get needsAttention => warning + critical;

  String get lastCheckLabel {
    final at = lastInspectedAt;
    if (at == null) return 'Belum ada pemeriksaan';
    return 'Pemeriksaan terakhir ${DateFormatter.relative(at)}';
  }
}

/// Fleet rollup card sitting directly under the dashboard greeting.
class FleetSummaryCard extends StatelessWidget {
  const FleetSummaryCard({super.key, required this.snapshot});

  final FleetSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('KONDISI ARMADA', style: AppTextStyles.eyebrow),
              const SizedBox(width: 12),
              // Expanded, not Spacer + Flexible: the label needs whatever the
              // eyebrow leaves over, not half of it.
              Expanded(
                child: Text(
                  snapshot.lastCheckLabel,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'NORMAL',
                  value: snapshot.normal,
                  color: AppColors.ok,
                  deep: AppColors.okDeep,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'PERLU TINDAKAN',
                  value: snapshot.needsAttention,
                  color: AppColors.warning,
                  deep: AppColors.warningDeep,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'BELUM DICEK',
                  value: snapshot.unchecked,
                  color: AppColors.neutral,
                  deep: AppColors.neutralDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    required this.deep,
  });

  final String label;
  final int value;
  final Color color;
  final Color deep;

  @override
  Widget build(BuildContext context) {
    // A zero count is drained of color: only the numbers that mean something
    // right now should catch the eye.
    final muted = value == 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: muted ? AppColors.divider : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$value',
              style: AppTextStyles.mono(
                size: 18,
                weight: FontWeight.w700,
                color: muted ? AppColors.textFaint : deep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.mono(
            size: 8,
            color: AppColors.textFaint,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

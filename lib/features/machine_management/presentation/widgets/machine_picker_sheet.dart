import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/models/machine.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/status_style.dart';


Future<Machine?> showMachinePickerSheet(
  BuildContext context, {
  required List<Machine> machines,
}) {
  return showModalBottomSheet<Machine>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) => _MachinePickerSheet(machines: machines),
  );
}

class _MachinePickerSheet extends StatelessWidget {
  const _MachinePickerSheet({required this.machines});

  final List<Machine> machines;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PERIKSA · 10 DETIK', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 7),
                  const Text('Mesin mana yang diperiksa?', style: AppTextStyles.heading),
                  const SizedBox(height: 5),
                  Text(
                    'Diurutkan dari yang paling perlu pemeriksaan.',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                itemCount: machines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _PickerRow(
                  machine: machines[index],
                  onTap: () => Navigator.of(context).pop(machines[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.machine, required this.onTap});

  final Machine machine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.forMachine(
      machine.status,
      inspected: machine.inspected,
    );
    return Material(
      color: AppColors.screenBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 38,
                decoration: BoxDecoration(
                  color: style.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading.copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      machine.calibrated
                          ? '${machine.line} · ${machine.lastCheckedRelativeLabel.toLowerCase()}'
                          : '${machine.line} · belum dikalibrasi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (machine.inspected)
                StatusBadge(status: machine.status)
              else
                const StatusBadge.unknown(),
            ],
          ),
        ),
      ),
    );
  }
}

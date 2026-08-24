import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../shared/models/machine.dart';
import '../../../../shared/models/machine_status.dart';
import '../../../../shared/services/machine_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/status_style.dart';
import '../../../../shared/widgets/threshold_meter.dart';

enum _CardMode { none, menu, renaming, confirmingDelete }

class MachineCard extends StatefulWidget {
  const MachineCard({
    super.key,
    required this.machine,
    required this.repository,
    required this.onOpenDetail,
    required this.onCheck,
    required this.onRecalibrate,
  });

  final Machine machine;
  final MachineRepository repository;
  final VoidCallback onOpenDetail;
  final VoidCallback onCheck;
  final ValueChanged<Machine> onRecalibrate;

  @override
  State<MachineCard> createState() => _MachineCardState();
}

class _MachineCardState extends State<MachineCard> {
  _CardMode _mode = _CardMode.none;
  late final TextEditingController _nameController;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.machine.name);
  }

  @override
  void didUpdateWidget(covariant MachineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.machine.name != widget.machine.name &&
        _mode != _CardMode.renaming) {
      _nameController.text = widget.machine.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setMode(_CardMode mode) => setState(() {
    _mode = mode;
    _error = null;
  });

  Future<void> _submitRename() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.rename(widget.machine.id, _nameController.text);
      if (!mounted) return;
      _setMode(_CardMode.none);
    } on ApiException catch (e) {
      setState(
        () => _error = e.isConflict
            ? 'Nama mesin ini sudah dipakai.'
            : e.displayMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitDelete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.remove(widget.machine.id);
    } on ApiException catch (e) {
      setState(() => _error = e.displayMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final machine = widget.machine;
    final style = StatusStyle.forMachine(
      machine.status,
      inspected: machine.inspected,
    );
    final expanded = _mode != _CardMode.none;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: expanded ? style.color.withValues(alpha: 0.35) : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: expanded ? 0.1 : 0.05),
            blurRadius: expanded ? 22 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      // Stack rather than a stretched Row: the status spine has to span the
      // card's full height, and the card's own height comes from content that
      // measures itself with LayoutBuilder (the threshold meter), which
      // cannot report intrinsic dimensions to an IntrinsicHeight row.
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [style.color, style.deep],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onOpenDetail,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIdentityRow(machine, style),
                    const SizedBox(height: 13),
                    _buildStatusRow(machine),
                    if (machine.inspected) ...[
                      const SizedBox(height: 13),
                      _ZScoreScale(value: machine.zScore, color: style.color),
                    ],
                    const SizedBox(height: 14),
                    _buildActionRow(machine),
                    if (_mode == _CardMode.menu) _buildMenu(),
                    if (_mode == _CardMode.renaming) _buildRenameForm(),
                    if (_mode == _CardMode.confirmingDelete)
                      _buildDeleteConfirm(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityRow(Machine machine, StatusStyle style) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WaveTile(style: style),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                machine.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading.copyWith(fontSize: 16.5),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 12,
                    color: AppColors.textFaint,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      machine.line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                machine.lastCheckedRelativeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              machine.inspected
                  ? machine.zScore.toStringAsFixed(1).replaceAll('.', ',')
                  : '—',
              style: AppTextStyles.mono(
                size: 26,
                color: machine.inspected ? AppColors.ink : AppColors.textFaint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SKOR-Z',
              style: AppTextStyles.mono(
                size: 8,
                color: AppColors.textFaint,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusRow(Machine machine) {
    final calibColor = machine.calibrated
        ? AppColors.okDeep
        : AppColors.warningDeep;
    return Row(
      children: [
        if (machine.inspected)
          StatusBadge(
            status: machine.status,
            pulse: machine.status == MachineStatus.critical,
          )
        else
          const StatusBadge.unknown(),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: calibColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  machine.calibrationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(
                    size: 9.5,
                    color: calibColor,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(Machine machine) {

    final needsCalibration = !machine.calibrated;
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: needsCalibration ? 'Kalibrasi' : 'Periksa',
            onPressed: needsCalibration
                ? () => widget.onRecalibrate(machine)
                : widget.onCheck,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppButton(
            label: 'Detail',
            variant: AppButtonVariant.secondary,
            onPressed: widget.onOpenDetail,
          ),
        ),
        const SizedBox(width: 8),
        _MenuTrigger(
          open: _mode == _CardMode.menu,
          onTap: () => _setMode(
            _mode == _CardMode.menu ? _CardMode.none : _CardMode.menu,
          ),
        ),
      ],
    );
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: AppColors.screenBackground,
          child: Column(
            children: [
              _menuRow(
                Icons.drive_file_rename_outline_rounded,
                'Ganti nama mesin',
                AppColors.ink,
                () => _setMode(_CardMode.renaming),
              ),
              _menuRow(Icons.tune_rounded, 'Kalibrasi ulang', AppColors.ink, () {
                _setMode(_CardMode.none);
                widget.onRecalibrate(widget.machine);
              }),
              _menuRow(
                Icons.delete_outline_rounded,
                'Hapus mesin',
                AppColors.critical,
                () => _setMode(_CardMode.confirmingDelete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuRow(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 11),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenameForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.screenBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GANTI NAMA MESIN',
              style: AppTextStyles.mono(
                size: 9,
                color: AppColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _nameController,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                errorText: _error,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Simpan',
                    loading: _busy,
                    onPressed: _submitRename,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Batal',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      _nameController.text = widget.machine.name;
                      _setMode(_CardMode.none);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteConfirm() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.criticalTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.critical.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hapus ${widget.machine.name} beserta baseline-nya?',
              style: const TextStyle(
                fontSize: 13,
                height: 1.55,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.criticalDeep,
                ),
              ),
            ],
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Hapus',
                    variant: AppButtonVariant.danger,
                    loading: _busy,
                    onPressed: _submitDelete,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Batal',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => _setMode(_CardMode.none),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveTile extends StatelessWidget {
  const _WaveTile({required this.style});

  final StatusStyle style;

  static const _heights = [9.0, 16.0, 12.0, 19.0, 10.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: style.color.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < _heights.length; i++) ...[
              if (i > 0) const SizedBox(width: 2.5),
              Container(
                width: 3,
                height: _heights[i],
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: i.isEven ? 0.55 : 1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZScoreScale extends StatelessWidget {
  const _ZScoreScale({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.mono(
      size: 8,
      color: AppColors.textFaint,
      letterSpacing: 0.6,
    );
    return Column(
      children: [
        ThresholdMeter(value: value, color: color, trackColor: AppColors.surfaceMuted),
        const SizedBox(height: 5),
        SizedBox(
          height: 11,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  Positioned(left: 0, child: Text('0', style: labelStyle)),
                  Positioned(
                    left: width * MachineStatusLabel.warningThreshold /
                            MachineStatusLabel.scaleMax -
                        8,
                    child: Text('3,0', style: labelStyle),
                  ),
                  Positioned(
                    left: width * MachineStatusLabel.criticalThreshold /
                            MachineStatusLabel.scaleMax -
                        8,
                    child: Text('6,0', style: labelStyle),
                  ),
                  Positioned(right: 0, child: Text('8', style: labelStyle)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuTrigger extends StatelessWidget {
  const _MenuTrigger({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: open ? AppColors.ink : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          child: AnimatedRotation(
            turns: open ? 0.25 : 0,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              Icons.more_horiz_rounded,
              size: 20,
              color: open ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

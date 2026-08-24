import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../shared/models/machine.dart';
import '../../../../shared/services/machine_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/status_style.dart';

enum _CardMode { none, menu, renaming, confirmingDelete }

/// One machine row on the dashboard: status, z-score, and the
/// Periksa/Detail/⋯ action row with an inline action sheet for
/// rename/recalibrate/delete (docs/design.md "InlineActionSheet").
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
    final style = StatusStyle.of(machine.status);
    final calibColor = machine.calibrated
        ? AppColors.okDeep
        : AppColors.warningDeep;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: style.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: style.tint,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _bar(style.color, 8, 0.55),
                                const SizedBox(width: 2),
                                _bar(style.color, 15, 1),
                                const SizedBox(width: 2),
                                _bar(style.color, 11, 0.75),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                machine.name,
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 16.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(machine.meta, style: AppTextStyles.caption),
                              const SizedBox(height: 6),
                              StatusBadge(status: machine.status),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              machine.zScore
                                  .toStringAsFixed(1)
                                  .replaceAll('.', ','),
                              style: AppTextStyles.mono(
                                size: 26,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
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
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: calibColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          machine.calibrationLabel,
                          style: AppTextStyles.mono(
                            size: 10,
                            color: calibColor,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Periksa',
                            onPressed: widget.onCheck,
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
                            _mode == _CardMode.menu
                                ? _CardMode.none
                                : _CardMode.menu,
                          ),
                        ),
                      ],
                    ),
                    if (_mode == _CardMode.menu) _buildMenu(),
                    if (_mode == _CardMode.renaming) _buildRenameForm(),
                    if (_mode == _CardMode.confirmingDelete)
                      _buildDeleteConfirm(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(Color color, double height, double opacity) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(1),
      ),
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
                'Ganti nama mesin',
                AppColors.ink,
                () => _setMode(_CardMode.renaming),
              ),
              _menuRow('Kalibrasi ulang', AppColors.ink, () {
                _setMode(_CardMode.none);
                widget.onRecalibrate(widget.machine);
              }),
              _menuRow(
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

  Widget _menuRow(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
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
                    label: _busy ? 'Menyimpan…' : 'Simpan',
                    enabled: !_busy,
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
                    label: _busy ? 'Menghapus…' : 'Hapus',
                    variant: AppButtonVariant.danger,
                    enabled: !_busy,
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

class _MenuTrigger extends StatelessWidget {
  const _MenuTrigger({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: open ? AppColors.divider : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 20,
            color: AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

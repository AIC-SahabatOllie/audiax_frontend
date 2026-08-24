import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/calibration_draft.dart';
import '../../../../shared/models/machine.dart';
import '../../../../shared/models/recording_mode.dart';
import '../../../../shared/services/machine_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import 'recording_screen.dart';

/// Confirmation screen shown right before recording starts, for both the
/// 120s calibration and 10s daily-check flows (docs/design.md
/// "RecordingRing" lead-in).
class ReadyScreen extends StatelessWidget {
  const ReadyScreen({
    super.key,
    required this.repository,
    required this.mode,
    this.machine,
    this.draft,
  }) : assert(
         (mode == RecordingMode.inspect && machine != null) ||
             (mode == RecordingMode.calibrate && draft != null),
       );

  final MachineRepository repository;
  final RecordingMode mode;
  final Machine? machine;
  final CalibrationDraft? draft;

  bool get _isCalibration => mode == RecordingMode.calibrate;

  @override
  Widget build(BuildContext context) {
    final title = _isCalibration
        ? 'Siap mengkalibrasi ${draft!.name}'
        : 'Siap memeriksa ${machine!.name}';
    final hint = _isCalibration
        ? 'Pastikan blower berjalan normal dan ponsel diam di posisinya sebelum mulai.'
        : 'Arahkan mikrofon ke blower. Rekaman berlangsung ${mode.durationLabel} tanpa suara lain di sekitar.';

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _ReadyIcon(),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, height: 1.65, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Mulai · ${mode.durationLabel}',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecordingScreen(
                      repository: repository,
                      mode: mode,
                      machine: machine,
                      draft: draft,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Batal',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyIcon extends StatelessWidget {
  const _ReadyIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(44)),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(22, AppColors.inkSoft.withValues(alpha: 0.4)),
            _bar(44, AppColors.brandAccent),
            _bar(32, AppColors.ok),
            _bar(58, Colors.white),
            _bar(28, AppColors.ok),
            _bar(16, AppColors.inkSoft.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Container(
        width: 6,
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
    );
  }
}

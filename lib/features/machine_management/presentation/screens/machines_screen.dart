import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/machine.dart';
import '../../../../shared/models/machine_status.dart';
import '../../../../shared/models/recording_mode.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/services/machine_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/brand_mark.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../calibration/presentation/screens/calibration_form_screen.dart';
import '../../../daily_check/presentation/screens/ready_screen.dart';
import '../widgets/fleet_summary_card.dart';
import '../widgets/machine_card.dart';
import '../widgets/machine_card_skeleton.dart';
import '../widgets/machine_picker_sheet.dart';
import 'machine_detail_screen.dart';

/// "Mesin" dashboard — the app's home screen (docs/design.md §3.1). The MVP
/// build keeps it to four blocks: greeting, fleet rollup, one primary action
/// ("Periksa"), and the machine list — backed by `GET /api/machines`
/// (`docs/api_contract.md` §4) via [MachineRepository] (PRD §6A.1 #1).
class MachinesScreen extends StatefulWidget {
  const MachinesScreen({
    super.key,
    required this.repository,
    required this.user,
    required this.authRepository,
    required this.onLoggedOut,
  });

  final MachineRepository repository;
  final User user;
  final AuthRepository authRepository;
  final VoidCallback onLoggedOut;

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  /// Priority order for the list: the worst reading first, with
  /// never-inspected machines ranked *above* healthy ones — an unknown
  /// machine is a pending task, a normal one is not. Replaces the filter/sort
  /// controls: with one sensible order there is nothing left to choose.
  static int _priorityRank(Machine machine) {
    if (!machine.inspected) return 2;
    return switch (machine.status) {
      MachineStatus.critical => 0,
      MachineStatus.warning => 1,
      MachineStatus.normal => 3,
    };
  }

  List<Machine> _sorted(List<Machine> machines) {
    return [...machines]..sort((a, b) {
      final rank = _priorityRank(a).compareTo(_priorityRank(b));
      if (rank != 0) return rank;
      return b.zScore.compareTo(a.zScore);
    });
  }

  // ---------------------------------------------------------------- navigation

  void _openCalibration({Machine? existingMachine}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalibrationFormScreen(
          repository: widget.repository,
          existingMachine: existingMachine,
        ),
      ),
    );
  }

  void _openDetail(String machineId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MachineDetailScreen(
          repository: widget.repository,
          machineId: machineId,
        ),
      ),
    );
  }

  void _startInspection(Machine machine) {
    // Without a baseline there is nothing to compare a recording against, so
    // route to calibration instead of a check the backend would reject.
    if (!machine.calibrated) {
      _openCalibration(existingMachine: machine);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadyScreen(
          repository: widget.repository,
          mode: RecordingMode.inspect,
          machine: machine,
        ),
      ),
    );
  }

  /// The screen's single primary action: one machine goes straight into the
  /// check, several open the picker (already ordered worst-first).
  Future<void> _quickInspect(List<Machine> machines) async {
    if (machines.isEmpty) {
      _openCalibration();
      return;
    }
    if (machines.length == 1) {
      _startInspection(machines.first);
      return;
    }
    final picked = await showMachinePickerSheet(context, machines: machines);
    if (picked != null && mounted) _startInspection(picked);
  }

  Future<void> _logout() async {
    Navigator.of(context).pop();
    await widget.authRepository.logout();
    widget.onLoggedOut();
  }

  void _openAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 22),
              Row(
                children: [
                  _Avatar(initials: widget.user.initials),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Keluar',
                variant: AppButtonVariant.danger,
                onPressed: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, _) {
          final machines = widget.repository.machines;

          if (widget.repository.isLoading && machines.isEmpty) {
            return const _LoadingState();
          }
          if (widget.repository.error != null && machines.isEmpty) {
            return _ErrorState(
              message: widget.repository.error!,
              onRetry: widget.repository.load,
            );
          }

          final snapshot = FleetSnapshot.of(machines);
          final ordered = _sorted(machines);

          return SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.brand,
              onRefresh: widget.repository.load,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Header(
                    user: widget.user,
                    alert: snapshot.critical > 0,
                    onAvatarTap: _openAccountSheet,
                  ),
                  // The rollup is meaningless before the first machine
                  // exists — the empty state does the talking instead.
                  if (machines.isEmpty)
                    _EmptyFleetState(onTap: () => _openCalibration())
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: FleetSummaryCard(snapshot: snapshot),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                      child: Column(
                        children: [
                          _AddMachineButton(
                            onTap: () => _openCalibration(),
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            label: 'Periksa mesin · 10 detik',
                            onPressed: () => _quickInspect(ordered),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 26, 18, 14),
                      child: Row(
                        children: [
                          const Text(
                            'Mesin terhubung',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(width: 9),
                          _CountBubble(count: machines.length),
                        ],
                      ),
                    ),
                    for (final machine in ordered)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        child: MachineCard(
                          key: ValueKey(machine.id),
                          machine: machine,
                          repository: widget.repository,
                          onOpenDetail: () => _openDetail(machine.id),
                          onCheck: () => _startInspection(machine),
                          onRecalibrate: (m) =>
                              _openCalibration(existingMachine: m),
                        ),
                      ),
                  ],
                  const _DisclaimerFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Greeting block. Flat on the page background rather than a gradient hero:
/// the summary card below it is what the eye should land on first.
class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.alert,
    required this.onAvatarTap,
  });

  final User user;
  final bool alert;
  final VoidCallback onAvatarTap;

  static String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(size: 24),
              const SizedBox(width: 8),
              Text(
                'AUDIAX',
                style: AppTextStyles.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              _Avatar(
                initials: user.initials,
                onTap: onAvatarTap,
                alert: alert,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '$_greeting, ${user.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pemantauan kondisi mesin',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: 8),
          Text(
            DateFormatter.longDate(DateTime.now()).toUpperCase(),
            style: AppTextStyles.mono(
              size: 9.5,
              color: AppColors.textFaint,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.onTap, this.alert = false});

  final String initials;
  final VoidCallback? onTap;

  /// Red dot when the fleet has a critical machine — the account sheet is
  /// also where the user lands after acting on an alert.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: AppColors.actionGradient,
              shape: BoxShape.circle,
            ),
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (alert)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.critical,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.screenBackground,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.mono(
          size: 11,
          weight: FontWeight.w700,
          color: AppColors.brand,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Secondary CTA above the primary "Periksa" button: white-on-page rather
/// than filled, so it reads as the calmer of the two actions.
class _AddMachineButton extends StatelessWidget {
  const _AddMachineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 19, color: AppColors.brand),
              SizedBox(width: 8),
              Text(
                'Tambah mesin',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 11),
              Text('MEMUAT ARMADA', style: AppTextStyles.eyebrow),
            ],
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < 3; i++) ...[
            const MachineCardSkeleton(),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.criticalTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 27,
                  color: AppColors.critical,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Gagal memuat armada',
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 200,
                child: AppButton(label: 'Coba lagi', onPressed: onRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the fleet list when the account has no machines yet —
/// steers straight into the calibration flow rather than a bare list.
class _EmptyFleetState extends StatelessWidget {
  const _EmptyFleetState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.16)),
            ),
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              size: 31,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Belum ada mesin terdaftar',
            style: AppTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Kalibrasi mesin pertama untuk mulai memantau kondisinya setiap hari.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: AppButton(label: '+ Kalibrasi mesin baru', onPressed: onTap),
          ),
          const SizedBox(height: 18),
          const _CalibrationSteps(),
        ],
      ),
    );
  }
}

/// What the first calibration actually involves — set expectations before the
/// user commits to a 120-second recording.
class _CalibrationSteps extends StatelessWidget {
  const _CalibrationSteps();

  static const _steps = [
    'Beri nama mesin dan lininya',
    'Rekam 120 detik kondisi sehat sebagai baseline',
    'Cek harian cukup 10 detik per mesin',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CARA KERJANYA', style: AppTextStyles.eyebrow),
          const SizedBox(height: 13),
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 11),
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.mono(
                        size: 11,
                        weight: FontWeight.w700,
                        color: AppColors.brand,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _steps[i],
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The PRD's standing disclaimer: AUDIAX triages, it does not diagnose.
class _DisclaimerFooter extends StatelessWidget {
  const _DisclaimerFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 13,
            color: AppColors.textFaint,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'AUDIAX memberi petunjuk awal dari suara mesin — bukan diagnosis akhir. Selalu konfirmasi dengan pemeriksaan teknisi.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: AppColors.textFaint,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

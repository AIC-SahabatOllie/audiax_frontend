import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/models/machine.dart';
import '../../../../shared/models/machine_status.dart';
import '../../../../shared/models/recording_mode.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/services/machine_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../calibration/presentation/screens/calibration_form_screen.dart';
import '../../../daily_check/presentation/screens/ready_screen.dart';
import '../widgets/machine_card.dart';
import 'machine_detail_screen.dart';

enum _MachineFilter { semua, perluTindakan, normal }

/// "Mesin" dashboard — the app's home screen: fleet summary, filters, and
/// the list of registered machines, backed by `GET /api/machines`
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
  _MachineFilter _filter = _MachineFilter.semua;

  List<Machine> _applyFilter(List<Machine> machines) {
    return switch (_filter) {
      _MachineFilter.semua => machines,
      _MachineFilter.perluTindakan =>
        machines.where((m) => m.status != MachineStatus.normal).toList(),
      _MachineFilter.normal =>
        machines.where((m) => m.status == MachineStatus.normal).toList(),
    };
  }

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.name, style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(widget.user.email, style: AppTextStyles.caption),
              const SizedBox(height: 20),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, _) {
          final machines = widget.repository.machines;

          if (widget.repository.isLoading && machines.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            );
          }
          if (widget.repository.error != null && machines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.repository.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Coba lagi',
                      onPressed: widget.repository.load,
                    ),
                  ],
                ),
              ),
            );
          }

          final warnCount = machines
              .where((m) => m.status != MachineStatus.normal)
              .length;
          final okCount = machines.length - warnCount;
          final filtered = _applyFilter(machines);
          final fleetIsEmpty = machines.isEmpty;

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: widget.repository.load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      user: widget.user,
                      total: machines.length,
                      warn: warnCount,
                      ok: okCount,
                      onAvatarTap: _openAccountSheet,
                    ),
                  ),
                  if (fleetIsEmpty)
                    SliverToBoxAdapter(
                      child: _EmptyFleetState(onTap: () => _openCalibration()),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Semua mesin',
                              style: AppTextStyles.title,
                            ),
                            _AddMachineChip(onTap: () => _openCalibration()),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _FilterRow(
                        filter: _filter,
                        onChanged: (f) => setState(() => _filter = f),
                      ),
                    ),
                    if (filtered.isEmpty)
                      const SliverToBoxAdapter(child: _EmptyFilterState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final machine = filtered[index];
                            return MachineCard(
                              machine: machine,
                              repository: widget.repository,
                              onOpenDetail: () => _openDetail(machine.id),
                              onCheck: () => _startInspection(machine),
                              onRecalibrate: (m) =>
                                  _openCalibration(existingMachine: m),
                            );
                          },
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                        child: _AddMachineDashedCard(
                          onTap: () => _openCalibration(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.total,
    required this.warn,
    required this.ok,
    required this.onAvatarTap,
  });

  final User user;
  final int total;
  final int warn;
  final int ok;
  final VoidCallback onAvatarTap;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: 10,
              bottom: 10,
              child: IgnorePointer(child: _WaveformMark()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_greeting, ${user.name}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Pemantauan kondisi mesin',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                                height: 1.15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _Avatar(initials: user.initials, onTap: onAvatarTap),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _StatChip(
                          icon: Icons.precision_manufacturing_rounded,
                          value: '$total',
                          label: 'TERDAFTAR',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatChip(
                          icon: Icons.warning_amber_rounded,
                          value: '$warn',
                          label: 'PERHATIAN',
                          accent: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatChip(
                          icon: Icons.verified_rounded,
                          value: '$ok',
                          label: 'NORMAL',
                          accent: AppColors.brandAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.onTap});

  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white24, width: 1.2),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
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
    );
  }
}

/// Faint decorative equalizer bars in the header corner — a quiet nod to the
/// app's "listen to the machine" identity without competing with the stats.
class _WaveformMark extends StatelessWidget {
  const _WaveformMark();

  static const _heights = [0.3, 0.55, 0.85, 0.5, 1.0, 0.4, 0.7, 0.35];

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final h in _heights)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FractionallySizedBox(
                heightFactor: h,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.accent = Colors.white,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.mono(
              size: 24,
              color: Colors.white,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.mono(
              size: 8,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMachineChip extends StatelessWidget {
  const _AddMachineChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(12, 9, 15, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'Tambah',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onChanged});

  final _MachineFilter filter;
  final ValueChanged<_MachineFilter> onChanged;

  static const _labels = {
    _MachineFilter.semua: 'Semua',
    _MachineFilter.perluTindakan: 'Perlu tindakan',
    _MachineFilter.normal: 'Normal',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      child: Row(
        children: [
          for (final entry in _labels.entries) ...[
            _FilterChip(
              label: entry.value,
              selected: filter == entry.key,
              onTap: () => onChanged(entry.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
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
      padding: const EdgeInsets.fromLTRB(22, 36, 22, 28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              size: 30,
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
            'Kalibrasi mesin pertama untuk mulai memantau kondisinya\nsetiap hari.',
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
        ],
      ),
    );
  }
}

/// Shown when a status filter has no matching machines — distinguishes
/// "nothing registered" from "nothing matches this filter" so the user
/// isn't misled into re-calibrating.
class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 26,
              color: AppColors.textFaint,
            ),
            SizedBox(height: 10),
            Text(
              'Tidak ada mesin dengan status ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMachineDashedCard extends StatelessWidget {
  const _AddMachineDashedCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: DottedBorderBox(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.okTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, size: 22, color: AppColors.ok),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kalibrasi mesin baru',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rekam 120 detik kondisi sehat',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed-border container (Flutter has no built-in dashed border), reused
/// wherever the mockup shows a dashed "add" affordance.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    final paint = Paint()
      ..color = AppColors.dashedBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const gapWidth = 5.0;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

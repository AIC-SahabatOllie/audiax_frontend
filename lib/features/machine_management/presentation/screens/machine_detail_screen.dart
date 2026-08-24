import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/models/inspection.dart';
import '../../../../shared/models/machine.dart';
import '../../../../shared/models/recording_mode.dart';
import '../../../../shared/models/trend_point.dart';
import '../../../../shared/services/machine_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/indicator_insight_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/status_style.dart';
import '../../../../shared/widgets/threshold_meter.dart';
import '../../../../shared/widgets/trend_bar_chart.dart';
import '../../../daily_check/presentation/screens/ready_screen.dart';

/// Machine detail: current z-score, dominant drifting indicator, trend, and
/// baseline metadata (docs/design.md §3.2 "Machine Detail & Live Spectral
/// Analysis") — loaded from `GET /machines/:id`, `.../baselines`, and
/// `.../inspections` (`docs/api_contract.md` §4/§5/§6) via
/// `MachineRepository.refreshDetail`.
class MachineDetailScreen extends StatefulWidget {
  const MachineDetailScreen({
    super.key,
    required this.repository,
    required this.machineId,
  });

  final MachineRepository repository;
  final String machineId;

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.repository.refreshDetail(widget.machineId);
  }

  List<TrendPoint> _trend() {
    final inspections = widget.repository.inspectionsFor(widget.machineId).where((i) => i.zScore != null).take(14).toList();
    return [
      for (final inspection in inspections.reversed)
        TrendPoint(value: inspection.zScore!, status: inspection.status.asMachineStatus!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, _) {
          final machine = widget.repository.byId(widget.machineId);
          if (machine == null) {
            return const SafeArea(child: Center(child: Text('Mesin tidak ditemukan')));
          }
          final trend = _trend();
          final style = StatusStyle.of(machine.status);

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Hero(machine: machine, style: style)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
                  sliver: SliverList.list(
                    children: [
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'INDIKATOR DOMINAN YANG BERGESER',
                              style: TextStyle(
                                fontFamily: AppTextStyles.monoFamily,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.4,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            IndicatorInsightCard(
                              dominantIndicator: machine.dominantIndicator,
                              reason: machine.reason,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TREN PEMERIKSAAN',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.monoFamily,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.4,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  'SKALA 0–8',
                                  style: AppTextStyles.mono(size: 9.5, color: AppColors.textFaint),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (trend.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Belum ada riwayat pemeriksaan.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.textFaint),
                                ),
                              )
                            else ...[
                              TrendBarChart(points: trend),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Pemeriksaan lalu', style: AppTextStyles.mono(size: 10, color: AppColors.textFaint)),
                                  Text('Terbaru', style: AppTextStyles.mono(size: 10, color: AppColors.textFaint)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BASELINE MESIN INI',
                              style: TextStyle(
                                fontFamily: AppTextStyles.monoFamily,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.4,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 13),
                            _infoRow('Kalibrasi', machine.calibrationLabel),
                            _infoRow(
                              'Kualitas',
                              machine.latestBaseline == null
                                  ? '—'
                                  : machine.latestBaseline!.calibrationQuality.toUpperCase(),
                              valueColor: machine.latestBaseline?.isGoodQuality == true
                                  ? AppColors.okDeep
                                  : AppColors.warningDeep,
                            ),
                            _infoRow(
                              'Jendela',
                              machine.latestBaseline == null ? '—' : '${machine.latestBaseline!.nWindows}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.okTint,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRIVACY BANDPASS',
                              style: AppTextStyles.mono(size: 9, color: AppColors.okDeep, letterSpacing: 1.4),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '300 Hz–3,4 kHz diatenuasi · audio mentah tidak disimpan',
                              style: TextStyle(fontSize: 11.5, height: 1.55, color: Color(0xFF4C6A57)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: machine.calibrated ? 'Periksa sekarang · 10 detik' : 'Mesin belum dikalibrasi',
                        enabled: machine.calibrated,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReadyScreen(
                              repository: widget.repository,
                              mode: RecordingMode.inspect,
                              machine: machine,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Indikator adalah petunjuk arah pergeseran, bukan jenis kerusakan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, height: 1.5, color: AppColors.textFaint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color valueColor = AppColors.ink}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.mono(size: 11.5, color: AppColors.textMuted)),
          Text(value, style: AppTextStyles.mono(size: 11.5, color: valueColor)),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.machine, required this.style});

  final Machine machine;
  final StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 26),
      decoration: const BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          StatusBadge(status: machine.status, pulse: true),
          const SizedBox(height: 12),
          Text(
            machine.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            machine.meta,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF8D97A6)),
          ),
          if (machine.description != null && machine.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              machine.description!,
              style: const TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFFAEB6C2)),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SKOR-Z FUSI',
                style: AppTextStyles.mono(size: 9.5, color: const Color(0xFF7B8695), letterSpacing: 1.4),
              ),
              Text(
                machine.zScore.toStringAsFixed(1).replaceAll('.', ','),
                style: AppTextStyles.mono(size: 44, color: Colors.white, letterSpacing: -1.6),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ThresholdMeter(
            value: machine.zScore,
            color: style.color,
            trackColor: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF6E7987))),
              Text('WARNING 3,0', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF6E7987))),
              Text('KRITIS 6,0', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF6E7987))),
              Text('8', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF6E7987))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

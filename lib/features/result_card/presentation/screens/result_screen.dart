import 'package:flutter/material.dart' hide Baseline;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../features/advisory/data/advisory_repository.dart';
import '../../../../features/advisory/presentation/screens/advisory_chat_screen.dart';
import '../../../../shared/models/baseline.dart';
import '../../../../shared/models/inspection.dart';
import '../../../../shared/models/machine_status.dart';
import '../../../../shared/models/recording_mode.dart';
import '../../../../shared/services/machine_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/indicator_insight_card.dart';
import '../../../../shared/widgets/status_style.dart';

/// Kartu hasil pemeriksaan / kalibrasi — status, indikator dominan, langkah
/// lanjut, dan disclaimer triase wajib (PRD §6A.1 #7, §12). Menampilkan
/// `Baseline`/`Inspection` asli dari `POST .../baselines` atau
/// `.../inspections` (`docs/api_contract.md` §5/§6) — tidak ada lagi data
/// fabrikasi lokal.
class ResultScreen extends StatelessWidget {
  const ResultScreen.calibration({
    super.key,
    required this.repository,
    required this.machineId,
    required Baseline baseline,
  }) : mode = RecordingMode.calibrate,
       _baseline = baseline,
       _inspection = null;

  const ResultScreen.inspection({
    super.key,
    required this.repository,
    required this.machineId,
    required Inspection inspection,
  }) : mode = RecordingMode.inspect,
       _inspection = inspection,
       _baseline = null;

  final MachineRepository repository;
  final RecordingMode mode;
  final String machineId;
  final Baseline? _baseline;
  final Inspection? _inspection;

  bool get _isCalibration => mode == RecordingMode.calibrate;

  Future<void> _finish(BuildContext context) async {
    await repository.refreshDetail(machineId);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Hanya untuk inspeksi. Kalibrasi tidak menghasilkan `inspectionId`, dan
  /// endpoint advisory memang tidak bisa dipanggil tanpanya.
  void _openAdvisory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdvisoryChatScreen(
          repository: AdvisoryRepository(repository.advisoryApi),
          machineId: machineId,
          inspection: _inspection!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _isCalibration ? _CalibrationHero(baseline: _baseline!) : _InspectionHero(inspection: _inspection!)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
              sliver: SliverList.list(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCalibration ? 'RINGKASAN KALIBRASI' : 'INDIKATOR DOMINAN',
                          style: AppTextStyles.mono(size: 9.5, color: AppColors.textMuted, letterSpacing: 1.4),
                        ),
                        const SizedBox(height: 15),
                        if (_isCalibration)
                          _CalibrationSummary(baseline: _baseline!)
                        else
                          IndicatorInsightCard(
                            dominantIndicator: _inspection!.dominantIndicator,
                            reason: _inspection!.reason,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LANGKAH LANJUT',
                          style: AppTextStyles.mono(size: 9.5, color: AppColors.okDeep, letterSpacing: 1.4),
                        ),
                        const SizedBox(height: 13),
                        for (final step in _isCalibration ? _calibrationSteps(_baseline!) : _inspectionSteps(_inspection!.status))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.ok,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.ink),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(label: 'Selesai', onPressed: () => _finish(context)),
                  if (!_isCalibration) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Tanya Teknisi Saku',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _openAdvisory(context),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    _isCalibration
                        ? 'Baseline tersimpan di server dan siap dipakai untuk pemeriksaan harian.'
                        : _inspection!.disclaimer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, height: 1.5, color: AppColors.textFaint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _calibrationSteps(Baseline baseline) {
    if (baseline.isGoodQuality) {
      return const [
        'Mesin siap dipakai untuk pemeriksaan harian.',
        'Ulangi kalibrasi jika blower diservis atau dipindah.',
      ];
    }
    return const [
      'Kualitas kalibrasi rendah — pertimbangkan rekam ulang lebih dekat ke mesin.',
      'Mesin tetap bisa diperiksa, tapi hasil mungkin kurang akurat.',
    ];
  }

  static List<String> _inspectionSteps(InspectionStatus status) => switch (status) {
    InspectionStatus.critical => const [
      'Matikan blower dan hentikan lini produksi sekarang.',
      'Periksa bearing dan kebersihan impeler.',
      'Jadwalkan servis teknisi hari ini.',
    ],
    InspectionStatus.warning => const [
      'Periksa baut dudukan dan kebersihan impeler.',
      'Ulangi pemeriksaan sore ini untuk konfirmasi.',
      'Jadwalkan servis dalam 7 hari.',
    ],
    InspectionStatus.normal => const [
      'Lanjutkan pemeriksaan rutin besok pagi.',
      'Tidak ada tindakan yang diperlukan.',
    ],
    InspectionStatus.calibrationInsufficient => const [
      'Kalibrasi ulang mesin ini sebelum pemeriksaan berikutnya.',
      'Rekam 2 menit kondisi sehat lewat menu "Kalibrasi ulang".',
    ],
  };
}

class _CalibrationSummary extends StatelessWidget {
  const _CalibrationSummary({required this.baseline});

  final Baseline baseline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Jendela terekam', '${baseline.nWindows}'),
        _row('Kualitas', baseline.calibrationQuality.toUpperCase()),
        _row('Fingerprint model', baseline.modelFingerprint),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.mono(size: 12, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalibrationHero extends StatelessWidget {
  const _CalibrationHero({required this.baseline});

  final Baseline baseline;

  @override
  Widget build(BuildContext context) {
    final style = baseline.isGoodQuality ? StatusStyle.of(MachineStatus.normal) : StatusStyle.of(MachineStatus.warning);
    return _Hero(
      style: style,
      eyebrow: 'HASIL KALIBRASI',
      title: baseline.isGoodQuality ? 'KALIBRASI BAIK' : 'KALIBRASI RENDAH',
      headline: baseline.isGoodQuality
          ? '${baseline.nWindows} jendela terekam bersih. Baseline aktif di server.'
          : '${baseline.nWindows} jendela terekam, tapi kualitas rendah. Baseline tetap aktif.',
      chips: [
        _StatChip(value: '${baseline.nWindows}', label: 'JENDELA'),
        _StatChip(value: baseline.calibrationQuality.toUpperCase(), label: 'KUALITAS'),
      ],
    );
  }
}

class _InspectionHero extends StatelessWidget {
  const _InspectionHero({required this.inspection});

  final Inspection inspection;

  @override
  Widget build(BuildContext context) {
    final mapped = inspection.status.asMachineStatus;
    final style = mapped != null
        ? StatusStyle.of(mapped)
        : const StatusStyle(
            color: AppColors.textMuted,
            deep: AppColors.inkSoft,
            tint: AppColors.surfaceMuted,
            chip: AppColors.divider,
          );
    final headline = switch (inspection.status) {
      InspectionStatus.critical => 'Pergeseran akustik jauh di atas ambang kritis. Hentikan produksi pada lini ini.',
      InspectionStatus.warning => 'Pergeseran akustik melewati ambang peringatan. Jadwalkan inspeksi.',
      InspectionStatus.normal => 'Suara blower masih dalam sebaran normal baseline mesin ini.',
      InspectionStatus.calibrationInsufficient =>
        inspection.reason ?? 'Kalibrasi mesin ini belum cukup untuk dianalisis.',
    };
    return _Hero(
      style: style,
      eyebrow: 'HASIL PEMERIKSAAN',
      title: inspection.status.label,
      headline: headline,
      chips: [
        _StatChip(value: inspection.zScore?.toStringAsFixed(1).replaceAll('.', ',') ?? '–', label: 'SKOR-Z'),
        _StatChip(value: inspection.healthScore?.toStringAsFixed(0) ?? '–', label: 'SKOR KESEHATAN'),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.style,
    required this.eyebrow,
    required this.title,
    required this.headline,
    required this.chips,
  });

  final StatusStyle style;
  final String eyebrow;
  final String title;
  final String headline;
  final List<_StatChip> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: style.deep,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: AppTextStyles.mono(size: 9.5, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.05,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(headline, style: TextStyle(fontSize: 13.5, height: 1.6, color: Colors.white.withValues(alpha: 0.86))),
          const SizedBox(height: 16),
          Row(children: [for (final chip in chips) ...[Expanded(child: chip), if (chip != chips.last) const SizedBox(width: 10)]]),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.mono(size: 26, color: Colors.white, letterSpacing: -0.8)),
          const SizedBox(height: 7),
          Text(
            label,
            style: AppTextStyles.mono(size: 8.5, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}

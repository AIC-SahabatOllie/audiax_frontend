import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../shared/models/calibration_draft.dart';
import '../../../../shared/models/machine.dart';
import '../../../../shared/models/recording_mode.dart';
import '../../../../shared/services/audio_recorder_service.dart';
import '../../../../shared/services/machine_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/countdown_ring.dart';
import '../../../../shared/widgets/input_quality_card.dart';
import '../../../../shared/widgets/live_spectrum_bars.dart';
import '../../../calibration/data/calibration_repository.dart';
import '../../../result_card/presentation/screens/result_screen.dart';
import '../../data/inspection_repository.dart';

enum _Phase { preparing, permissionDenied, recording, uploading, error }

/// Rekam 120 detik (kalibrasi) atau 10 detik (pemeriksaan harian), lalu
/// unggah ke `POST /machines/:id/baselines` atau `.../inspections`
/// (`docs/api_contract.md` §5/§6) — shared by `calibration` and
/// `daily_check` (PRD §6A.1 #3/#6).
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({
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

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late final Duration _total = widget.mode.duration;
  final AudioRecorderService _audio = AudioRecorderService();
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  _Phase _phase = _Phase.preparing;
  String? _errorMessage;

  bool get _isCalibrate => widget.mode == RecordingMode.calibrate;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  Future<void> _begin() async {
    setState(() {
      _phase = _Phase.preparing;
      _errorMessage = null;
    });
    final granted = await _audio.hasPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _phase = _Phase.permissionDenied);
      return;
    }
    await _audio.start();
    if (!mounted) return;
    _startedAt = DateTime.now();
    setState(() {
      _phase = _Phase.recording;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    final elapsed = DateTime.now().difference(_startedAt!);
    if (elapsed >= _total) {
      _finishRecording();
      return;
    }
    setState(() => _elapsed = elapsed);
  }

  Future<void> _finishRecording() async {
    _timer?.cancel();
    setState(() => _phase = _Phase.uploading);
    try {
      final file = await _audio.stop();
      if (file == null) {
        throw const ApiException(statusCode: 0, error: 'Rekaman gagal disimpan.');
      }
      if (_isCalibrate) {
        final draft = widget.draft!;
        final repo = CalibrationRepository(widget.repository.baselinesApi);
        final baseline = await repo.calibrate(draft.machineId, file);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultScreen.calibration(
              repository: widget.repository,
              machineId: draft.machineId,
              baseline: baseline,
            ),
          ),
        );
      } else {
        final machine = widget.machine!;
        final repo = InspectionRepository(widget.repository.inspectionsApi);
        final inspection = await repo.inspect(machine.id, file);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultScreen.inspection(
              repository: widget.repository,
              machineId: machine.id,
              inspection: inspection,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = e.displayMessage;
      });
    } finally {
      await _audio.dispose();
    }
  }

  void _cancel() {
    _timer?.cancel();
    if (_phase == _Phase.recording) {
      _audio.cancel();
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 26),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isCalibrate ? 'MEREKAM BASELINE' : 'MEMERIKSA KONDISI',
                    style: AppTextStyles.mono(
                      size: 9.5,
                      color: AppColors.brandAccent,
                      letterSpacing: 1.4,
                    ),
                  ),
                  if (_phase == _Phase.recording || _phase == _Phase.preparing)
                    Material(
                      color: const Color(0x1FFF8A80),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _cancel,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF8A80),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.preparing:
        return const _CenteredMessage(text: 'Menyiapkan mikrofon…');
      case _Phase.permissionDenied:
        return _CenteredMessage(
          text: 'Izin mikrofon diperlukan untuk merekam. Aktifkan lewat pengaturan perangkat.',
          action: AppButton(
            label: 'Kembali',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        );
      case _Phase.uploading:
        return _CenteredMessage(
          text: _isCalibrate ? 'Mengunggah baseline…' : 'Menganalisis kondisi mesin…',
          showSpinner: true,
        );
      case _Phase.error:
        return _CenteredMessage(
          text: _errorMessage ?? 'Terjadi kesalahan.',
          action: Column(
            children: [
              AppButton(label: 'Coba lagi', onPressed: _begin),
              const SizedBox(height: 10),
              AppButton(
                label: 'Kembali',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      case _Phase.recording:
        final remainingMs = (_total - _elapsed).inMilliseconds.clamp(0, _total.inMilliseconds);
        final remainingSeconds = (remainingMs / 1000).ceil();
        final remainingFraction = remainingMs / _total.inMilliseconds;
        return Column(
          children: [
            CountdownRing(remainingFraction: remainingFraction, seconds: remainingSeconds),
            const SizedBox(height: 22),
            Text(
              _isCalibrate
                  ? 'Tahan posisi ponsel. Rekaman ini menjadi garis dasar mesin — jangan bergerak menjauh.'
                  : 'Arahkan mikrofon ke blower. Jangan bicara selama perekaman.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF9AA4B2)),
            ),
            const SizedBox(height: 22),
            const LiveSpectrumBars(color: AppColors.brandAccent),
            const SizedBox(height: 22),
            const InputQualityCard(),
          ],
        );
    }
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text, this.action, this.showSpinner = false});

  final String text;
  final Widget? action;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          if (showSpinner) ...[
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.brandAccent),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white),
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    );
  }
}

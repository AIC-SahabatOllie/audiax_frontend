import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../shared/models/calibration_draft.dart';
import '../../../../shared/models/machine.dart';
import '../../../../shared/models/recording_mode.dart';
import '../../../../shared/services/machine_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../daily_check/presentation/screens/ready_screen.dart';

/// Guided calibration form — name + line/location, then position guidance
/// before the 120s recording starts (PRD §6A.1 #3).
class CalibrationFormScreen extends StatefulWidget {
  const CalibrationFormScreen({
    super.key,
    required this.repository,
    this.existingMachine,
  });

  final MachineRepository repository;
  final Machine? existingMachine;

  @override
  State<CalibrationFormScreen> createState() => _CalibrationFormScreenState();
}

class _CalibrationFormScreenState extends State<CalibrationFormScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.existingMachine?.name ?? '',
  );
  late final TextEditingController _lineController = TextEditingController(
    text: widget.existingMachine == null ? '' : widget.existingMachine!.line,
  );
  late final TextEditingController _descriptionController = TextEditingController(
    text: widget.existingMachine?.description ?? '',
  );
  String? _nameError;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lineController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() {
      _submitting = true;
      _nameError = null;
    });
    try {
      final String machineId;
      final existing = widget.existingMachine;
      if (existing != null) {
        machineId = existing.id;
      } else {
        final created = await widget.repository.create(
          label: _nameController.text.trim(),
          location: _lineController.text.trim().isEmpty ? null : _lineController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        );
        machineId = created.id;
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReadyScreen(
            repository: widget.repository,
            mode: RecordingMode.calibrate,
            draft: CalibrationDraft(
              machineId: machineId,
              name: _nameController.text.trim(),
              line: _lineController.text.trim(),
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _nameError = e.isConflict ? 'Nama mesin ini sudah dipakai.' : e.displayMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _nameController.text.trim().isNotEmpty && !_submitting;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, size: 18, color: AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Kalibrasi mesin baru', style: AppTextStyles.title),
              const SizedBox(height: 10),
              const Text(
                'Rekam 120 detik suara blower dalam kondisi sehat. Rekaman ini menjadi garis dasar khusus mesin tersebut.',
                style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('NAMA MESIN'),
                    const SizedBox(height: 9),
                    _TextField(
                      controller: _nameController,
                      hint: 'mis. Oven Blower 5',
                      errorText: _nameError,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel('LINI / LOKASI'),
                    const SizedBox(height: 9),
                    _TextField(controller: _lineController, hint: 'mis. Lini goreng'),
                    const SizedBox(height: 18),
                    _FieldLabel('DESKRIPSI (OPSIONAL)'),
                    const SizedBox(height: 9),
                    _TextField(
                      controller: _descriptionController,
                      hint: 'mis. Blower utama untuk pengering adonan lini 2',
                      maxLines: 3,
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
                    _FieldLabel('POSISI PONSEL'),
                    const SizedBox(height: 16),
                    _step('1', 'Pegang ponsel ±30 cm dari rumah blower.'),
                    const SizedBox(height: 13),
                    _step('2', 'Jangan tutup mikrofon dengan tangan atau kain.'),
                    const SizedBox(height: 13),
                    _step('3', 'Rekam saat oven berjalan normal, tanpa suara mesin lain.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: _submitting ? 'Memproses…' : 'Lanjutkan',
                enabled: canContinue,
                onPressed: _continue,
              ),
              const SizedBox(height: 12),
              const Text(
                'Rekaman baseline dikirim ke server untuk dianalisis.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: AppColors.okTint, borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.mono(size: 10.5, color: AppColors.okDeep),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.ink)),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.mono(size: 9.5, color: AppColors.textMuted, letterSpacing: 1.4));
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.controller, required this.hint, this.errorText, this.onChanged, this.maxLines = 1});

  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: maxLines > 1 ? maxLines : null,
      textAlignVertical: maxLines > 1 ? TextAlignVertical.top : null,
      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.ink),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.screenBackground,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textFaint, fontWeight: FontWeight.w500),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(15),
      ),
    );
  }
}

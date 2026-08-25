import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/models/advisory_message.dart';
import '../../../../shared/widgets/app_button.dart';

/// Sheet 6 pertanyaan yang dikumpulkan sekali per pembukaan chat, karena
/// `entity.Machine` belum punya kolom atribut mesin di backend (menunggu
/// migrasi 0005). Bentuk yang wajib dipertahankan: kunci map yang dikirim
/// ([AdvisoryOptions]), label Indonesia yang ditampilkan — mengirim label
/// alih-alih kunci menghasilkan 422 di setiap giliran.
class AdvisoryContextSheet extends StatefulWidget {
  const AdvisoryContextSheet({super.key});

  @override
  State<AdvisoryContextSheet> createState() => _AdvisoryContextSheetState();
}

class _AdvisoryContextSheetState extends State<AdvisoryContextSheet> {
  String _driveType = AdvisoryContext.conservativeDefault.driveType;
  String _recency = AdvisoryContext.conservativeDefault.recency;
  String _machineAge = AdvisoryContext.conservativeDefault.machineAge;
  String _hoursPerDay = AdvisoryContext.conservativeDefault.hoursPerDay;
  bool _hasBackup = AdvisoryContext.conservativeDefault.hasBackup;
  String _loadState = AdvisoryContext.conservativeDefault.loadState;

  void _submit() {
    Navigator.of(context).pop(
      AdvisoryContext(
        driveType: _driveType,
        recency: _recency,
        machineAge: _machineAge,
        hoursPerDay: _hoursPerDay,
        hasBackup: _hasBackup,
        loadState: _loadState,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AppColors.dashedBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'SEBELUM MULAI BERTANYA',
                  style: AppTextStyles.mono(size: 9.5, color: AppColors.textMuted, letterSpacing: 1.4),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jawab enam pertanyaan singkat ini supaya Teknisi Saku bisa menilai risiko mesin dengan lebih tepat.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                _dropdown(
                  label: 'Jenis penggerak',
                  value: _driveType,
                  options: AdvisoryOptions.driveType,
                  onChanged: (v) => setState(() => _driveType = v),
                ),
                _dropdown(
                  label: 'Terakhir diservis',
                  value: _recency,
                  options: AdvisoryOptions.recency,
                  onChanged: (v) => setState(() => _recency = v),
                ),
                _dropdown(
                  label: 'Umur mesin',
                  value: _machineAge,
                  options: AdvisoryOptions.machineAge,
                  onChanged: (v) => setState(() => _machineAge = v),
                ),
                _dropdown(
                  label: 'Jam operasi per hari',
                  value: _hoursPerDay,
                  options: AdvisoryOptions.hoursPerDay,
                  onChanged: (v) => setState(() => _hoursPerDay = v),
                ),
                _dropdown(
                  label: 'Kondisi saat ini',
                  value: _loadState,
                  options: AdvisoryOptions.loadState,
                  onChanged: (v) => setState(() => _loadState = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ada mesin cadangan?', style: AppTextStyles.body),
                  value: _hasBackup,
                  activeColor: AppColors.brand,
                  onChanged: (v) => setState(() => _hasBackup = v),
                ),
                const SizedBox(height: 14),
                AppButton(label: 'Mulai bertanya', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceMuted,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              for (final entry in options.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

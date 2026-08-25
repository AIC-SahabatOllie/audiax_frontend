import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/models/advisory_message.dart';

/// Satu gelembung percakapan.
///
/// Tiga hal WAJIB terlihat pada balasan asisten, dan tidak boleh dihilangkan
/// demi kerapian tampilan:
///
///   1. `escalated`  -- kondisi bahaya, harus dominan secara visual
///   2. `source`     -- penurunan ke jawaban statis tidak boleh senyap
///   3. `disclaimer` -- kewajiban produk, alat triase bukan diagnosis
class AdvisoryBubble extends StatelessWidget {
  const AdvisoryBubble({super.key, required this.message});

  final AdvisoryMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) return _userBubble();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // Bahaya mengubah seluruh warna gelembung, bukan cuma menambah ikon
          // kecil. Operator sedang menatap layar ponsel di ruangan bising.
          color: message.escalated ? AppColors.criticalTint : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: message.escalated
              ? Border.all(color: AppColors.critical, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.escalated) ...[
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.criticalDeep),
                  const SizedBox(width: 6),
                  Text(
                    'HENTIKAN MESIN',
                    style: AppTextStyles.mono(size: 10, color: AppColors.criticalDeep, letterSpacing: 1.4),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            Text(
              message.content,
              style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.ink),
            ),

            if (message.nextStep != null && message.nextStep!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_forward, size: 15, color: AppColors.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.nextStep!,
                        style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (message.needsTechnician) ...[
              const SizedBox(height: 10),
              _chip('Perlu teknisi', AppColors.warningChip, AppColors.warningDeep),
            ],

            if (message.isFallback) ...[
              const SizedBox(height: 10),
              // Badge sumber. Jangan sembunyikan mode fallback -- kalau LLM
              // mati, operator berhak tahu jawabannya berasal dari panduan
              // baku, bukan dari sesuatu yang membaca pertanyaannya.
              _chip('Panduan baku', AppColors.surfaceMuted, AppColors.textMuted),
            ],

            if (message.disclaimer != null) ...[
              const SizedBox(height: 8),
              Text(
                message.disclaimer!,
                style: const TextStyle(fontSize: 10.5, height: 1.45, color: AppColors.textFaint),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _userBubble() => Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.only(bottom: 14, left: 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.content,
        style: const TextStyle(fontSize: 14, height: 1.45, color: Colors.white),
      ),
    ),
  );

  Widget _chip(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
    child: Text(
      label,
      style: AppTextStyles.mono(size: 9.5, color: fg, letterSpacing: 0.8),
    ),
  );
}

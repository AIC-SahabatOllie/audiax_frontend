import 'package:flutter/material.dart';

/// Live input-level readout shown under the recording spectrum — mocked
/// values since there is no real Audio Quality Gate wired up yet (PRD §7.1
/// "kualitas kalibrasi rendah, ulangi perekaman").
class InputQualityCard extends StatelessWidget {
  const InputQualityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('LEVEL INPUT', 'BAIK · −18 dBFS'),
          const SizedBox(height: 11),
          _row('CLIPPING', 'TIDAK TERDETEKSI'),
          const SizedBox(height: 10),
          const Text(
            'Audio Quality Gate (F1) berjalan sebelum unggah.',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF6E7987)),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Color(0xFF8D97A6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Color(0xFF4DF2B8),
          ),
        ),
      ],
    );
  }
}

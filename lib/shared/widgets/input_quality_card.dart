import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../services/audio_quality_controller.dart';

/// Live input-level readout shown under the recording spectrum. Reads the same
/// [AudioQualityController] that feeds the bars and the pre-upload Audio
/// Quality Gate (PRD §7.1 "kualitas kalibrasi rendah, ulangi perekaman").
class InputQualityCard extends StatelessWidget {
  const InputQualityCard({super.key, required this.controller});

  final AudioQualityController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final status = controller.currentStatus;
          final clipped = controller.clippedRatio;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(
                'LEVEL INPUT',
                '${_statusLabel(status)} · ${_formatDbfs(controller.currentDbfs)}',
                _statusColor(status),
              ),
              const SizedBox(height: 12),
              _LevelMeter(dbfs: controller.currentDbfs, status: status),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _ScaleTick('−60'),
                  _ScaleTick('−24'),
                  _ScaleTick('0 dBFS'),
                ],
              ),
              const SizedBox(height: 12),
              _row(
                'CLIPPING',
                clipped > 0
                    ? 'TERDETEKSI · ${(clipped * 100).toStringAsFixed(0)}%'
                    : 'TIDAK TERDETEKSI',
                clipped > AudioQualityController.clippingTolerance
                    ? AppColors.critical
                    : clipped > 0
                    ? AppColors.warning
                    : AppColors.ok,
              ),
              const SizedBox(height: 10),
              const Text(
                'Audio Quality Gate (F1) berjalan sebelum unggah.',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF6E7987)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) {
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
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Horizontal dBFS scale (−60…0) with the zone the current level falls into
/// lit up and a marker tracking the live reading.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.dbfs, required this.status});

  final double dbfs;
  final AudioLevelStatus status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  // Flex values are the width of each zone in dB, so the
                  // scale stays linear against the −60…0 readout.
                  _zone(15, AudioLevelStatus.silent),
                  _zone(21, AudioLevelStatus.low),
                  _zone(18, AudioLevelStatus.good),
                  _zone(5, AudioLevelStatus.hot),
                  _zone(1, AudioLevelStatus.clipping),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment(normalizeDbfs(dbfs) * 2 - 1, 0),
            child: Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zone(int flex, AudioLevelStatus zone) {
    return Expanded(
      flex: flex,
      child: ColoredBox(
        color: _statusColor(zone).withValues(alpha: zone == status ? 0.9 : 0.22),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ScaleTick extends StatelessWidget {
  const _ScaleTick(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 9,
        color: Color(0xFF6E7987),
      ),
    );
  }
}

Color _statusColor(AudioLevelStatus status) {
  return switch (status) {
    AudioLevelStatus.good => AppColors.ok,
    AudioLevelStatus.low || AudioLevelStatus.hot => AppColors.warning,
    AudioLevelStatus.silent || AudioLevelStatus.clipping => AppColors.critical,
  };
}

String _statusLabel(AudioLevelStatus status) {
  return switch (status) {
    AudioLevelStatus.silent => 'SENYAP',
    AudioLevelStatus.low => 'TERLALU PELAN',
    AudioLevelStatus.good => 'BAIK',
    AudioLevelStatus.hot => 'TERLALU KERAS',
    AudioLevelStatus.clipping => 'CLIPPING',
  };
}

String _formatDbfs(double dbfs) {
  final rounded = dbfs.round();
  if (rounded <= kMinDbfs) return '≤ −60 dBFS';
  return '${rounded < 0 ? '−' : ''}${rounded.abs()} dBFS';
}

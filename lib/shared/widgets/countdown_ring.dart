import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Circular countdown used for both calibration (120s) and daily inspection
/// (10s) recording screens (docs/design.md "RecordingRing").
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.remainingFraction,
    required this.seconds,
    this.size = 222,
  });

  final double remainingFraction;
  final int seconds;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.brandAccent.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SizedBox(
            width: size - 28,
            height: size - 28,
            child: CircularProgressIndicator(
              value: remainingFraction.clamp(0, 1),
              strokeWidth: 2,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.brandAccent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$seconds',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 64,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -1.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'DETIK TERSISA',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: Color(0xFF7B8695),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

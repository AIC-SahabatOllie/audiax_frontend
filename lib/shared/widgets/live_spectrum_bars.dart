import 'package:flutter/material.dart';

import '../services/audio_quality_controller.dart';

/// Rolling history of the microphone input level shown while recording — one
/// bar per sample in [AudioQualityController.levels], newest on the right.
class LiveSpectrumBars extends StatelessWidget {
  const LiveSpectrumBars({
    super.key,
    required this.color,
    required this.controller,
    this.height = 60,
  });

  final Color color;
  final AudioQualityController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final levels = controller.levels;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < levels.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      // Floor of 3px so an idle mic still reads as a baseline
                      // instead of an empty strip.
                      height: (levels[i] * height).clamp(3.0, height),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.35 + levels[i] * 0.65),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

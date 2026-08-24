import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated bar spectrum used on the recording screen while audio is being
/// captured. Purely decorative (no real-time FFT — there is no microphone
/// wired up yet), seeded so the motion looks organic instead of uniform.
class LiveSpectrumBars extends StatefulWidget {
  const LiveSpectrumBars({
    super.key,
    required this.color,
    this.barCount = 38,
    this.height = 60,
  });

  final Color color;
  final int barCount;
  final double height;

  @override
  State<LiveSpectrumBars> createState() => _LiveSpectrumBarsState();
}

class _LiveSpectrumBarsState extends State<LiveSpectrumBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_BarPhase> _phases;

  @override
  void initState() {
    super.initState();
    final random = math.Random(7);
    _phases = List.generate(widget.barCount, (i) {
      return _BarPhase(
        speed: 0.6 + random.nextDouble() * 1.1,
        phase: random.nextDouble() * math.pi * 2,
        base: 0.28 + random.nextDouble() * 0.18,
        amplitude: 0.28 + random.nextDouble() * 0.34,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.lastElapsedDuration?.inMilliseconds ?? 0;
          final seconds = t / 1000;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _phases.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.2),
                    child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: _phases[i].heightFactorAt(seconds),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
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

class _BarPhase {
  const _BarPhase({
    required this.speed,
    required this.phase,
    required this.base,
    required this.amplitude,
  });

  final double speed;
  final double phase;
  final double base;
  final double amplitude;

  double heightFactorAt(double seconds) {
    final wave = (math.sin(seconds * speed + phase) + 1) / 2;
    return (base + amplitude * wave).clamp(0.05, 1.0);
  }
}

import 'package:flutter/material.dart';

import '../../app/theme/app_text_styles.dart';
import '../models/machine_status.dart';
import 'status_style.dart';

/// Pill with a dot + label, tinted in the status color — the app's one and
/// only way of surfacing NORMAL/WARNING/KRITIS (docs/design.md §1.4).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.pulse = false});

  final MachineStatus status;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: style.chip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(color: style.color, pulse: pulse),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: AppTextStyles.mono(
              size: 9,
              weight: FontWeight.w600,
              color: style.deep,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.pulse});

  final Color color;
  final bool pulse;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dot = SizedBox(width: 6, height: 6);
    if (_controller == null) {
      return DecoratedBox(
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        child: dot,
      );
    }
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        final opacity = 0.45 + _controller!.value * 0.55;
        return Opacity(
          opacity: opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
            child: dot,
          ),
        );
      },
    );
  }
}

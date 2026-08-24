import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';


class MachineCardSkeleton extends StatefulWidget {
  const MachineCardSkeleton({super.key});

  @override
  State<MachineCardSkeleton> createState() => _MachineCardSkeletonState();
}

class _MachineCardSkeletonState extends State<MachineCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = 0.45 + _controller.value * 0.45;
        return Container(
          padding: const EdgeInsets.fromLTRB(15, 16, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Bone(width: 46, height: 46, radius: 15, opacity: t),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bone(width: 132, height: 13, opacity: t),
                        const SizedBox(height: 8),
                        _Bone(width: 92, height: 10, opacity: t),
                      ],
                    ),
                  ),
                  _Bone(width: 44, height: 24, opacity: t),
                ],
              ),
              const SizedBox(height: 16),
              _Bone(width: double.infinity, height: 8, opacity: t),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _Bone(height: 42, radius: 16, opacity: t)),
                  const SizedBox(width: 8),
                  Expanded(child: _Bone(height: 42, radius: 16, opacity: t)),
                  const SizedBox(width: 8),
                  _Bone(width: 46, height: 42, radius: 16, opacity: t),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    this.width,
    required this.height,
    required this.opacity,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double opacity;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

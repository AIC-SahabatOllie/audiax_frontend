import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/widgets/brand_mark.dart';
import 'fleet_summary_card.dart';

class DashboardHero extends StatelessWidget {
  const DashboardHero({
    super.key,
    required this.user,
    required this.snapshot,
    required this.onAvatarTap,
    required this.onTapAttention,
  });

  final User user;
  final FleetSnapshot snapshot;
  final VoidCallback onAvatarTap;
  final VoidCallback onTapAttention;

  /// Vertical overlap between the summary card and the gradient. The gradient
  /// reserves this much empty space at its bottom, and the same amount is
  /// left below the translated card, so it doubles as the section gap.
  static const double _overlap = 56;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(34),
            ),
            child: Stack(
              children: [
                const Positioned(
                  right: -46,
                  top: -58,
                  child: IgnorePointer(child: _GlowBlob(size: 190)),
                ),
                const Positioned(
                  left: -70,
                  bottom: -80,
                  child: IgnorePointer(child: _GlowBlob(size: 170, opacity: 0.1)),
                ),
                const Positioned(
                  right: 18,
                  top: 74,
                  child: IgnorePointer(child: _WaveformMark()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, _overlap + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _BrandPill(),
                          const Spacer(),
                          _Avatar(
                            initials: user.initials,
                            onTap: onAvatarTap,
                            alert: snapshot.critical > 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        '$_greeting, ${user.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pemantauan kondisi mesin',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormatter.longDate(DateTime.now()).toUpperCase(),
                        style: AppTextStyles.mono(
                          size: 9.5,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -_overlap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: FleetSummaryCard(
              snapshot: snapshot,
              onTapAttention: onTapAttention,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(size: 22),
          const SizedBox(width: 7),
          Text(
            'AUDIAX',
            style: AppTextStyles.mono(
              size: 10.5,
              weight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.onTap,
    required this.alert,
  });

  final String initials;
  final VoidCallback onTap;

  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.14),
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white24, width: 1.2),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (alert)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.critical,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, this.opacity = 0.16});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.brandAccent.withValues(alpha: opacity),
            AppColors.brandAccent.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _WaveformMark extends StatelessWidget {
  const _WaveformMark();

  static const _heights = [10.0, 20.0, 32.0, 18.0, 38.0, 14.0, 26.0, 12.0];

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.13,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final height in _heights)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 5,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

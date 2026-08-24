import 'package:flutter/material.dart';

import '../models/trend_point.dart';
import 'status_style.dart';

/// Bar chart for the "tren N pemeriksaan" panel on the machine detail screen.
class TrendBarChart extends StatelessWidget {
  const TrendBarChart({super.key, required this.points, this.height = 88});

  final List<TrendPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: (point.scalePct / 100).clamp(0.04, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: StatusStyle.of(point.status).color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                        bottom: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

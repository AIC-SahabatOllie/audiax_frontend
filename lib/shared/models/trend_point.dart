import 'machine_status.dart';

/// One point on the "TREN 14 PEMERIKSAAN" bar chart — built from real
/// `Inspection` history by `MachineDetailScreen`, not generated.
class TrendPoint {
  final double value;
  final MachineStatus status;

  const TrendPoint({required this.value, required this.status});

  double get scalePct =>
      (value / MachineStatusLabel.scaleMax * 100).clamp(0, 100);
}

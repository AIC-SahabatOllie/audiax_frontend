import 'machine_status.dart';

/// Maps the `status` field of `InspectionResponse`
/// (`docs/api_contract.md` §6) — four values, `calibrationInsufficient`
/// (`KALIBRASI_KURANG`) is a normal outcome, not an error: the endpoint
/// still returns `201` for it.
enum InspectionStatus { normal, warning, critical, calibrationInsufficient }

extension InspectionStatusX on InspectionStatus {
  static InspectionStatus fromApi(String value) => switch (value) {
    'NORMAL' => InspectionStatus.normal,
    'WARNING' => InspectionStatus.warning,
    'CRITICAL' => InspectionStatus.critical,
    'KALIBRASI_KURANG' => InspectionStatus.calibrationInsufficient,
    _ => throw ArgumentError('unknown inspection status: $value'),
  };

  String get label => switch (this) {
    InspectionStatus.normal => 'NORMAL',
    InspectionStatus.warning => 'WARNING',
    InspectionStatus.critical => 'KRITIS',
    InspectionStatus.calibrationInsufficient => 'KALIBRASI KURANG',
  };

  /// `null` for `calibrationInsufficient` — it has no place on the
  /// normal/warning/critical fleet-health scale used for badges/filters.
  MachineStatus? get asMachineStatus => switch (this) {
    InspectionStatus.normal => MachineStatus.normal,
    InspectionStatus.warning => MachineStatus.warning,
    InspectionStatus.critical => MachineStatus.critical,
    InspectionStatus.calibrationInsufficient => null,
  };
}

/// Maps `InspectionResponse` in `docs/api_contract.md` §6.
class Inspection {
  final String id;
  final String machineId;
  final String? baselineId;
  final InspectionStatus status;
  final double? zScore;
  final double? healthScore;
  final String? dominantIndicator;
  final String? reason;
  final String disclaimer;
  final DateTime inspectedAt;

  const Inspection({
    required this.id,
    required this.machineId,
    required this.baselineId,
    required this.status,
    required this.zScore,
    required this.healthScore,
    required this.dominantIndicator,
    required this.reason,
    required this.disclaimer,
    required this.inspectedAt,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
    id: json['id'] as String,
    machineId: json['machine_id'] as String,
    baselineId: json['baseline_id'] as String?,
    status: InspectionStatusX.fromApi(json['status'] as String),
    zScore: (json['z_score'] as num?)?.toDouble(),
    healthScore: (json['health_score'] as num?)?.toDouble(),
    dominantIndicator: json['dominant_indicator'] as String?,
    reason: json['reason'] as String?,
    disclaimer: json['disclaimer'] as String,
    inspectedAt: DateTime.parse(json['inspected_at'] as String),
  );
}

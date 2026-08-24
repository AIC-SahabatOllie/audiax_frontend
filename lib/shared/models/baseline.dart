/// Maps `BaselineResponse` in `docs/api_contract.md` §5. Embeddings/backend
/// stats/notes are intentionally never returned by the API, so they have no
/// field here either.
class Baseline {
  final String id;
  final String machineId;
  final String modelFingerprint;
  final int nWindows;

  /// `"baik"` or `"rendah"` — raw value from the AI service.
  final String calibrationQuality;
  final bool isActive;
  final DateTime calibratedAt;

  const Baseline({
    required this.id,
    required this.machineId,
    required this.modelFingerprint,
    required this.nWindows,
    required this.calibrationQuality,
    required this.isActive,
    required this.calibratedAt,
  });

  bool get isGoodQuality => calibrationQuality == 'baik';

  factory Baseline.fromJson(Map<String, dynamic> json) => Baseline(
    id: json['id'] as String,
    machineId: json['machine_id'] as String,
    modelFingerprint: json['model_fingerprint'] as String,
    nWindows: json['n_windows'] as int,
    calibrationQuality: json['calibration_quality'] as String,
    isActive: json['is_active'] as bool,
    calibratedAt: DateTime.parse(json['calibrated_at'] as String),
  );
}

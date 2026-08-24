import '../../core/utils/date_formatter.dart';
import 'baseline.dart';
import 'inspection.dart';
import 'machine_status.dart';

/// A registered machine. Core fields map `MachineResponse`
/// (`docs/api_contract.md` §4); `latestBaseline`/`latestInspection` are
/// attached by `MachineRepository` from the separate baselines/inspections
/// endpoints (§5/§6) so screens can render fleet status without each doing
/// their own N-call fan-out.
class Machine {
  final String id;
  final String label;
  final String? location;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Baseline? latestBaseline;
  final Inspection? latestInspection;

  const Machine({
    required this.id,
    required this.label,
    this.location,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.latestBaseline,
    this.latestInspection,
  });

  factory Machine.fromJson(Map<String, dynamic> json) => Machine(
    id: json['id'] as String,
    label: json['label'] as String,
    location: json['location'] as String?,
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  String get name => label;
  String get line => location ?? 'Belum diberi lini';

  /// Whether this machine has an active baseline at all — matches the
  /// backend's own eligibility check for inspections (quality, "baik" vs
  /// "rendah", is a separate signal shown in [calibrationLabel]).
  bool get calibrated => latestBaseline != null;

  MachineStatus get status => latestInspection?.status.asMachineStatus ?? MachineStatus.normal;

  /// Whether this machine has ever produced a health reading. Distinct from
  /// [status]: an un-inspected machine defaults to `normal` on the shared
  /// scale, but the dashboard must show it as *unknown*, never as healthy.
  bool get inspected => latestInspection?.status.asMachineStatus != null;

  DateTime? get lastInspectedAt => latestInspection?.inspectedAt;

  /// Drives the fleet ring's "sudah dicek hari ini" fraction.
  bool get checkedToday {
    final at = lastInspectedAt;
    return at != null && DateFormatter.isToday(at);
  }

  double get zScore => latestInspection?.zScore ?? 0;

  String? get dominantIndicator => latestInspection?.dominantIndicator;
  String? get reason => latestInspection?.reason;

  String get calibrationLabel {
    final baseline = latestBaseline;
    if (baseline == null) return 'Belum dikalibrasi';
    final dateLabel =
        'Terkalibrasi ${DateFormatter.shortDate(baseline.calibratedAt)} · ${baseline.nWindows} jendela';
    return baseline.isGoodQuality ? dateLabel : '$dateLabel · kualitas rendah';
  }

  String get lastCheckedLabel {
    final inspection = latestInspection;
    if (inspection == null) return 'belum diperiksa';
    return 'cek ${DateFormatter.time(inspection.inspectedAt)}';
  }

  /// Relative variant of [lastCheckedLabel] for the dashboard, where "2 jam
  /// lalu" answers "is this reading still fresh?" better than a clock time.
  String get lastCheckedRelativeLabel {
    final at = lastInspectedAt;
    if (at == null) return 'Belum pernah diperiksa';
    return 'Diperiksa ${DateFormatter.relative(at)}';
  }

  String get meta => '$line · $lastCheckedLabel';

  Machine copyWith({
    String? label,
    String? location,
    String? description,
    Baseline? latestBaseline,
    Inspection? latestInspection,
  }) {
    return Machine(
      id: id,
      label: label ?? this.label,
      location: location ?? this.location,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt,
      latestBaseline: latestBaseline ?? this.latestBaseline,
      latestInspection: latestInspection ?? this.latestInspection,
    );
  }
}

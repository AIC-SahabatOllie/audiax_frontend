/// Fusion z-score health status for a machine, per F8 (PRD §6A.1 #7).
///
/// Thresholds are a fixed visual/decision constant across the app:
/// WARNING at z ≥ 3,0, CRITICAL at z ≥ 6,0, on a 0–8 display scale.
enum MachineStatus { normal, warning, critical }

extension MachineStatusLabel on MachineStatus {
  String get label => switch (this) {
    MachineStatus.normal => 'NORMAL',
    MachineStatus.warning => 'WARNING',
    MachineStatus.critical => 'KRITIS',
  };

  static const double warningThreshold = 3.0;
  static const double criticalThreshold = 6.0;
  static const double scaleMax = 8.0;

  static MachineStatus fromZScore(double z) {
    if (z >= criticalThreshold) return MachineStatus.critical;
    if (z >= warningThreshold) return MachineStatus.warning;
    return MachineStatus.normal;
  }
}

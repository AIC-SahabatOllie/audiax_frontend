/// Form state carried from the calibration screen through ready/recording to
/// the result screen. `machineId` is always a real, already-created machine
/// by the time this reaches `RecordingScreen` — `CalibrationFormScreen`
/// resolves it (creating the machine via `POST /machines` for a new one, or
/// reusing the existing id for a recalibration) before navigating on.
class CalibrationDraft {
  final String machineId;
  final String name;
  final String line;

  const CalibrationDraft({required this.machineId, required this.name, required this.line});
}

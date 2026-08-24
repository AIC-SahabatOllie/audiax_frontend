/// Which recording flow is active — shared by `calibration` (120s baseline)
/// and `daily_check` (10s inspection), since both reuse the same
/// ready/recording screens (docs/design.md "RecordingScreen").
enum RecordingMode { calibrate, inspect }

extension RecordingModeDuration on RecordingMode {
  Duration get duration => switch (this) {
    RecordingMode.calibrate => const Duration(seconds: 120),
    RecordingMode.inspect => const Duration(seconds: 10),
  };

  String get durationLabel => switch (this) {
    RecordingMode.calibrate => '120 detik',
    RecordingMode.inspect => '10 detik',
  };
}

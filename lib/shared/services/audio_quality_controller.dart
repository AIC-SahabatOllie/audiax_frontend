import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Input level buckets used by the recording UI and the pre-upload quality
/// gate (PRD §7.1 "kualitas kalibrasi rendah, ulangi perekaman").
enum AudioLevelStatus { silent, low, good, hot, clipping }

/// Bottom of the meter scale. Mic noise floors sit well below this, so
/// anything quieter is drawn as "no bar" rather than a sliver.
const double kMinDbfs = -60.0;
const double kMaxDbfs = 0.0;

/// Thresholds are in dBFS (0 = full scale). `-1` and below is where a 16-bit
/// WAV starts to square off, and `-24` is the quietest level that still leaves
/// the analyzer enough headroom above a phone mic's noise floor.
AudioLevelStatus classifyLevel(double dbfs) {
  if (dbfs >= -1.0) return AudioLevelStatus.clipping;
  if (dbfs >= -6.0) return AudioLevelStatus.hot;
  if (dbfs >= -24.0) return AudioLevelStatus.good;
  if (dbfs >= -45.0) return AudioLevelStatus.low;
  return AudioLevelStatus.silent;
}

/// Maps a dBFS reading onto 0.0–1.0 for bar/meter geometry.
double normalizeDbfs(double dbfs) {
  return ((dbfs - kMinDbfs) / (kMaxDbfs - kMinDbfs)).clamp(0.0, 1.0);
}

/// Single source of truth for live microphone level during a recording —
/// shared by `LiveSpectrumBars` and `InputQualityCard` so both render from one
/// subscription, and read by `RecordingScreen` for the pre-upload quality gate.
class AudioQualityController extends ChangeNotifier {
  AudioQualityController() {
    _levelsView = UnmodifiableListView(_levels);
  }

  /// Number of samples kept for the spectrum history (one bar each).
  static const int historyLength = 38;

  /// Above this share of clipped samples the recording is worth redoing.
  static const double clippingTolerance = 0.05;

  /// A session is "too quiet" when most of it never rose above [-45, -24) dBFS.
  static const double lowSignalTolerance = 0.6;

  final List<double> _levels = List<double>.filled(historyLength, 0.0, growable: true);
  late final UnmodifiableListView<double> _levelsView;

  StreamSubscription<Amplitude>? _subscription;
  double _currentDbfs = kMinDbfs;
  int _sampleCount = 0;
  int _clippedCount = 0;
  int _weakCount = 0;
  double _dbfsSum = 0;

  double get currentDbfs => _currentDbfs;

  AudioLevelStatus get currentStatus => classifyLevel(_currentDbfs);

  /// Rolling history normalised to 0.0–1.0, oldest first.
  List<double> get levels => _levelsView;

  int get sampleCount => _sampleCount;

  double get clippedRatio => _sampleCount == 0 ? 0 : _clippedCount / _sampleCount;

  double get averageDbfs => _sampleCount == 0 ? kMinDbfs : _dbfsSum / _sampleCount;

  bool get hasLowSignal =>
      _sampleCount > 0 && _weakCount / _sampleCount > lowSignalTolerance;

  /// Subscribes to a fresh amplitude stream, discarding the previous session.
  void start(Stream<Amplitude> stream) {
    _subscription?.cancel();
    _reset();
    _subscription = stream.listen(_onAmplitude);
    notifyListeners();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onAmplitude(Amplitude amplitude) {
    // Some platforms report -inf/NaN while the mic is still warming up.
    final dbfs = amplitude.current.isFinite
        ? amplitude.current.clamp(kMinDbfs, kMaxDbfs).toDouble()
        : kMinDbfs;

    _currentDbfs = dbfs;
    _sampleCount++;
    _dbfsSum += dbfs;

    final status = classifyLevel(dbfs);
    if (status == AudioLevelStatus.clipping) _clippedCount++;
    if (status == AudioLevelStatus.silent || status == AudioLevelStatus.low) {
      _weakCount++;
    }

    _levels.removeAt(0);
    _levels.add(normalizeDbfs(dbfs));
    notifyListeners();
  }

  void _reset() {
    _levels.fillRange(0, _levels.length, 0.0);
    _currentDbfs = kMinDbfs;
    _sampleCount = 0;
    _clippedCount = 0;
    _weakCount = 0;
    _dbfsSum = 0;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

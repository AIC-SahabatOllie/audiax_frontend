import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Thin wrapper around `package:record` — captures a WAV file (matching
/// `docs/api_contract.md` §1 "Upload audio: Berkas WAV") for the
/// calibration (120s) and daily-check (10s) recording flows.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/audiax_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
  }

  Future<File?> stop() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    return File(path);
  }

  /// Live input level while recording — drives the spectrum bars, the input
  /// quality card and the pre-upload quality gate.
  Stream<Amplitude> amplitudeStream({
    Duration interval = const Duration(milliseconds: 120),
  }) {
    return _recorder.onAmplitudeChanged(interval);
  }

  Future<void> cancel() => _recorder.cancel();

  Future<void> dispose() => _recorder.dispose();
}

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
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
  }

  Future<File?> stop() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    return File(path);
  }

  Future<void> cancel() => _recorder.cancel();

  Future<void> dispose() => _recorder.dispose();
}

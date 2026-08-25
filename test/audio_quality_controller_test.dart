import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'package:audiax_frontend/shared/services/audio_quality_controller.dart';

/// Menyalurkan deretan pembacaan dBFS ke controller dan menunggu sampai
/// seluruh event terkirim.
Future<void> feed(AudioQualityController controller, List<double> dbfsValues) async {
  final source = StreamController<Amplitude>();
  controller.start(source.stream);
  for (final dbfs in dbfsValues) {
    source.add(Amplitude(current: dbfs, max: dbfs));
  }
  await source.close();
}

void main() {
  group('classifyLevel', () {
    test('0 dBFS dan tepat di batas −1 dBFS dianggap clipping', () {
      expect(classifyLevel(0), AudioLevelStatus.clipping);
      expect(classifyLevel(-1.0), AudioLevelStatus.clipping);
    });

    test('tepat di bawah −1 sampai batas −6 dBFS dianggap terlalu keras', () {
      expect(classifyLevel(-1.01), AudioLevelStatus.hot);
      expect(classifyLevel(-6.0), AudioLevelStatus.hot);
    });

    test('tepat di bawah −6 sampai batas −24 dBFS dianggap baik', () {
      expect(classifyLevel(-6.01), AudioLevelStatus.good);
      expect(classifyLevel(-18.0), AudioLevelStatus.good);
      expect(classifyLevel(-24.0), AudioLevelStatus.good);
    });

    test('tepat di bawah −24 sampai batas −45 dBFS dianggap terlalu pelan', () {
      expect(classifyLevel(-24.01), AudioLevelStatus.low);
      expect(classifyLevel(-45.0), AudioLevelStatus.low);
    });

    test('di bawah −45 dBFS dianggap senyap', () {
      expect(classifyLevel(-45.01), AudioLevelStatus.silent);
      expect(classifyLevel(-60.0), AudioLevelStatus.silent);
      expect(classifyLevel(-120.0), AudioLevelStatus.silent);
    });
  });

  group('normalizeDbfs', () {
    test('memetakan −60..0 dBFS ke 0..1 dan menjepit di luar rentang', () {
      expect(normalizeDbfs(-60.0), 0.0);
      expect(normalizeDbfs(0.0), 1.0);
      expect(normalizeDbfs(-30.0), closeTo(0.5, 0.0001));
      expect(normalizeDbfs(-120.0), 0.0);
      expect(normalizeDbfs(12.0), 1.0);
    });
  });

  group('AudioQualityController', () {
    test('menghitung clippedRatio sebagai proporsi sample yang clipping', () async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);

      // 2 dari 8 sample clipping (>= −1 dBFS) → 0.25.
      await feed(controller, [-18, -18, 0, -0.5, -18, -18, -18, -18]);

      expect(controller.sampleCount, 8);
      expect(controller.clippedRatio, closeTo(0.25, 0.0001));
    });

    test('clippedRatio nol saat belum ada sample maupun saat tidak ada yang clipping', () async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);

      expect(controller.clippedRatio, 0);

      await feed(controller, [-30, -22, -18, -12]);

      expect(controller.clippedRatio, 0);
    });

    test('mulai rekaman baru mereset hitungan sesi sebelumnya', () async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);

      await feed(controller, [0, 0, 0, 0]);
      expect(controller.clippedRatio, 1.0);

      await feed(controller, [-18, -18]);

      expect(controller.sampleCount, 2);
      expect(controller.clippedRatio, 0);
    });

    test('currentStatus dan currentDbfs mengikuti sample terakhir', () async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);

      await feed(controller, [-50, -30, -18]);

      expect(controller.currentDbfs, -18);
      expect(controller.currentStatus, AudioLevelStatus.good);
    });

    test('riwayat level dibatasi 38 sample terakhir, ternormalisasi 0..1', () async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);

      await feed(controller, List<double>.filled(50, -30.0));

      expect(controller.levels.length, AudioQualityController.historyLength);
      expect(controller.levels.last, closeTo(0.5, 0.0001));
      expect(controller.levels.first, closeTo(0.5, 0.0001));
    });

    test('riwayat menggeser sample terlama sehingga yang terbaru ada di akhir', () async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);

      await feed(controller, [-60, -30, 0]);

      expect(controller.levels.last, 1.0);
      expect(controller.levels[controller.levels.length - 2], closeTo(0.5, 0.0001));
      expect(controller.levels[controller.levels.length - 3], 0.0);
    });

    test('hasLowSignal aktif hanya kalau mayoritas sesi pelan atau senyap', () async {
      final quiet = AudioQualityController();
      addTearDown(quiet.dispose);
      // 8 dari 10 sample pelan/senyap (> 60%).
      await feed(quiet, [-50, -50, -50, -50, -30, -30, -30, -30, -18, -18]);
      expect(quiet.hasLowSignal, isTrue);

      final loud = AudioQualityController();
      addTearDown(loud.dispose);
      // 4 dari 10 sample pelan/senyap (< 60%).
      await feed(loud, [-50, -50, -30, -30, -18, -18, -18, -18, -18, -18]);
      expect(loud.hasLowSignal, isFalse);
    });

    test('averageDbfs adalah rata-rata sample sesi berjalan', () async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);

      await feed(controller, [-10, -20, -30]);

      expect(controller.averageDbfs, closeTo(-20.0, 0.0001));
    });

    test('pembacaan tak hingga diperlakukan sebagai dasar skala −60 dBFS', () async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);

      await feed(controller, [double.negativeInfinity, double.nan]);

      expect(controller.currentDbfs, kMinDbfs);
      expect(controller.currentStatus, AudioLevelStatus.silent);
      expect(controller.levels.last, 0.0);
    });

    test('memberi tahu listener setiap ada sample baru', () async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await feed(controller, [-30, -20, -10]);

      // 1 dari start() + 1 per sample.
      expect(notifications, 4);
    });

    test('stop() menghentikan pembaruan dari stream lama', () async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);
      final source = StreamController<Amplitude>();
      controller.start(source.stream);

      source.add(Amplitude(current: -18, max: -18));
      await Future<void>.delayed(Duration.zero);
      await controller.stop();
      source.add(Amplitude(current: 0, max: 0));
      await source.close();

      expect(controller.sampleCount, 1);
      expect(controller.currentDbfs, -18);
    });
  });
}

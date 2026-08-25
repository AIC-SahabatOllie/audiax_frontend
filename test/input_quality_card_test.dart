import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'package:audiax_frontend/shared/services/audio_quality_controller.dart';
import 'package:audiax_frontend/shared/widgets/input_quality_card.dart';
import 'package:audiax_frontend/shared/widgets/live_spectrum_bars.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(backgroundColor: Colors.black, body: child),
  );
}

void main() {
  group('InputQualityCard', () {
    testWidgets('menampilkan level dan status yang ikut berubah saat ada sample baru', (tester) async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);
      final source = StreamController<Amplitude>();
      controller.start(source.stream);

      await tester.pumpWidget(_host(InputQualityCard(controller: controller)));

      expect(find.textContaining('SENYAP'), findsOneWidget);

      source.add(Amplitude(current: -18, max: -18));
      await tester.pump();

      expect(find.text('BAIK · −18 dBFS'), findsOneWidget);

      await source.close();
    });

    testWidgets('baris CLIPPING berubah jadi TERDETEKSI setelah ada sample clipping', (tester) async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);
      final source = StreamController<Amplitude>();
      controller.start(source.stream);

      await tester.pumpWidget(_host(InputQualityCard(controller: controller)));

      expect(find.text('TIDAK TERDETEKSI'), findsOneWidget);

      source.add(Amplitude(current: 0, max: 0));
      await tester.pump();

      expect(find.text('TIDAK TERDETEKSI'), findsNothing);
      expect(find.textContaining('TERDETEKSI · 100%'), findsOneWidget);

      await source.close();
    });
  });

  group('LiveSpectrumBars', () {
    testWidgets('menggambar satu bar per sample riwayat controller', (tester) async {
      final controller = AudioQualityController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(LiveSpectrumBars(color: Colors.teal, controller: controller)),
      );

      expect(
        find.byType(AnimatedContainer),
        findsNWidgets(AudioQualityController.historyLength),
      );
    });
  });
}

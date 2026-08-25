import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:audiax_frontend/core/network/api_client.dart';
import 'package:audiax_frontend/core/network/session_store.dart';
import 'package:audiax_frontend/shared/models/advisory_message.dart';
import 'package:audiax_frontend/shared/services/advisory_api.dart';

void main() {
  group('AdvisoryApi.send', () {
    test('path memuat machineId dan inspectionId di posisi yang benar, dan amplop {"data": ...} terbuka', () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'data': {
              'reply': 'Jawaban',
              'next_step': 'Langkah',
              'needs_technician': false,
              'escalated': false,
              'source': 'llm',
              'disclaimer': 'Disclaimer',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = AdvisoryApi(ApiClient(sessionStore: SessionStore(), httpClient: client));

      final reply = await api.send(
        machineId: 'machine-1',
        inspectionId: 'inspection-2',
        history: const [],
        userMessage: 'sabuknya kenceng kok',
        context: AdvisoryContext.conservativeDefault,
      );

      expect(captured!.url.path, '/api/machines/machine-1/inspections/inspection-2/advisory/messages');
      expect(reply.content, 'Jawaban');
      expect(reply.source, 'llm');
    });

    test('riwayat dipotong di 8 giliran, dan yang terbaru yang bertahan', () async {
      List<dynamic>? sentHistory;
      final client = MockClient((request) async {
        sentHistory = (jsonDecode(request.body) as Map<String, dynamic>)['history'] as List<dynamic>;
        return http.Response(
          jsonEncode({
            'data': {'reply': 'ok'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = AdvisoryApi(ApiClient(sessionStore: SessionStore(), httpClient: client));

      final history = List.generate(
        10,
        (i) => AdvisoryMessage(role: i.isEven ? 'user' : 'assistant', content: 'pesan-$i'),
      );

      await api.send(
        machineId: 'm',
        inspectionId: 'i',
        history: history,
        userMessage: 'terbaru',
        context: AdvisoryContext.conservativeDefault,
      );

      expect(sentHistory!.length, 8);
      expect(sentHistory!.first, {'role': 'user', 'content': 'pesan-2'});
      expect(sentHistory!.last, {'role': 'assistant', 'content': 'pesan-9'});
    });
  });
}

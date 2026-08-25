import 'package:flutter_test/flutter_test.dart';

import 'package:audiax_frontend/shared/models/advisory_message.dart';

void main() {
  group('AdvisoryMessage.fromResponse', () {
    test('memetakan keenam field dari respons backend', () {
      final message = AdvisoryMessage.fromResponse({
        'reply': 'Bau gosong itu tanda bahaya serius.',
        'next_step': 'Matikan mesin sekarang juga.',
        'needs_technician': true,
        'escalated': true,
        'source': 'fallback_static',
        'disclaimer': 'Alat bantu triase, bukan diagnosis mengikat.',
      });

      expect(message.role, 'assistant');
      expect(message.content, 'Bau gosong itu tanda bahaya serius.');
      expect(message.nextStep, 'Matikan mesin sekarang juga.');
      expect(message.needsTechnician, isTrue);
      expect(message.escalated, isTrue);
      expect(message.source, 'fallback_static');
      expect(message.disclaimer, 'Alat bantu triase, bukan diagnosis mengikat.');
      expect(message.isFallback, isTrue);
    });

    test('memakai default aman kalau field opsional absen', () {
      final message = AdvisoryMessage.fromResponse({'reply': 'Halo'});

      expect(message.needsTechnician, isFalse);
      expect(message.escalated, isFalse);
      expect(message.source, isNull);
      expect(message.isFallback, isFalse);
    });
  });

  test('toHistoryJson hanya menghasilkan role dan content', () {
    const message = AdvisoryMessage(
      role: 'assistant',
      content: 'Jawaban',
      nextStep: 'Langkah',
      needsTechnician: true,
      escalated: true,
      source: 'llm',
      disclaimer: 'Disclaimer',
    );

    expect(message.toHistoryJson(), {'role': 'assistant', 'content': 'Jawaban'});
  });

  test('AdvisoryContext.toJson memakai nama snake_case yang benar', () {
    const context = AdvisoryContext(
      driveType: 'belt',
      recency: '>6bln',
      machineAge: '3-5th',
      hoursPerDay: '>8',
      hasBackup: false,
      loadState: 'bermuatan',
    );

    expect(context.toJson(), {
      'drive_type': 'belt',
      'recency': '>6bln',
      'machine_age': '3-5th',
      'hours_per_day': '>8',
      'has_backup': false,
      'load_state': 'bermuatan',
    });
  });

  test('nilai enum context conservativeDefault cocok dengan yang divalidasi backend', () {
    const c = AdvisoryContext.conservativeDefault;
    expect(AdvisoryOptions.driveType.containsKey(c.driveType), isTrue);
    expect(AdvisoryOptions.recency.containsKey(c.recency), isTrue);
    expect(AdvisoryOptions.machineAge.containsKey(c.machineAge), isTrue);
    expect(AdvisoryOptions.hoursPerDay.containsKey(c.hoursPerDay), isTrue);
    expect(AdvisoryOptions.loadState.containsKey(c.loadState), isTrue);
  });
}

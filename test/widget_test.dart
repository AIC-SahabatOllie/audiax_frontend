import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:audiax_frontend/app/app.dart';

void main() {
  testWidgets('Shows the landing screen when no session is stored', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AudiaxApp());
    await tester.pumpAndSettle();

    expect(find.text('Daftar'), findsOneWidget);
    expect(find.textContaining('Masuk', findRichText: true), findsOneWidget);
  });
}

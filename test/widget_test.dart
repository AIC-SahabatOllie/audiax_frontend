import 'package:flutter_test/flutter_test.dart';

import 'package:audiax_frontend/app/app.dart';

void main() {
  testWidgets('Boots the app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const AudiaxApp());

    expect(find.text('AUDIAX'), findsOneWidget);
  });
}

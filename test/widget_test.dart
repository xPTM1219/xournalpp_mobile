import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xournalpp/main.dart';

void main() {
  testWidgets('Open page smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(XournalppMobile());

    // The OpenPage app bar shows the app name.
    expect(find.text('Xournal++'), findsOneWidget);

    // The recent files section is present while it loads.
    expect(find.text('Recent files'), findsOneWidget);
  });

  testWidgets('Open page shows the new notebook action',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(XournalppMobile());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.note_add), findsWidgets);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
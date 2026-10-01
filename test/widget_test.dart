import 'package:chaos_alert/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app starts dark and shows its name', (tester) async {
    await tester.pumpWidget(const ChaosAlertApp());
    await tester.pumpAndSettle();

    expect(find.text('chaos-alert'), findsOneWidget);
    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, Brightness.dark);
  });
}

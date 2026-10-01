import 'dart:math';

import 'package:chaos_alert/l10n/app_localizations.dart';
import 'package:chaos_alert/src/controller.dart';
import 'package:chaos_alert/src/vacation_screen.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_platform.dart';

void main() {
  late MemoryStore store;
  late FakePlatform platform;
  late Controller controller;

  setUp(() {
    store = MemoryStore();
    platform = FakePlatform();
    controller = Controller(
      store: store,
      platform: platform,
      words: const ['verdict', 'venture', 'harbour', 'lantern'],
      clock: () => DateTime(2026, 10, 5, 12),
      random: Random(1),
    );
    store.saveAlarm(
      const Alarm(id: 0, time: ClockTime(6, 30), weekdays: {1, 2, 3, 4, 5}),
    );
  });

  Widget app() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: VacationScreen(controller: controller),
  );

  testWidgets('a vacation is picked as a range and moves the nag', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('No vacations planned.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '10/06/2026');
    await tester.enterText(fields.at(1), '10/09/2026');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final v = store.loadVacations().single;
    expect(v.from, DateTime(2026, 10, 6));
    expect(v.to, DateTime(2026, 10, 9));
    expect(find.text('Tue, Oct 6, 2026 – Fri, Oct 9, 2026'), findsOneWidget);
    // Mornings 6th to 9th are off; the next nag is for Monday the 12th.
    expect(platform.nag, DateTime(2026, 10, 11, 22, 30));
  });

  testWidgets('a vacation is deleted', (tester) async {
    store.saveVacation(
      Vacation(id: 0, from: DateTime(2026, 12, 21), to: DateTime(2027, 1, 1)),
    );
    await tester.pumpWidget(app());
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(store.loadVacations(), isEmpty);
    expect(find.text('No vacations planned.'), findsOneWidget);
  });
}

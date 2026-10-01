import 'dart:math';

import 'package:chaos_alert/l10n/app_localizations.dart';
import 'package:chaos_alert/src/alarm_screens.dart';
import 'package:chaos_alert/src/controller.dart';
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
  });

  Widget app() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AlarmsScreen(controller: controller),
  );

  testWidgets('a new alarm repeats on weekdays at 06:30 by default', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('No alarms yet.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final a = store.loadAlarms().single;
    expect(a.time, const ClockTime(6, 30));
    expect(a.weekdays, {1, 2, 3, 4, 5});
    expect(a.wakeUp, isTrue);
    expect(find.text('Mon Tue Wed Thu Fri'), findsOneWidget);
    expect(platform.rings, hasLength(1));
  });

  testWidgets('days are picked with chips, and none blocks saving', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    for (final d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
    expect(find.text('Pick at least one day'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(store.loadAlarms(), isEmpty);
    await tester.tap(find.text('Sat'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.loadAlarms().single.weekdays, {DateTime.saturday});
  });

  testWidgets('a one-time alarm defaults to tomorrow', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Once'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final a = store.loadAlarms().single;
    expect(a.date, DateTime(2026, 10, 6));
    expect(a.weekdays, isEmpty);
  });

  testWidgets('the wake-up switch can be turned off', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wake-up alarm'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.loadAlarms().single.wakeUp, isFalse);
    expect(find.textContaining('Reminder'), findsOneWidget);
  });

  testWidgets('the time is picked with the clock dialog', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('alarm-time')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '7');
    await tester.enterText(fields.at(1), '15');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.loadAlarms().single.time, const ClockTime(7, 15));
  });

  testWidgets('an alarm is switched off, edited and deleted from the list', (
    tester,
  ) async {
    final a = store.saveAlarm(
      const Alarm(id: 0, time: ClockTime(6, 30), weekdays: {1}),
    );
    await tester.pumpWidget(app());
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(store.loadAlarms().single.enabled, isFalse);
    expect(platform.rings, isEmpty);

    await tester.tap(find.byKey(ValueKey('alarm-${a.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tue'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.loadAlarms().single.weekdays, {1, 2});
    expect(store.loadAlarms().single.enabled, isTrue);

    await tester.tap(find.byKey(ValueKey('alarm-${a.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(store.loadAlarms(), isEmpty);
    expect(find.text('No alarms yet.'), findsOneWidget);
  });
}

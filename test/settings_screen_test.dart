import 'dart:math';

import 'package:chaos_alert/l10n/app_localizations.dart';
import 'package:chaos_alert/src/controller.dart';
import 'package:chaos_alert/src/platform.dart';
import 'package:chaos_alert/src/settings_screen.dart';
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
    home: SettingsScreen(controller: controller),
  );

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  String value(String key) =>
      (find.byKey(ValueKey('$key-value')).evaluate().single.widget as Text)
          .data!;

  testWidgets('the sleep length moves the bedtime', (tester) async {
    await tester.pumpWidget(app());
    expect(value('sleep'), '8 h 0 min');
    await tap(tester, 'sleep-more');
    expect(value('sleep'), '8 h 15 min');
    expect(
      store.loadSettings().sleepLength,
      const Duration(hours: 8, minutes: 15),
    );
    expect(platform.nag, DateTime(2026, 10, 5, 22, 15));
  });

  testWidgets('snoozes and the timeout change in minutes', (tester) async {
    await tester.pumpWidget(app());
    await tap(tester, 'nagSnooze-less');
    await tap(tester, 'alarmSnooze-more');
    await tap(tester, 'timeout-more');
    final s = store.loadSettings();
    expect(s.nagSnooze, const Duration(minutes: 5));
    expect(s.alarmSnooze, const Duration(minutes: 10));
    expect(s.alarmTimeout, const Duration(minutes: 11));
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('nagSnooze-less')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('volumes change in 5 % steps and the start stays below', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tap(tester, 'low-more');
    expect(value('low'), '25 %');
    await tap(tester, 'medium-less');
    expect(value('medium'), '45 %');
    for (var i = 0; i < 4; i++) {
      await tap(tester, 'low-more');
    }
    expect(value('low'), '45 %');
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('low-more')))
          .onPressed,
      isNull,
    );
    expect(platform.rings.single.lowVolume, 0.45);
    expect(platform.rings.single.mediumVolume, 0.45);
  });

  testWidgets('the chime can be switched off', (tester) async {
    await tester.pumpWidget(app());
    await tester.ensureVisible(find.text('Chime at bedtime'));
    await tester.tap(find.text('Chime at bedtime'));
    await tester.pumpAndSettle();
    expect(store.loadSettings().chime, isFalse);
    expect(platform.chime, isFalse);
  });

  testWidgets('without music access a hint offers to allow it', (tester) async {
    platform.granted[Permission.music] = false;
    await controller.refresh();
    await tester.pumpWidget(app());
    expect(find.text('Songs are left out'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(platform.requested, [Permission.music]);
    expect(find.text('Songs are left out'), findsNothing);
  });
}

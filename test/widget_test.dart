import 'dart:math';

import 'package:chaos_alert/src/app.dart';
import 'package:chaos_alert/src/controller.dart';
import 'package:chaos_alert/src/platform.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_platform.dart';

void main() {
  late MemoryStore store;
  late FakePlatform platform;
  var now = DateTime(2026, 10, 5, 12);

  Controller controller() => Controller(
    store: store,
    platform: platform,
    words: const ['verdict', 'venture', 'harbour', 'lantern', 'quarrel'],
    clock: () => now,
    random: Random(1),
  );

  setUp(() {
    now = DateTime(2026, 10, 5, 12);
    store = MemoryStore();
    platform = FakePlatform();
    store.saveAlarm(
      const Alarm(id: 0, time: ClockTime(6, 30), weekdays: {1, 2, 3, 4, 5}),
    );
  });

  void setupDone() => store.saveState(store.loadState()..setupDone = true);

  testWidgets('the app is dark and shows the next alarm and bedtime', (
    tester,
  ) async {
    setupDone();
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, Brightness.dark);
    expect(find.text('Next alarm Tue 6:30 AM'), findsOneWidget);
    expect(find.text('Bedtime Mon 10:30 PM'), findsOneWidget);
    expect(find.text("I'm in bed"), findsNothing);
  });

  testWidgets('the first start walks through every permission', (tester) async {
    platform.granted[Permission.exactAlarms] = false;
    final c = controller();
    await tester.pumpWidget(ChaosAlertApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Exact alarms'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(platform.requested, [Permission.exactAlarms]);
    expect(find.text('Allowed'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Step 5 of 5'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(c.setupDone, isTrue);
    expect(find.text('chaos-alert'), findsOneWidget);
  });

  testWidgets('a missing permission shows a red banner leading to setup', (
    tester,
  ) async {
    setupDone();
    platform.granted[Permission.fullScreen] = false;
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    expect(
      find.text('Alarms may not ring: a permission is missing.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Fix'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 5'), findsOneWidget);
  });

  testWidgets('"I\'m in bed" appears three hours before bedtime', (
    tester,
  ) async {
    setupDone();
    now = DateTime(2026, 10, 5, 19, 30);
    final c = controller();
    await tester.pumpWidget(ChaosAlertApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm in bed"));
    await tester.pumpAndSettle();
    expect(find.text('Remember this word:'), findsOneWidget);
    await tester.tap(find.text('Good night'));
    await tester.pumpAndSettle();
    expect(find.text("I'm in bed"), findsNothing);
    expect(find.text('Bedtime Tue 10:30 PM'), findsOneWidget);
  });

  testWidgets('the button shows up as the window opens', (tester) async {
    setupDone();
    now = DateTime(2026, 10, 5, 19, 29);
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    expect(find.text("I'm in bed"), findsNothing);
    now = DateTime(2026, 10, 5, 19, 30);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text("I'm in bed"), findsOneWidget);
  });

  testWidgets('Android opening the app for the nag shows the nag', (
    tester,
  ) async {
    setupDone();
    platform.initial = const NagLaunch();
    now = DateTime(2026, 10, 5, 22, 30);
    platform.events.add(NagFired(now));
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    expect(find.text('Are you in bed?'), findsOneWidget);
  });

  testWidgets('a ring while the app runs shows the alarm', (tester) async {
    setupDone();
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    now = DateTime(2026, 10, 6, 6, 30);
    platform.events.add(RingStarted(1, now));
    platform.launch(const RingLaunch(1));
    await tester.pumpAndSettle();
    expect(find.text('Turn off'), findsOneWidget);
  });
}

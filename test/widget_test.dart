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

  testWidgets('a hint whose page never came shows once on the main screen', (
    tester,
  ) async {
    setupDone();
    store.saveState(store.loadState()..pendingHint = true);
    final c = controller();
    await tester.pumpWidget(ChaosAlertApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.textContaining('talking to a doctor'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('talking to a doctor'), findsNothing);
    expect(store.loadState().pendingHint, isFalse);
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

  testWidgets('"I\'m in bed" gives no word; the word comes from its own '
      'button', (tester) async {
    setupDone();
    now = DateTime(2026, 10, 5, 16, 30);
    final c = controller();
    await tester.pumpWidget(ChaosAlertApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Show the word'), findsNothing);
    await tester.tap(find.text("I'm in bed"));
    await tester.pumpAndSettle();
    expect(find.text('Remember this word:'), findsNothing);
    expect(find.text("I'm in bed"), findsNothing);
    // The nag still comes at the planned bedtime.
    expect(find.text('Bedtime Mon 10:30 PM'), findsOneWidget);
    await tester.tap(find.text('Show the word'));
    await tester.pumpAndSettle();
    expect(find.text('Remember this word:'), findsOneWidget);
    await tester.tap(find.text('Good night'));
    await tester.pumpAndSettle();
    expect(find.text('Show the word'), findsNothing);
    expect(find.text('Bedtime Tue 10:30 PM'), findsOneWidget);
  });

  testWidgets('once in bed, the nag asks for the word', (tester) async {
    setupDone();
    now = DateTime(2026, 10, 5, 21);
    final c = controller();
    await c.inBed();
    platform.initial = const NagLaunch();
    now = DateTime(2026, 10, 5, 22, 30);
    platform.events.add(NagFired(now));
    await tester.pumpWidget(ChaosAlertApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Want the word now?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.text('Remember this word:'), findsOneWidget);
  });

  testWidgets('"I\'m awake" shows up six hours before the alarm', (
    tester,
  ) async {
    setupDone();
    now = DateTime(2026, 10, 6, 0, 29);
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    expect(find.text("I'm awake"), findsNothing);
    now = DateTime(2026, 10, 6, 0, 30);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text("I'm awake"), findsOneWidget);
    await tester.tap(find.text("I'm awake"));
    await tester.pumpAndSettle();
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('the button shows up as the window opens', (tester) async {
    setupDone();
    now = DateTime(2026, 10, 5, 16, 29);
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    expect(find.text("I'm in bed"), findsNothing);
    now = DateTime(2026, 10, 5, 16, 30);
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

  testWidgets('a nag that fires after the morning started shows nothing', (
    tester,
  ) async {
    setupDone();
    platform.initial = const NagLaunch();
    now = DateTime(2026, 10, 6, 6, 31);
    platform.events.add(NagFired(now));
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    expect(find.text('Are you in bed?'), findsNothing);
    expect(find.text("I'm in bed"), findsNothing);
  });

  testWidgets("the evening's unanswered nag is gone under the morning alarm", (
    tester,
  ) async {
    setupDone();
    platform.initial = const NagLaunch();
    now = DateTime(2026, 10, 5, 22, 30);
    platform.events.add(NagFired(now));
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    expect(find.text('Are you in bed?'), findsOneWidget);
    expect(platform.nagCleared, 0);
    // Android fires the ring a moment after its time.
    now = DateTime(2026, 10, 6, 6, 30, 1);
    platform.events.add(RingStarted(1, now));
    platform.launch(const RingLaunch(1));
    await tester.pumpAndSettle();
    expect(find.text('Are you in bed?', skipOffstage: false), findsNothing);
    expect(platform.nagCleared, greaterThan(0));
    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();
    expect(find.text('Are you in bed?'), findsNothing);
  });

  testWidgets('a second nag takes the place of the open one', (tester) async {
    setupDone();
    platform.initial = const NagLaunch();
    now = DateTime(2026, 10, 5, 22, 30);
    platform.events.add(NagFired(now));
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    now = DateTime(2026, 10, 5, 22, 40);
    platform.events.add(NagFired(now));
    platform.launch(const NagLaunch());
    await tester.pumpAndSettle();
    expect(find.text('Are you in bed?', skipOffstage: false), findsOneWidget);
    await tester.tap(find.text('Snooze 10 min'));
    await tester.pumpAndSettle();
    expect(find.text('Are you in bed?', skipOffstage: false), findsNothing);
  });

  testWidgets('Yes on the nag still shows the word', (tester) async {
    setupDone();
    platform.initial = const NagLaunch();
    now = DateTime(2026, 10, 5, 22, 30);
    platform.events.add(NagFired(now));
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.text('Are you in bed?', skipOffstage: false), findsNothing);
    expect(find.text('Remember this word:'), findsOneWidget);
  });

  testWidgets('a snooze from the notification closes the alarm screen', (
    tester,
  ) async {
    setupDone();
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    now = DateTime(2026, 10, 6, 6, 30);
    platform.events.add(RingStarted(1, now));
    platform.launch(const RingLaunch(1));
    await tester.pumpAndSettle();
    expect(find.text('Turn off'), findsOneWidget);
    platform.arrive(RingSnoozed(1, now));
    await tester.pumpAndSettle();
    expect(find.text('Turn off'), findsNothing);
  });

  testWidgets('the awake notice opens I am awake', (tester) async {
    setupDone();
    platform.initial = const AwakeLaunch();
    now = DateTime(2026, 10, 6, 5, 45);
    await tester.pumpWidget(ChaosAlertApp(controller: controller()));
    await tester.pumpAndSettle();
    expect(find.text('Back'), findsOneWidget);
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

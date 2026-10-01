import 'dart:math';

import 'package:chaos_alert/l10n/app_localizations.dart';
import 'package:chaos_alert/src/controller.dart';
import 'package:chaos_alert/src/timeline_screen.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_platform.dart';

NightRecord night(DateTime morning, {int bedHour = 23, bool assumed = false}) =>
    NightRecord(
      plannedBedtime: DateTime(
        morning.year,
        morning.month,
        morning.day - 1,
        22,
        30,
      ),
      bedtime: DateTime(morning.year, morning.month, morning.day - 1, bedHour),
      bedtimeAssumed: assumed,
      end: DateTime(morning.year, morning.month, morning.day, 7),
      result: NightResult.success,
    );

void main() {
  late MemoryStore store;
  late Controller controller;

  setUp(() {
    store = MemoryStore();
    controller = Controller(
      store: store,
      platform: FakePlatform(),
      words: const ['verdict', 'venture', 'harbour', 'lantern'],
      // Thursday 8 October 2026.
      clock: () => DateTime(2026, 10, 8, 12),
      random: Random(1),
    );
  });

  Widget app() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: TimelineScreen(controller: controller),
  );

  NightRecord? recordOf(WidgetTester tester, int month, int day) => tester
      .widget<NightBar>(find.byKey(ValueKey('night-2026-$month-$day')))
      .record;

  test('the axis runs from 20:00 to noon', () {
    final morning = DateTime(2026, 10, 6);
    expect(axisPosition(morning, DateTime(2026, 10, 5, 20)), 0);
    expect(axisPosition(morning, DateTime(2026, 10, 6, 4)), 0.5);
    expect(axisPosition(morning, DateTime(2026, 10, 6, 12)), 1);
    expect(axisPosition(morning, DateTime(2026, 10, 5, 18)), 0);
  });

  testWidgets('the week shows seven rows with this week\'s nights', (
    tester,
  ) async {
    store
      ..addRecord(night(DateTime(2026, 10, 6)))
      ..addRecord(night(DateTime(2026, 10, 7), bedHour: 1 + 24, assumed: true))
      ..addRecord(night(DateTime(2026, 10, 1)));
    await tester.pumpWidget(app());
    expect(find.byType(NightBar), findsNWidgets(7));
    expect(recordOf(tester, 10, 5), isNull);
    expect(recordOf(tester, 10, 6), isNotNull);
    expect(recordOf(tester, 10, 7)!.bedtimeAssumed, isTrue);
    expect(find.text('Oct 5 – Oct 11, 2026'), findsOneWidget);
    // 8 h and 6 h in bed; bedtimes 23:00 and 01:00.
    expect(find.text('Average in bed: 7 h 0 min'), findsOneWidget);
    expect(find.text('Average bedtime: 12:00 AM'), findsOneWidget);
  });

  testWidgets('earlier weeks are one tap away', (tester) async {
    store.addRecord(night(DateTime(2026, 10, 1)));
    await tester.pumpWidget(app());
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('Sep 28 – Oct 4, 2026'), findsOneWidget);
    expect(recordOf(tester, 10, 1), isNotNull);
  });

  testWidgets('the month shows a row per day', (tester) async {
    store
      ..addRecord(night(DateTime(2026, 10, 1)))
      ..addRecord(night(DateTime(2026, 10, 6)));
    await tester.pumpWidget(app());
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.byType(NightBar, skipOffstage: false), findsNWidgets(31));
    expect(find.text('Average in bed: 8 h 0 min'), findsOneWidget);
  });

  testWidgets('an empty period says so', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('No nights in this period.'), findsOneWidget);
  });
}

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

  /// Shows the timeline over what the store holds now.
  Future<void> pumpApp(WidgetTester tester) async {
    await controller.reschedule();
    await tester.pumpWidget(app());
  }

  NightRecord? recordOf(WidgetTester tester, int month, int day) => tester
      .widget<NightBar>(find.byKey(ValueKey('night-2026-$month-$day')))
      .record;

  group('axis', () {
    NightRecord sleep(DateTime bed, DateTime end, {DateTime? planned}) =>
        NightRecord(
          plannedBedtime: planned ?? bed,
          bedtime: bed,
          bedtimeAssumed: false,
          end: end,
          result: NightResult.success,
        );

    test('without nights it runs from 20:00 to noon', () {
      final axis = TimeAxis.fit(const []);
      final morning = DateTime(2026, 10, 6);
      expect(axis.position(morning, DateTime(2026, 10, 5, 20)), 0);
      expect(axis.position(morning, DateTime(2026, 10, 6, 4)), 0.5);
      expect(axis.position(morning, DateTime(2026, 10, 6, 12)), 1);
      expect(axis.labels.first, const ClockTime(20, 0));
      expect(axis.labels.last, const ClockTime(12, 0));
    });

    test('runs exactly from the earliest bedtime to the latest end', () {
      final axis = TimeAxis.fit([
        sleep(DateTime(2026, 10, 5, 23, 10), DateTime(2026, 10, 6, 6, 40)),
        sleep(DateTime(2026, 10, 7, 0, 20), DateTime(2026, 10, 7, 7, 10)),
      ]);
      expect(axis.labels, const [ClockTime(23, 10), ClockTime(7, 10)]);
      final morning = DateTime(2026, 10, 6);
      expect(axis.position(morning, DateTime(2026, 10, 5, 23, 10)), 0);
      expect(axis.position(morning, DateTime(2026, 10, 6, 3, 10)), 0.5);
      expect(axis.position(morning, DateTime(2026, 10, 6, 7, 10)), 1);
    });

    test('a single night fills the whole width', () {
      final axis = TimeAxis.fit([
        sleep(DateTime(2026, 10, 5, 22, 45), DateTime(2026, 10, 6, 6, 15)),
      ]);
      expect(axis.labels, const [ClockTime(22, 45), ClockTime(6, 15)]);
    });

    test('the reference lines mark the latest bedtime and the earliest '
        'end', () {
      final axis = TimeAxis.fit([
        sleep(DateTime(2026, 10, 5, 23, 10), DateTime(2026, 10, 6, 6, 40)),
        sleep(DateTime(2026, 10, 7, 0, 20), DateTime(2026, 10, 7, 7, 10)),
      ]);
      // 00:20 and 06:40, counted from the morning's midnight.
      expect(axis.references, const [20, 400]);
      expect(TimeAxis.fit(const []).references, isEmpty);
    });

    test('an earlier planned bedtime widens the window', () {
      final axis = TimeAxis.fit([
        sleep(
          DateTime(2026, 10, 6, 1),
          DateTime(2026, 10, 6, 7),
          planned: DateTime(2026, 10, 5, 22, 30),
        ),
      ]);
      expect(axis.labels.first, const ClockTime(22, 30));
      // The reference stays at the real bedtime.
      expect(axis.references.first, 60);
    });

    test('day sleepers get a daytime window', () {
      final axis = TimeAxis.fit([
        sleep(DateTime(2026, 10, 6, 8), DateTime(2026, 10, 6, 16)),
        sleep(DateTime(2026, 10, 7, 9), DateTime(2026, 10, 7, 15, 30)),
      ]);
      expect(axis.labels, const [ClockTime(8, 0), ClockTime(16, 0)]);
      final morning = DateTime(2026, 10, 6);
      expect(axis.position(morning, DateTime(2026, 10, 6, 12)), 0.5);
    });

    test('is never wider than a day', () {
      final axis = TimeAxis.fit([
        sleep(DateTime(2026, 10, 5, 14), DateTime(2026, 10, 6, 7)),
        sleep(DateTime(2026, 10, 7, 2), DateTime(2026, 10, 7, 21)),
      ]);
      expect(axis.minutes, 24 * 60);
      expect(axis.labels, const [ClockTime(14, 0), ClockTime(14, 0)]);
      final morning = DateTime(2026, 10, 7);
      expect(axis.position(morning, DateTime(2026, 10, 7, 21)), 1);
    });
  });

  testWidgets('the top line shows only the start and the end', (tester) async {
    store.addRecord(
      NightRecord(
        plannedBedtime: DateTime(2026, 10, 5, 22, 50),
        bedtime: DateTime(2026, 10, 5, 22, 50),
        bedtimeAssumed: false,
        end: DateTime(2026, 10, 6, 6, 35),
        result: NightResult.success,
      ),
    );
    await pumpApp(tester);
    expect(find.text('10:50 PM'), findsOneWidget);
    expect(find.text('6:35 AM'), findsOneWidget);
    expect(find.textContaining(':00 '), findsNothing);
  });

  testWidgets('the week shows seven rows with this week\'s nights', (
    tester,
  ) async {
    store
      ..addRecord(night(DateTime(2026, 10, 6)))
      ..addRecord(night(DateTime(2026, 10, 7), bedHour: 1 + 24, assumed: true))
      ..addRecord(night(DateTime(2026, 10, 1)));
    await pumpApp(tester);
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
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('Sep 28 – Oct 4, 2026'), findsOneWidget);
    expect(recordOf(tester, 10, 1), isNotNull);
  });

  testWidgets('the month shows a row per day', (tester) async {
    store
      ..addRecord(night(DateTime(2026, 10, 1)))
      ..addRecord(night(DateTime(2026, 10, 6)));
    await pumpApp(tester);
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.byType(NightBar, skipOffstage: false), findsNWidgets(31));
    expect(find.text('Average in bed: 8 h 0 min'), findsOneWidget);
  });

  testWidgets('an empty period says so', (tester) async {
    await pumpApp(tester);
    expect(find.text('No nights in this period.'), findsOneWidget);
  });
}

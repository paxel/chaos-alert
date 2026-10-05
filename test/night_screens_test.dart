import 'dart:math';

import 'package:chaos_alert/l10n/app_localizations.dart';
import 'package:chaos_alert/src/controller.dart';
import 'package:chaos_alert/src/night_screens.dart';
import 'package:chaos_alert/src/platform.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_platform.dart';

const words = ['verdict', 'venture', 'harbour', 'lantern', 'quarrel'];

/// A daily 06:30 wake-up alarm, the clock at Monday 22:30.
class Setup {
  Setup() {
    controller = Controller(
      store: store,
      platform: platform,
      words: words,
      nagLines: const ['The pillow misses you.'],
      clock: () => now,
      random: Random(1),
    );
    alarm = store.saveAlarm(
      const Alarm(
        id: 0,
        time: ClockTime(6, 30),
        weekdays: {1, 2, 3, 4, 5, 6, 7},
      ),
    );
  }

  final store = MemoryStore();
  final platform = FakePlatform();
  late final Controller controller;
  late final Alarm alarm;
  DateTime now = DateTime(2026, 10, 5, 22, 30);

  /// [screen] pushed over an empty home, so popping it is visible.
  Widget app(Widget screen) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => screen)),
            child: const Text('home'),
          ),
        ),
      ),
    ),
  );

  /// Opens [screen] the way the app does: Android queued the nag or the
  /// ring, the app reads the queue, then shows it.
  Future<void> open(WidgetTester tester, Widget screen) async {
    if (screen is NagScreen) platform.events.add(NagFired(now));
    if (screen is AlarmScreen) {
      platform.events.add(RingStarted(screen.alarmId, now));
    }
    await controller.refresh();
    await tester.pumpWidget(app(screen));
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('nag', () {
    testWidgets('Yes shows the word once and closes to home', (tester) async {
      final s = Setup();
      await s.open(tester, NagScreen(controller: s.controller));
      expect(find.text('The pillow misses you.'), findsOneWidget);
      expect(find.text('Are you in bed?'), findsOneWidget);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      final word = words.firstWhere((w) => find.text(w).evaluate().isNotEmpty);
      expect(s.store.loadState().night!.word, word);
      await tester.tap(find.text('Good night'));
      await tester.pumpAndSettle();
      expect(find.text(word), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('the default snooze uses the setting', (tester) async {
      final s = Setup();
      await s.controller.saveSettings(
        const Settings(nagSnooze: Duration(minutes: 15)),
      );
      await s.open(tester, NagScreen(controller: s.controller));
      await tester.tap(find.text('Snooze 15 min'));
      await tester.pumpAndSettle();
      expect(s.platform.nag, DateTime(2026, 10, 5, 22, 45));
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('a longer snooze is one tap', (tester) async {
      final s = Setup();
      await s.open(tester, NagScreen(controller: s.controller));
      await tester.tap(find.text('2 h'));
      await tester.pumpAndSettle();
      expect(s.platform.nag, DateTime(2026, 10, 6, 0, 30));
    });

    testWidgets('Yes on a nag left over after the bedtime was given closes '
        'without a new word', (tester) async {
      final s = Setup();
      final word = (await s.controller.inBed())!;
      await s.open(tester, NagScreen(controller: s.controller));
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(s.store.loadState().night!.word, word);
    });

    testWidgets("Android's nag event records the nag time", (tester) async {
      final s = Setup();
      await s.open(tester, NagScreen(controller: s.controller));
      expect(s.store.loadState().night!.lastNag, s.now);
    });
  });

  group('alarm', () {
    Future<String> sayInBed(Setup s) async {
      final word = (await s.controller.inBed())!;
      s.now = DateTime(2026, 10, 6, 6, 30);
      return word;
    }

    testWidgets('a snooze from the notification closes it, and its timeout '
        'leaves the snooze alone', (tester) async {
      final s = Setup();
      await sayInBed(s);
      await s.open(
        tester,
        AlarmScreen(controller: s.controller, alarmId: s.alarm.id),
      );
      s.now = DateTime(2026, 10, 6, 6, 31);
      s.platform.events.add(RingSnoozed(s.alarm.id, s.now));
      await s.controller.refresh();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      await tester.pump(const Duration(minutes: 11));
      expect(
        s.controller.alarmSnoozes[s.alarm.id],
        DateTime(2026, 10, 6, 6, 40),
      );
    });

    testWidgets('the right word closes it', (tester) async {
      final s = Setup();
      final word = await sayInBed(s);
      await s.open(
        tester,
        AlarmScreen(controller: s.controller, alarmId: s.alarm.id),
      );
      expect(find.text('Which word did you see last night?'), findsOneWidget);
      await tester.tap(find.text(word));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(s.store.loadRecords().single.result, NightResult.success);
      expect(s.platform.stops, 1);
    });

    /// Marks [word] and confirms it with OK.
    Future<void> pick(WidgetTester tester, String word) async {
      await tester.tap(find.text(word));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pump();
    }

    testWidgets('a wrong word says so, snoozes and keeps the word hidden', (
      tester,
    ) async {
      final s = Setup();
      final word = await sayInBed(s);
      await s.open(
        tester,
        AlarmScreen(controller: s.controller, alarmId: s.alarm.id),
      );
      final wrong = words.firstWhere(
        (w) => w != word && find.text(w).evaluate().isNotEmpty,
      );
      await pick(tester, wrong);
      expect(
        find.text('Not this one.\nThe alarm rings again in 9 min.'),
        findsOneWidget,
      );
      expect(find.text(word), findsNothing);
      expect(s.platform.stops, 1);
      expect(s.platform.rings.first.at, DateTime(2026, 10, 6, 6, 39));
      expect(s.store.loadRecords(), isEmpty);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('the next ring leaves the wrong word out; the right one '
        'then shows the tries, the streak and the strip', (tester) async {
      final s = Setup();
      final word = await sayInBed(s);
      await s.open(
        tester,
        AlarmScreen(controller: s.controller, alarmId: s.alarm.id),
      );
      final wrong = words.firstWhere(
        (w) => w != word && find.text(w).evaluate().isNotEmpty,
      );
      await pick(tester, wrong);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      s.now = DateTime(2026, 10, 6, 6, 39);
      await s.open(
        tester,
        AlarmScreen(controller: s.controller, alarmId: s.alarm.id),
      );
      expect(find.text(wrong), findsNothing);
      await pick(tester, word);
      await tester.pumpAndSettle();
      expect(find.text('Found on try 2'), findsOneWidget);
      expect(find.text(word), findsOneWidget);
      expect(find.text('1 miss in a row'), findsOneWidget);
      expect(find.text('0 right, 1 wrong in total'), findsOneWidget);
      expect(find.byKey(const ValueKey('strip-failure-1')), findsOneWidget);
      expect(s.store.loadRecords().single.wrongPicks, 1);
    });

    testWidgets('a tap only marks a word; OK answers, and a misclick can '
        'be fixed first', (tester) async {
      final s = Setup();
      final word = await sayInBed(s);
      await s.open(
        tester,
        AlarmScreen(controller: s.controller, alarmId: s.alarm.id),
      );
      final ok = find.widgetWithText(FilledButton, 'OK');
      expect(tester.widget<FilledButton>(ok).onPressed, isNull);

      final wrong = words.firstWhere(
        (w) => w != word && find.text(w).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(wrong));
      await tester.pump();
      expect(find.byKey(ValueKey('picked-$wrong')), findsOneWidget);
      expect(s.store.loadRecords(), isEmpty);
      expect(s.platform.stops, 0);

      await tester.tap(find.text(word));
      await tester.pump();
      expect(find.byKey(ValueKey('picked-$word')), findsOneWidget);
      expect(find.byKey(ValueKey('picked-$wrong')), findsNothing);

      await tester.tap(ok);
      await tester.pumpAndSettle();
      expect(s.store.loadRecords().single.result, NightResult.success);
    });

    testWidgets('the words have room between them', (tester) async {
      final s = Setup();
      await sayInBed(s);
      await s.open(
        tester,
        AlarmScreen(controller: s.controller, alarmId: s.alarm.id),
      );
      final shown = words.where((w) => find.text(w).evaluate().isNotEmpty);
      final rects = [
        for (final w in shown)
          tester.getRect(
            find.ancestor(
              of: find.text(w),
              matching: find.bySubtype<ButtonStyleButton>(),
            ),
          ),
      ]..sort((a, b) => a.top.compareTo(b.top));
      expect(rects, hasLength(4));
      for (var i = 0; i < 3; i++) {
        expect(rects[i].height, greaterThanOrEqualTo(64));
        expect(rects[i + 1].top - rects[i].bottom, greaterThanOrEqualTo(20));
      }
    });

    testWidgets('without a word it offers a plain turn-off', (tester) async {
      final s = Setup();
      s.controller.engine.nagShown();
      s.now = DateTime(2026, 10, 6, 6, 30);
      await s.open(
        tester,
        AlarmScreen(controller: s.controller, alarmId: s.alarm.id),
      );
      expect(find.text('Which word did you see last night?'), findsNothing);
      await tester.tap(find.text('Turn off'));
      await tester.pumpAndSettle();
      expect(s.store.loadRecords().single.result, NightResult.noWord);
    });

    testWidgets('snooze closes it and rings again later', (tester) async {
      final s = Setup();
      await sayInBed(s);
      await s.open(
        tester,
        AlarmScreen(controller: s.controller, alarmId: s.alarm.id),
      );
      await tester.tap(find.text('Snooze'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(s.platform.rings.first.at, DateTime(2026, 10, 6, 6, 39));
      expect(s.store.loadRecords(), isEmpty);
    });

    testWidgets('unanswered, it times out and the night is missed', (
      tester,
    ) async {
      final s = Setup();
      await sayInBed(s);
      await s.open(
        tester,
        AlarmScreen(controller: s.controller, alarmId: s.alarm.id),
      );
      await tester.pump(const Duration(minutes: 10));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(s.store.loadRecords().single.result, NightResult.missed);
    });
  });

  group("I'm awake", () {
    /// In bed Monday 22:30, awake Tuesday 05:50 — inside the window.
    Future<String> awakeMorning(Setup s) async {
      final word = (await s.controller.inBed())!;
      s.now = DateTime(2026, 10, 6, 5, 50);
      await s.controller.reschedule();
      return word;
    }

    testWidgets('the right word ends the night and cancels the alarm', (
      tester,
    ) async {
      final s = Setup();
      final word = await awakeMorning(s);
      await s.open(tester, AwakeScreen(controller: s.controller));
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Snooze'), findsNothing);
      await tester.tap(find.text(word));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(s.store.loadRecords().single.result, NightResult.success);
      expect(
        s.platform.rings.where((r) => r.at == DateTime(2026, 10, 6, 6, 30)),
        isEmpty,
      );
    });

    testWidgets('a wrong word says so and the quiz goes on without it', (
      tester,
    ) async {
      final s = Setup();
      final word = await awakeMorning(s);
      await s.open(tester, AwakeScreen(controller: s.controller));
      final wrong = words.firstWhere(
        (w) => w != word && find.text(w).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(wrong));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pump();
      expect(find.text('Not this one.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text(wrong), findsNothing);
      expect(find.text(word), findsOneWidget);
      await tester.tap(find.text(word));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Found on try 2'), findsOneWidget);
    });

    testWidgets('Back changes nothing; the alarm still rings', (tester) async {
      final s = Setup();
      await awakeMorning(s);
      await s.open(tester, AwakeScreen(controller: s.controller));
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(s.store.loadRecords(), isEmpty);
      expect(s.platform.rings.first.at, DateTime(2026, 10, 6, 6, 30));
    });

    testWidgets('without a word it is a plain turn-off', (tester) async {
      final s = Setup();
      s.controller.engine.nagShown();
      s.now = DateTime(2026, 10, 6, 5, 50);
      await s.open(tester, AwakeScreen(controller: s.controller));
      expect(find.text('Which word did you see last night?'), findsNothing);
      await tester.tap(find.text('Turn off'));
      await tester.pumpAndSettle();
      expect(s.store.loadRecords().single.result, NightResult.noWord);
    });
  });

  testWidgets('the fifth miss in a row shows the hint', (tester) async {
    final s = Setup();
    final failures = [
      for (var i = 0; i < 5; i++)
        NightRecord(
          plannedBedtime: DateTime(2026, 9, 1 + i, 22),
          bedtime: DateTime(2026, 9, 1 + i, 22),
          bedtimeAssumed: false,
          end: DateTime(2026, 9, 2 + i, 6),
          result: NightResult.failure,
          wrongPicks: 1 + i % 3,
        ),
    ];
    await s.open(
      tester,
      SummaryScreen(
        outcome: QuizOutcome.right(
          wrongPicks: 3,
          word: 'verdict',
          stats: QuizStats.of(failures),
        ),
      ),
    );
    expect(find.text('Found on try 4'), findsOneWidget);
    expect(find.text('5 misses in a row'), findsOneWidget);
    expect(find.textContaining('poor sleep alone'), findsOneWidget);
    expect(find.textContaining('talking to a doctor'), findsOneWidget);
    for (final n in [1, 2, 3]) {
      expect(find.byKey(ValueKey('strip-failure-$n')), findsWidgets);
    }
  });
}

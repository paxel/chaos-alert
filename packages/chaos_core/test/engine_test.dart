import 'dart:math';

import 'package:chaos_core/chaos_core.dart';
import 'package:test/test.dart';

const weekdays = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
};

const words = [
  'verdict',
  'venture',
  'harbour',
  'lantern',
  'quarrel',
  'nimbus',
  'ember',
  'tundra',
];

/// October 2026; the 5th is a Monday.
DateTime at(int day, int h, [int m = 0]) => DateTime(2026, 10, day, h, m);

/// An engine over a memory store whose clock the test moves.
class Night {
  Night() {
    engine = Engine(
      store: store,
      words: words,
      clock: () => now,
      random: Random(1),
    );
  }

  final store = MemoryStore();
  late final Engine engine;
  DateTime now = at(5, 12);

  Alarm alarm(
    int h,
    int m, {
    Set<int> days = weekdays,
    DateTime? date,
    bool wakeUp = true,
  }) => store.saveAlarm(
    Alarm(
      id: 0,
      time: ClockTime(h, m),
      weekdays: date == null ? days : const {},
      date: date,
      wakeUp: wakeUp,
    ),
  );

  NightRecord get last => store.loadRecords().last;

  /// The alarm rings now; returns what its screen shows.
  RingScreen ring(int alarmId) {
    engine.ring(alarmId);
    return engine.screenFor(alarmId);
  }

  /// The quiz option that is not [word].
  String wrong(RingScreen screen, String word) =>
      screen.options.firstWhere((o) => o != word);
}

void main() {
  late Night n;
  setUp(() => n = Night());

  group('nag', () {
    test('is planned at the bedtime of the next wake-up morning', () {
      n.alarm(6, 30);
      expect(n.engine.plan().nextNag, at(5, 22, 30));
    });

    test('is not planned without a wake-up alarm', () {
      n.alarm(6, 30, wakeUp: false);
      expect(n.engine.plan().nextNag, isNull);
    });

    test('is not planned again tonight once it was shown and not answered', () {
      n.alarm(6, 30);
      n.now = at(5, 22, 30);
      n.engine.nagShown();
      expect(n.engine.plan().nextNag, at(6, 22, 30));
    });

    test('comes back after a snooze', () {
      n.alarm(6, 30);
      n.now = at(5, 22, 30);
      n.engine.nagShown();
      n.engine.snoozeNag(const Duration(hours: 2));
      expect(n.engine.plan().nextNag, at(6, 0, 30));
    });

    test('a snooze past the alarm drops tonight\'s nag', () {
      n.alarm(6, 30);
      n.now = at(6, 4);
      n.engine.nagShown();
      n.engine.snoozeNag(const Duration(hours: 3));
      expect(n.engine.plan().nextNag, at(6, 22, 30));
    });

    test('stops for tonight once the user is in bed', () {
      n.alarm(6, 30);
      n.now = at(5, 22, 30);
      n.engine.nagShown();
      n.engine.inBed();
      expect(n.engine.plan().nextNag, at(6, 22, 30));
    });

    test('a past bedtime with no night yet nags right away', () {
      n.now = at(5, 23);
      n.alarm(6, 30);
      expect(n.engine.plan().nextNag!.isAfter(n.now), isFalse);
    });
  });

  group('in bed', () {
    test('shows a word from the list', () {
      n.alarm(6, 30);
      n.now = at(5, 22, 30);
      expect(words, contains(n.engine.inBed()));
    });

    test('the button appears three hours before bedtime', () {
      n.alarm(6, 30);
      n.now = at(5, 19, 29);
      expect(n.engine.canSayInBed, isFalse);
      n.now = at(5, 19, 30);
      expect(n.engine.canSayInBed, isTrue);
    });

    test('the button is gone once the user said so', () {
      n.alarm(6, 30);
      n.now = at(5, 21);
      n.engine.inBed();
      expect(n.engine.canSayInBed, isFalse);
    });

    test('the button stays while an unanswered nag is open', () {
      n.alarm(6, 30);
      n.now = at(5, 22, 30);
      n.engine.nagShown();
      n.now = at(5, 23);
      expect(n.engine.canSayInBed, isTrue);
    });

    test('early in bed cancels the evening nag', () {
      n.alarm(6, 30);
      n.now = at(5, 21, 45);
      n.engine.inBed();
      expect(n.engine.plan().nextNag, at(6, 22, 30));
    });

    test('a word is never repeated before the list is used up', () {
      final a = n.alarm(6, 30, days: {1, 2, 3, 4, 5, 6, 7});
      final seen = <String>[];
      for (var i = 0; i < words.length; i++) {
        n.now = at(5 + i, 22, 30);
        seen.add(n.engine.inBed());
        n.now = at(6 + i, 6, 30);
        expect(n.ring(a.id).quiz, isTrue);
        n.engine.answer(a.id, seen.last);
      }
      expect(seen.toSet(), hasLength(words.length));
    });
  });

  group('alarm', () {
    test('quizzes on the first wake-up alarm when a word was shown', () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      final word = n.engine.inBed();
      n.now = at(6, 6, 30);
      final screen = n.ring(a.id);
      expect(screen.quiz, isTrue);
      expect(screen.options, hasLength(4));
      expect(screen.options, contains(word));
    });

    test('the right word stops it and records a success', () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      final word = n.engine.inBed();
      n.now = at(6, 6, 30);
      n.ring(a.id);
      n.now = at(6, 6, 31);
      final outcome = n.engine.answer(a.id, word)!;
      expect(outcome.correct, isTrue);
      expect(n.last.result, NightResult.success);
      expect(n.last.bedtime, at(5, 22, 30));
      expect(n.last.bedtimeAssumed, isFalse);
      expect(n.last.plannedBedtime, at(5, 22, 30));
      expect(n.last.end, at(6, 6, 31));
    });

    test('a wrong word stops it too and records a failure', () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      final word = n.engine.inBed();
      n.now = at(6, 6, 30);
      final screen = n.ring(a.id);
      final outcome = n.engine.answer(a.id, n.wrong(screen, word))!;
      expect(outcome.correct, isFalse);
      expect(outcome.word, word);
      expect(outcome.stats.streak, 1);
      expect(n.last.result, NightResult.failure);
      expect(n.engine.plan().nextNag, at(6, 22, 30));
    });

    test('without a word the alarm gets a plain dismiss and the night '
        'counts as no word with the last nag as bedtime', () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      n.engine.nagShown();
      n.engine.snoozeNag(const Duration(minutes: 10));
      n.now = at(5, 22, 40);
      n.engine.nagShown();
      n.now = at(6, 6, 30);
      final screen = n.ring(a.id);
      expect(screen.quiz, isFalse);
      n.engine.dismiss(a.id);
      expect(n.last.result, NightResult.noWord);
      expect(n.last.bedtime, at(5, 22, 40));
      expect(n.last.bedtimeAssumed, isTrue);
    });

    test('snoozing keeps the quiz for the next ring', () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      final word = n.engine.inBed();
      n.now = at(6, 6, 30);
      n.ring(a.id);
      n.engine.snoozeAlarm(a.id);
      expect(n.engine.plan().rings.first.at, at(6, 6, 39));
      n.now = at(6, 6, 39);
      final screen = n.ring(a.id);
      expect(screen.quiz, isTrue);
      n.engine.answer(a.id, word);
      expect(n.last.end, at(6, 6, 39));
      expect(n.engine.plan().rings.first.at, at(7, 6, 30));
    });

    test('the alarm snooze follows its setting', () {
      final a = n.alarm(6, 30);
      n.store.saveSettings(const Settings(alarmSnooze: Duration(minutes: 4)));
      n.now = at(6, 6, 30);
      n.ring(a.id);
      n.engine.snoozeAlarm(a.id);
      expect(n.engine.plan().rings.first.at, at(6, 6, 34));
    });

    test('with two alarms the quiz is on the first, the later one is a '
        'plain dismiss', () {
      final first = n.alarm(6, 30);
      final backup = n.alarm(6, 45);
      n.now = at(5, 22, 30);
      final word = n.engine.inBed();
      n.now = at(6, 6, 30);
      n.ring(first.id);
      n.engine.answer(first.id, word);
      n.now = at(6, 6, 45);
      expect(n.ring(backup.id).quiz, isFalse);
      n.engine.dismiss(backup.id);
      expect(n.store.loadRecords(), hasLength(1));
    });

    test('an alarm without the wake-up switch never quizzes nor ends the '
        'night', () {
      final reminder = n.alarm(6, 0, wakeUp: false);
      final wake = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      final word = n.engine.inBed();
      n.now = at(6, 6);
      expect(n.ring(reminder.id).quiz, isFalse);
      n.engine.dismiss(reminder.id);
      n.now = at(6, 6, 10);
      n.engine.timeout(reminder.id);
      expect(n.store.loadRecords(), isEmpty);
      n.now = at(6, 6, 30);
      expect(n.ring(wake.id).quiz, isTrue);
      n.engine.answer(wake.id, word);
      expect(n.last.result, NightResult.success);
    });

    test('a one-time alarm switches itself off after ringing', () {
      final a = n.alarm(7, 0, date: at(6, 0));
      n.now = at(6, 7);
      n.ring(a.id);
      expect(n.store.loadAlarms().single.enabled, isFalse);
      expect(n.engine.plan().rings, isEmpty);
    });
  });

  group('timeout', () {
    test('of the only wake-up alarm makes the night missed', () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      n.engine.inBed();
      n.now = at(6, 6, 30);
      n.ring(a.id);
      n.now = at(6, 6, 40);
      n.engine.timeout(a.id);
      expect(n.last.result, NightResult.missed);
      expect(n.last.end, at(6, 6, 40));
    });

    test('hands the quiz on to a later wake-up alarm of the morning', () {
      final first = n.alarm(6, 30);
      final backup = n.alarm(6, 45);
      n.now = at(5, 22, 30);
      final word = n.engine.inBed();
      n.now = at(6, 6, 30);
      n.ring(first.id);
      n.now = at(6, 6, 40);
      n.engine.timeout(first.id);
      expect(n.store.loadRecords(), isEmpty);
      n.now = at(6, 6, 45);
      expect(n.ring(backup.id).quiz, isTrue);
      n.now = at(6, 6, 46);
      n.engine.answer(backup.id, word);
      expect(n.last.result, NightResult.success);
      expect(n.last.end, at(6, 6, 46));
    });

    test('of every wake-up alarm ends the night at the last timeout', () {
      final first = n.alarm(6, 30);
      final backup = n.alarm(6, 45);
      n.now = at(5, 22, 30);
      n.engine.inBed();
      n.now = at(6, 6, 30);
      n.ring(first.id);
      n.now = at(6, 6, 40);
      n.engine.timeout(first.id);
      n.now = at(6, 6, 45);
      n.ring(backup.id);
      n.now = at(6, 6, 55);
      n.engine.timeout(backup.id);
      expect(n.last.result, NightResult.missed);
      expect(n.last.end, at(6, 6, 55));
    });
  });

  group('word expiry', () {
    test('the word waits for a moved alarm', () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      final word = n.engine.inBed();
      n.store.saveAlarm(a.copyWith(time: const ClockTime(8, 0)));
      n.now = at(6, 8);
      expect(n.ring(a.id).quiz, isTrue);
      n.engine.answer(a.id, word);
      expect(n.last.result, NightResult.success);
    });

    test('the word expires when no wake-up alarm rings within a day', () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      n.engine.inBed();
      n.store.saveAlarm(a.copyWith(enabled: false));
      n.now = at(6, 22, 31);
      n.store.saveAlarm(a.copyWith(enabled: true));
      expect(n.engine.plan().nextNag, at(6, 22, 30));
      n.now = at(7, 6, 30);
      expect(n.ring(a.id).quiz, isFalse);
      n.engine.dismiss(a.id);
      expect(n.store.loadRecords(), isEmpty);
    });
  });

  group('vacation', () {
    test('a one-time alarm on vacation rings with a plain dismiss', () {
      n.alarm(6, 30);
      final once = n.alarm(9, 0, date: at(7, 0));
      n.store.saveVacation(Vacation(id: 0, from: at(6, 0), to: at(9, 0)));
      n.now = at(6, 12);
      final plan = n.engine.plan();
      expect(plan.rings.first.at, at(7, 9));
      expect(plan.nextNag, at(11, 22, 30));
      n.now = at(7, 9);
      expect(n.ring(once.id).quiz, isFalse);
      n.engine.dismiss(once.id);
      expect(n.store.loadRecords(), isEmpty);
    });
  });

  group('hint', () {
    test('comes with the fifth failure in a row', () {
      final a = n.alarm(6, 30, days: {1, 2, 3, 4, 5, 6, 7});
      QuizOutcome? outcome;
      for (var i = 0; i < 5; i++) {
        n.now = at(5 + i, 22, 30);
        final word = n.engine.inBed();
        n.now = at(6 + i, 6, 30);
        final screen = n.ring(a.id);
        outcome = n.engine.answer(a.id, n.wrong(screen, word));
        expect(outcome!.stats.showHint, i == 4);
      }
      expect(outcome!.stats.streak, 5);
    });
  });

  group('events Android saw while the app slept', () {
    test('a nag at 22:30 learned at 06:30 records bedtime 22:30, assumed', () {
      final a = n.alarm(6, 30);
      n.now = at(6, 6, 31);
      n.engine.nagShown(at: at(5, 22, 30));
      n.engine.ring(a.id, at: at(6, 6, 30));
      expect(n.engine.screenFor(a.id).quiz, isFalse);
      n.engine.dismiss(a.id);
      expect(n.last.bedtime, at(5, 22, 30));
      expect(n.last.bedtimeAssumed, isTrue);
      expect(n.last.result, NightResult.noWord);
    });

    test('a ring and timeout the app never saw still leave the next '
        "evening's nag scheduled", () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      n.engine.inBed();
      // Planned the evening before: tonight is done, tomorrow comes next.
      expect(n.engine.plan().nags, [
        at(6, 22, 30),
        at(7, 22, 30),
        at(8, 22, 30),
      ]);
      n.now = at(6, 20);
      n.engine.ring(a.id, at: at(6, 6, 30));
      n.engine.timeout(a.id, at: at(6, 6, 40));
      expect(n.last.result, NightResult.missed);
      expect(n.last.end, at(6, 6, 40));
      expect(n.engine.plan().nextNag, at(6, 22, 30));
    });

    test('old events replay with their own time, not the clock', () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      n.engine.inBed();
      // The app comes back two days later.
      n.now = at(7, 20);
      n.engine.ring(a.id, at: at(6, 6, 30));
      n.engine.timeout(a.id, at: at(6, 6, 40));
      expect(n.last.result, NightResult.missed);
    });

    test('an expiring word leaves the next nags planned without any event '
        'at expiry time', () {
      final a = n.alarm(6, 30);
      n.now = at(5, 22, 30);
      n.engine.inBed();
      n.store.saveAlarm(a.copyWith(enabled: false));
      n.store.saveAlarm(
        a.copyWith(enabled: true, weekdays: {DateTime.wednesday}),
      );
      // Planned right after the edit: Tuesday evening's nag for Wednesday.
      expect(n.engine.plan().nextNag, at(6, 22, 30));
    });

    test("the next evening's nag starts a new night when the last one "
        'never ended', () {
      n.alarm(6, 30);
      n.engine.nagShown(at: at(5, 22, 30));
      n.engine.nagShown(at: at(6, 22, 30));
      final night = n.store.loadState().night!;
      expect(night.plannedBedtime, at(6, 22, 30));
      expect(night.lastNag, at(6, 22, 30));
    });

    test('rings are planned three ahead per alarm, snoozes added', () {
      final a = n.alarm(6, 30);
      n.now = at(6, 6, 30);
      n.engine.ring(a.id);
      n.engine.snoozeAlarm(a.id);
      expect(n.engine.plan().rings.map((r) => r.at), [
        at(6, 6, 39),
        at(7, 6, 30),
        at(8, 6, 30),
        at(9, 6, 30),
      ]);
    });
  });

  test('the engine keeps nothing in memory between events', () {
    final a = n.alarm(6, 30);
    n.now = at(5, 22, 30);
    final word = n.engine.inBed();
    final restarted = Engine(
      store: n.store,
      words: words,
      clock: () => at(6, 6, 30),
    );
    restarted.ring(a.id);
    expect(restarted.screenFor(a.id).options, contains(word));
  });
}

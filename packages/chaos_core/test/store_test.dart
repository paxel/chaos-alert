import 'dart:io';
import 'dart:math';

import 'package:chaos_core/chaos_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

/// The same behaviour is asked of every store.
void contract(String name, Store Function() open) {
  group(name, () {
    late Store store;
    setUp(() => store = open());

    test('settings start at their defaults and round-trip', () {
      expect(store.loadSettings().sleepLength, const Duration(hours: 8));
      store.saveSettings(
        const Settings(
          sleepLength: Duration(hours: 7, minutes: 30),
          nagSnooze: Duration(minutes: 5),
          alarmSnooze: Duration(minutes: 4),
          alarmTimeout: Duration(minutes: 15),
          lowVolume: 0.1,
          mediumVolume: 0.7,
          chime: false,
        ),
      );
      final s = store.loadSettings();
      expect(s.sleepLength, const Duration(hours: 7, minutes: 30));
      expect(s.nagSnooze, const Duration(minutes: 5));
      expect(s.alarmSnooze, const Duration(minutes: 4));
      expect(s.alarmTimeout, const Duration(minutes: 15));
      expect(s.lowVolume, 0.1);
      expect(s.mediumVolume, 0.7);
      expect(s.chime, isFalse);
    });

    test('alarms are created, edited and deleted', () {
      final a = store.saveAlarm(
        const Alarm(
          id: 0,
          time: ClockTime(6, 30),
          weekdays: {DateTime.monday, DateTime.sunday},
        ),
      );
      final b = store.saveAlarm(
        Alarm(
          id: 0,
          time: const ClockTime(5, 15),
          date: DateTime(2026, 12, 24),
          wakeUp: false,
        ),
      );
      expect(a.id, isNot(0));
      expect(b.id, isNot(a.id));
      store.saveAlarm(a.copyWith(enabled: false));
      final loaded = {for (final x in store.loadAlarms()) x.id: x};
      expect(loaded[a.id]!.weekdays, {DateTime.monday, DateTime.sunday});
      expect(loaded[a.id]!.enabled, isFalse);
      expect(loaded[b.id]!.date, DateTime(2026, 12, 24));
      expect(loaded[b.id]!.time, const ClockTime(5, 15));
      expect(loaded[b.id]!.wakeUp, isFalse);
      store.deleteAlarm(a.id);
      expect(store.loadAlarms().map((x) => x.id), [b.id]);
    });

    test('vacations are created and deleted', () {
      final v = store.saveVacation(
        Vacation(id: 0, from: DateTime(2026, 7, 1), to: DateTime(2026, 7, 14)),
      );
      expect(store.loadVacations().single.to, DateTime(2026, 7, 14));
      store.deleteVacation(v.id);
      expect(store.loadVacations(), isEmpty);
    });

    test('nights and the engine state round-trip', () {
      final record = NightRecord(
        plannedBedtime: DateTime(2026, 10, 4, 22, 30),
        bedtime: DateTime(2026, 10, 4, 22, 40),
        bedtimeAssumed: true,
        end: DateTime(2026, 10, 5, 6, 31),
        result: NightResult.failure,
        word: 'lantern',
        wrongPicks: 2,
      );
      store.addRecord(record);
      final back = store.loadRecords().single;
      expect(back.bedtime, record.bedtime);
      expect(back.bedtimeAssumed, isTrue);
      expect(back.end, record.end);
      expect(back.result, NightResult.failure);
      expect(back.wrongPicks, 2);
      expect(back.word, 'lantern');

      final state = EngineState(
        night: OpenNight(
          plannedBedtime: DateTime(2026, 10, 5, 22, 30),
          lastNag: DateTime(2026, 10, 5, 22, 30),
          nagSnoozedUntil: DateTime(2026, 10, 5, 22, 40),
          options: ['a', 'b', 'c', 'd'],
          wrongPicks: ['b'],
          nagLine: 'Go to bed.',
        ),
        alarmSnoozes: {3: DateTime(2026, 10, 6, 6, 39)},
        lastRing: {3: DateTime(2026, 10, 6, 6, 30)},
        deck: WordDeck(order: [2, 0, 1], cursor: 1),
        lineDeck: WordDeck(order: [1, 0], cursor: 2),
        setupDone: true,
        pendingHint: true,
      );
      store.saveState(state);
      final s = store.loadState();
      expect(s.night!.nagSnoozedUntil, DateTime(2026, 10, 5, 22, 40));
      expect(s.night!.confirmed, isFalse);
      expect(s.night!.options, ['a', 'b', 'c', 'd']);
      expect(s.night!.wrongPicks, ['b']);
      expect(s.alarmSnoozes, {3: DateTime(2026, 10, 6, 6, 39)});
      expect(s.lastRing, {3: DateTime(2026, 10, 6, 6, 30)});
      expect(s.deck.order, [2, 0, 1]);
      expect(s.deck.cursor, 1);
      expect(s.night!.nagLine, 'Go to bed.');
      expect(s.lineDeck.order, [1, 0]);
      expect(s.lineDeck.cursor, 2);
      expect(s.setupDone, isTrue);
      expect(s.pendingHint, isTrue);
      expect(EngineState().setupDone, isFalse);
    });
  });
}

void main() {
  contract('memory store', MemoryStore.new);
  contract('SQLite store', SqliteStore.inMemory);

  test('a database from 0.1.0 gains wrong picks, old nights at 0', () {
    final dir = Directory.systemTemp.createTempSync('chaos_migrate');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/chaos.db';
    // The 0.1.0 schema, with one night in it.
    final old = sqlite3.open(path)
      ..execute('''
        create table kv (key text primary key, value text not null);
        create table alarms (id integer primary key autoincrement,
          hour integer not null, minute integer not null,
          weekdays integer not null, date text, enabled integer not null,
          wake_up integer not null);
        create table vacations (id integer primary key autoincrement,
          from_day text not null, to_day text not null);
        create table nights (id integer primary key autoincrement,
          planned_bedtime text not null, bedtime text not null,
          bedtime_assumed integer not null, end_time text not null,
          result text not null, word text);
        insert into nights (planned_bedtime, bedtime, bedtime_assumed,
          end_time, result, word) values ('2026-10-01T22:30:00.000',
          '2026-10-01T22:30:00.000', 0, '2026-10-02T06:30:00.000',
          'success', 'lantern');
      ''')
      ..userVersion = 1;
    old.close();

    final store = SqliteStore.open(path);
    addTearDown(store.close);
    final night = store.loadRecords().single;
    expect(night.word, 'lantern');
    expect(night.wrongPicks, 0);
  });

  test('a night survives closing and reopening the database file', () {
    final dir = Directory.systemTemp.createTempSync('chaos_store');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/chaos.db';
    var now = DateTime(2026, 10, 5, 22, 30);
    const words = ['verdict', 'venture', 'harbour', 'lantern', 'quarrel'];

    var store = SqliteStore.open(path);
    final alarm = store.saveAlarm(
      const Alarm(id: 0, time: ClockTime(6, 30), weekdays: {DateTime.tuesday}),
    );
    final word = Engine(
      store: store,
      words: words,
      clock: () => now,
      random: Random(1),
    ).inBed()!;
    store.close();

    store = SqliteStore.open(path);
    addTearDown(store.close);
    now = DateTime(2026, 10, 6, 6, 30);
    final engine = Engine(store: store, words: words, clock: () => now);
    engine.ring(alarm.id);
    expect(engine.screenFor(alarm.id).options, contains(word));
    expect(engine.answer(alarm.id, word)!.correct, isTrue);
    expect(store.loadRecords().single.result, NightResult.success);
  });
}

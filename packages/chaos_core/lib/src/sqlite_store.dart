import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import 'model.dart';
import 'nights.dart';
import 'state.dart';
import 'store.dart';

/// The [Store] on the phone: one SQLite file.
class SqliteStore implements Store {
  SqliteStore._(this._db) {
    _migrate();
  }

  /// Opens or creates the database at [path].
  factory SqliteStore.open(String path) => SqliteStore._(sqlite3.open(path));

  /// A database that lives in memory only, for tests.
  factory SqliteStore.inMemory() => SqliteStore._(sqlite3.openInMemory());

  final Database _db;

  void close() => _db.close();

  void _migrate() {
    if (_db.userVersion < 1) _createTables();
    if (_db.userVersion < 2) {
      _db.execute(
        'alter table nights add column wrong_picks integer not null default 0',
      );
      _db.userVersion = 2;
    }
  }

  void _createTables() {
    _db.execute('''
      create table kv (key text primary key, value text not null);
      create table alarms (
        id integer primary key autoincrement,
        hour integer not null,
        minute integer not null,
        weekdays integer not null,
        date text,
        enabled integer not null,
        wake_up integer not null
      );
      create table vacations (
        id integer primary key autoincrement,
        from_day text not null,
        to_day text not null
      );
      create table nights (
        id integer primary key autoincrement,
        planned_bedtime text not null,
        bedtime text not null,
        bedtime_assumed integer not null,
        end_time text not null,
        result text not null,
        word text
      );
    ''');
    _db.userVersion = 1;
  }

  String? _get(String key) {
    final rows = _db.select('select value from kv where key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  void _put(String key, String value) => _db.execute(
    'insert into kv (key, value) values (?, ?) '
    'on conflict (key) do update set value = excluded.value',
    [key, value],
  );

  @override
  Settings loadSettings() {
    final raw = _get('settings');
    if (raw == null) return const Settings();
    final m = jsonDecode(raw) as Map<String, Object?>;
    const d = Settings();
    Duration? minutes(String key) => switch (m[key]) {
      final int v => Duration(minutes: v),
      _ => null,
    };
    return Settings(
      sleepLength: minutes('sleepLength') ?? d.sleepLength,
      nagSnooze: minutes('nagSnooze') ?? d.nagSnooze,
      alarmSnooze: minutes('alarmSnooze') ?? d.alarmSnooze,
      alarmTimeout: minutes('alarmTimeout') ?? d.alarmTimeout,
      lowVolume: (m['lowVolume'] as num?)?.toDouble() ?? d.lowVolume,
      mediumVolume: (m['mediumVolume'] as num?)?.toDouble() ?? d.mediumVolume,
      chime: m['chime'] as bool? ?? d.chime,
    );
  }

  @override
  void saveSettings(Settings settings) => _put(
    'settings',
    jsonEncode({
      'sleepLength': settings.sleepLength.inMinutes,
      'nagSnooze': settings.nagSnooze.inMinutes,
      'alarmSnooze': settings.alarmSnooze.inMinutes,
      'alarmTimeout': settings.alarmTimeout.inMinutes,
      'lowVolume': settings.lowVolume,
      'mediumVolume': settings.mediumVolume,
      'chime': settings.chime,
    }),
  );

  @override
  List<Alarm> loadAlarms() => [
    for (final r in _db.select('select * from alarms order by id'))
      Alarm(
        id: r['id'] as int,
        time: ClockTime(r['hour'] as int, r['minute'] as int),
        weekdays: {
          for (var d = DateTime.monday; d <= DateTime.sunday; d++)
            if ((r['weekdays'] as int) & (1 << d) != 0) d,
        },
        date: switch (r['date']) {
          final String s => DateTime.parse(s),
          _ => null,
        },
        enabled: r['enabled'] == 1,
        wakeUp: r['wake_up'] == 1,
      ),
  ];

  @override
  Alarm saveAlarm(Alarm alarm) {
    final values = [
      alarm.time.hour,
      alarm.time.minute,
      alarm.weekdays.fold(0, (bits, d) => bits | (1 << d)),
      alarm.date == null ? null : _day(alarm.date!),
      alarm.enabled ? 1 : 0,
      alarm.wakeUp ? 1 : 0,
    ];
    if (alarm.id == 0) {
      _db.execute(
        'insert into alarms (hour, minute, weekdays, date, enabled, wake_up) '
        'values (?, ?, ?, ?, ?, ?)',
        values,
      );
      return alarm.copyWith(id: _db.lastInsertRowId);
    }
    _db.execute(
      'insert or replace into alarms '
      '(id, hour, minute, weekdays, date, enabled, wake_up) '
      'values (?, ?, ?, ?, ?, ?, ?)',
      [alarm.id, ...values],
    );
    return alarm;
  }

  @override
  void deleteAlarm(int id) =>
      _db.execute('delete from alarms where id = ?', [id]);

  @override
  List<Vacation> loadVacations() => [
    for (final r in _db.select('select * from vacations order by from_day'))
      Vacation(
        id: r['id'] as int,
        from: DateTime.parse(r['from_day'] as String),
        to: DateTime.parse(r['to_day'] as String),
      ),
  ];

  @override
  Vacation saveVacation(Vacation vacation) {
    if (vacation.id == 0) {
      _db.execute('insert into vacations (from_day, to_day) values (?, ?)', [
        _day(vacation.from),
        _day(vacation.to),
      ]);
      return Vacation(
        id: _db.lastInsertRowId,
        from: vacation.from,
        to: vacation.to,
      );
    }
    _db.execute(
      'insert or replace into vacations (id, from_day, to_day) '
      'values (?, ?, ?)',
      [vacation.id, _day(vacation.from), _day(vacation.to)],
    );
    return vacation;
  }

  @override
  void deleteVacation(int id) =>
      _db.execute('delete from vacations where id = ?', [id]);

  @override
  List<NightRecord> loadRecords() => [
    for (final r in _db.select('select * from nights order by end_time'))
      NightRecord(
        plannedBedtime: DateTime.parse(r['planned_bedtime'] as String),
        bedtime: DateTime.parse(r['bedtime'] as String),
        bedtimeAssumed: r['bedtime_assumed'] == 1,
        end: DateTime.parse(r['end_time'] as String),
        result: NightResult.values.byName(r['result'] as String),
        word: r['word'] as String?,
        wrongPicks: r['wrong_picks'] as int,
      ),
  ];

  @override
  void addRecord(NightRecord record) => _db.execute(
    'insert into nights (planned_bedtime, bedtime, bedtime_assumed, '
    'end_time, result, word, wrong_picks) values (?, ?, ?, ?, ?, ?, ?)',
    [
      record.plannedBedtime.toIso8601String(),
      record.bedtime.toIso8601String(),
      record.bedtimeAssumed ? 1 : 0,
      record.end.toIso8601String(),
      record.result.name,
      record.word,
      record.wrongPicks,
    ],
  );

  @override
  EngineState loadState() {
    final raw = _get('state');
    if (raw == null) return EngineState();
    return EngineState.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  void saveState(EngineState state) =>
      _put('state', jsonEncode(state.toJson()));
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

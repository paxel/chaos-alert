import 'model.dart';
import 'nights.dart';
import 'state.dart';

/// Where everything the app knows is kept.
abstract interface class Store {
  Settings loadSettings();
  void saveSettings(Settings settings);

  List<Alarm> loadAlarms();

  /// Saves [alarm]; an id of 0 makes a new alarm. Returns it with its id.
  Alarm saveAlarm(Alarm alarm);
  void deleteAlarm(int id);

  List<Vacation> loadVacations();

  /// Saves [vacation]; an id of 0 makes a new one. Returns it with its id.
  Vacation saveVacation(Vacation vacation);
  void deleteVacation(int id);

  List<NightRecord> loadRecords();
  void addRecord(NightRecord record);

  EngineState loadState();
  void saveState(EngineState state);
}

/// A [Store] in memory, for tests.
class MemoryStore implements Store {
  Settings _settings = const Settings();
  final _alarms = <int, Alarm>{};
  final _vacations = <int, Vacation>{};
  final _records = <NightRecord>[];
  Map<String, Object?> _state = EngineState().toJson();
  var _nextId = 1;

  @override
  Settings loadSettings() => _settings;

  @override
  void saveSettings(Settings settings) => _settings = settings;

  @override
  List<Alarm> loadAlarms() => _alarms.values.toList();

  @override
  Alarm saveAlarm(Alarm alarm) {
    final saved = alarm.id == 0 ? alarm.copyWith(id: _nextId++) : alarm;
    _alarms[saved.id] = saved;
    return saved;
  }

  @override
  void deleteAlarm(int id) => _alarms.remove(id);

  @override
  List<Vacation> loadVacations() => _vacations.values.toList();

  @override
  Vacation saveVacation(Vacation vacation) {
    final saved = vacation.id == 0
        ? Vacation(id: _nextId++, from: vacation.from, to: vacation.to)
        : vacation;
    _vacations[saved.id] = saved;
    return saved;
  }

  @override
  void deleteVacation(int id) => _vacations.remove(id);

  @override
  List<NightRecord> loadRecords() => List.of(_records);

  @override
  void addRecord(NightRecord record) => _records.add(record);

  // Kept as JSON, so tests go through the same round trip as the database.
  @override
  EngineState loadState() => EngineState.fromJson(_state);

  @override
  void saveState(EngineState state) => _state = state.toJson();
}

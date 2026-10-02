import 'dart:math';

import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/foundation.dart';

import 'platform.dart';

/// The app's single source of truth: wraps the engine and the store, and
/// hands every change to Android as a fresh schedule.
class Controller extends ChangeNotifier {
  Controller({
    required this.store,
    required this.platform,
    required List<String> words,
    DateTime Function()? clock,
    Random? random,
  }) : clock = clock ?? DateTime.now,
       _random = random ?? Random() {
    engine = Engine(
      store: store,
      words: words,
      clock: this.clock,
      random: _random,
    );
    _reload();
  }

  final Store store;
  final AlarmPlatform platform;
  final DateTime Function() clock;
  final Random _random;
  late final Engine engine;

  List<Sound>? _sounds;
  Map<Permission, bool> _permissions = const {};

  /// Permissions Android has not granted.
  List<Permission> get missingPermissions => [
    for (final p in Permission.values)
      if (_permissions[p] != true) p,
  ];

  bool get hasPermissionInfo => _permissions.isNotEmpty;

  // What the screens show, read once per change so build() never touches
  // the store.
  late Settings _settings;
  late List<Alarm> _alarms;
  late List<Vacation> _vacations;
  late List<NightRecord> _nights;
  late bool _canSayInBed;
  late bool _setupDone;
  late bool _pendingHint;
  Plan _plan = const Plan();

  Settings get settings => _settings;
  List<Alarm> get alarms => List.of(_alarms);
  List<Vacation> get vacations => List.of(_vacations);
  List<NightRecord> get nights => _nights;
  bool get canSayInBed => _canSayInBed;
  bool get setupDone => _setupDone;

  /// The hint whose page never came (a timeout ended the fifth failure).
  bool get pendingHint => _pendingHint;

  /// The plan last handed to Android.
  Plan get plan => _plan;

  void _reload() {
    _settings = store.loadSettings();
    _alarms = store.loadAlarms();
    _vacations = store.loadVacations();
    _nights = store.loadRecords();
    _canSayInBed = engine.canSayInBed;
    _setupDone = store.loadState().setupDone;
    _pendingHint = engine.pendingHint;
  }

  /// The hint card on the main screen was read.
  void dismissHint() {
    engine.dismissHint();
    _pendingHint = false;
    notifyListeners();
  }

  /// Re-reads what depends on the time of day, like the "I'm in bed"
  /// window. Called once a minute while the main screen is shown.
  void tick() {
    final can = engine.canSayInBed;
    if (can == _canSayInBed) return;
    _canSayInBed = can;
    notifyListeners();
  }

  /// The first-start setup was walked through.
  void finishSetup() {
    final state = store.loadState()..setupDone = true;
    store.saveState(state);
    _setupDone = true;
    notifyListeners();
  }

  /// Reads what Android allows, which sounds exist and what happened while
  /// the app was not running, then reschedules.
  Future<void> refresh() async {
    _permissions = await platform.permissions();
    _sounds = await platform.sounds();
    final events = await platform.drainEvents()
      ..sort((a, b) => a.at.compareTo(b.at));
    for (final e in events) {
      switch (e) {
        case NagFired(:final at):
          engine.nagShown(at: at);
        case RingStarted(:final alarmId, :final at):
          engine.ring(alarmId, at: at);
        case RingTimedOut(:final alarmId, :final at):
          engine.timeout(alarmId, at: at);
      }
    }
    await reschedule();
  }

  /// Hands the engine's plan to Android.
  Future<void> reschedule() async {
    final plan = _plan = engine.plan();
    final settings = store.loadSettings();
    final sounds = _sounds ??= await platform.sounds();
    await platform.scheduleNags(plan.nags, chime: settings.chime);
    await platform.scheduleRings([
      for (final r in plan.rings)
        ScheduledRing(
          alarmId: r.alarmId,
          at: r.at,
          sounds: pickSounds(sounds, _random),
          lowVolume: settings.lowVolume,
          mediumVolume: settings.mediumVolume,
          timeout: settings.alarmTimeout,
        ),
    ]);
    _reload();
    notifyListeners();
  }

  Future<void> saveSettings(Settings settings) {
    store.saveSettings(settings);
    return reschedule();
  }

  Future<void> saveAlarm(Alarm alarm) {
    store.saveAlarm(alarm);
    return reschedule();
  }

  Future<void> deleteAlarm(int id) {
    store.deleteAlarm(id);
    return reschedule();
  }

  Future<void> saveVacation(Vacation vacation) {
    store.saveVacation(vacation);
    return reschedule();
  }

  Future<void> deleteVacation(int id) {
    store.deleteVacation(id);
    return reschedule();
  }

  Future<void> request(Permission permission) async {
    await platform.request(permission);
    await refresh();
  }

  /// Returns the word to remember.
  Future<String> inBed() async {
    final word = engine.inBed();
    await reschedule();
    return word;
  }

  Future<void> snoozeNag(Duration length) {
    engine.snoozeNag(length);
    return reschedule();
  }

  /// What the ringing alarm [alarmId] shows.
  RingScreen screenFor(int alarmId) => engine.screenFor(alarmId);

  Future<void> snoozeAlarm(int alarmId) async {
    engine.snoozeAlarm(alarmId);
    await platform.stopRinging();
    await reschedule();
  }

  Future<QuizOutcome?> answer(int alarmId, String picked) async {
    final outcome = engine.answer(alarmId, picked);
    await platform.stopRinging();
    await reschedule();
    return outcome;
  }

  Future<void> dismiss(int alarmId) async {
    engine.dismiss(alarmId);
    await platform.stopRinging();
    await reschedule();
  }

  Future<void> timeout(int alarmId) async {
    engine.timeout(alarmId);
    await platform.stopRinging();
    await reschedule();
  }
}

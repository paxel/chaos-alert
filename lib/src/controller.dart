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

  Settings get settings => store.loadSettings();
  List<Alarm> get alarms => store.loadAlarms();
  List<Vacation> get vacations => store.loadVacations();
  List<NightRecord> get nights => store.loadRecords();
  bool get canSayInBed => engine.canSayInBed;
  Plan get plan => engine.plan();

  /// Reads what Android allows and which sounds exist, then reschedules.
  Future<void> refresh() async {
    _permissions = await platform.permissions();
    _sounds = await platform.sounds();
    await reschedule();
  }

  /// Hands the engine's plan to Android.
  Future<void> reschedule() async {
    final plan = engine.plan();
    final settings = store.loadSettings();
    final sounds = _sounds ??= await platform.sounds();
    await platform.scheduleNag(plan.nag, chime: settings.chime);
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

  Future<void> nagShown() {
    engine.nagShown();
    return reschedule();
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

  Future<RingScreen> ring(int alarmId) async {
    final screen = engine.ring(alarmId);
    await reschedule();
    return screen;
  }

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

import 'dart:async';
import 'dart:math';

import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/foundation.dart';

import 'generated_sounds.dart';
import 'platform.dart';

/// The app's single source of truth: wraps the engine and the store, and
/// hands every change to Android as a fresh schedule.
class Controller extends ChangeNotifier {
  Controller({
    required this.store,
    required this.platform,
    this.clips,
    required List<String> words,
    List<String> nagLines = const [],
    DateTime Function()? clock,
    Random? random,
  }) : clock = clock ?? DateTime.now,
       _random = random ?? Random() {
    engine = Engine(
      store: store,
      words: words,
      nagLines: nagLines,
      clock: this.clock,
      random: _random,
    );
    _reload();
  }

  final Store store;
  final AlarmPlatform platform;

  /// Makes the generated sounds; without it there are none.
  final ClipMaker? clips;
  final DateTime Function() clock;
  final Random _random;
  late final Engine engine;

  List<Sound>? _sounds;
  final _folderSounds = <String, List<Sound>?>{};
  Map<Permission, bool> _permissions = const {};

  /// Permissions Android has not granted.
  List<Permission> get missingPermissions => [
    for (final p in Permission.values)
      if (_permissions[p] != true) p,
  ];

  bool get hasPermissionInfo => _permissions.isNotEmpty;

  /// How many sounds each picked folder holds: 0 for none, null once the
  /// phone took the access away; a folder not read yet is missing.
  Map<String, int?> get folderCounts => {
    for (final e in _folderSounds.entries) e.key: e.value?.length,
  };

  // What the screens show, read once per change so build() never touches
  // the store.
  late Settings _settings;
  late List<Alarm> _alarms;
  late List<Vacation> _vacations;
  late List<NightRecord> _nights;
  late bool _canSayInBed;
  late bool _canFetchWord;
  late bool _isBedtime;
  late bool _canSayAwake;
  late bool _canSayUp;
  late bool _setupDone;
  late bool _pendingHint;
  late Map<int, DateTime> _alarmSnoozes;
  String? _nagLine;
  Plan _plan = const Plan();

  Settings get settings => _settings;
  List<Alarm> get alarms => List.of(_alarms);
  List<Vacation> get vacations => List.of(_vacations);
  List<NightRecord> get nights => _nights;
  bool get canSayInBed => _canSayInBed;

  /// Whether the word can be fetched now: in bed, without it yet.
  bool get canFetchWord => _canFetchWord;

  /// Whether a nag still belongs to a night; outside, an open nag is stale.
  bool get isBedtime => _isBedtime;
  bool get canSayAwake => _canSayAwake;

  /// Whether "I'm up" can end the night: after the "I'm awake" quiz.
  bool get canSayUp => _canSayUp;
  bool get setupDone => _setupDone;

  /// The line on the nag last shown tonight.
  String? get nagLine => _nagLine;

  /// When each snoozed alarm rings again.
  Map<int, DateTime> get alarmSnoozes => Map.of(_alarmSnoozes);

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
    _canFetchWord = engine.canFetchWord;
    _isBedtime = engine.isBedtime;
    _canSayAwake = engine.canSayAwake;
    _canSayUp = engine.canSayUp;
    _setupDone = store.loadState().setupDone;
    _pendingHint = engine.pendingHint;
    _nagLine = engine.nagLine;
    _alarmSnoozes = store.loadState().alarmSnoozes;
  }

  /// Adds [text] to the event log on the phone, without waiting for it.
  void log(String text) => unawaited(platform.log('app: $text'));

  /// The hint card on the main screen was read.
  void dismissHint() {
    engine.dismissHint();
    _pendingHint = false;
    notifyListeners();
  }

  /// Re-reads what depends on the time of day, like the "I'm in bed"
  /// window. Called once a minute while the main screen is shown.
  void tick() {
    final inBed = engine.canSayInBed;
    final word = engine.canFetchWord;
    final bedtime = engine.isBedtime;
    final awake = engine.canSayAwake;
    final up = engine.canSayUp;
    if (inBed == _canSayInBed &&
        word == _canFetchWord &&
        bedtime == _isBedtime &&
        awake == _canSayAwake &&
        up == _canSayUp) {
      return;
    }
    _canSayInBed = inBed;
    _canFetchWord = word;
    _isBedtime = bedtime;
    _canSayAwake = awake;
    _canSayUp = up;
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
        case RingSnoozed(:final alarmId, :final at):
          engine.snoozeAlarm(alarmId, at: at);
        case RingTimedOut(:final alarmId, :final at):
          engine.timeout(alarmId, at: at);
      }
    }
    await reschedule();
    // A big folder takes long to read, and a ring screen waits for this.
    _foldersRead = _readFolders();
  }

  Future<void>? _foldersRead;

  /// The folder reading the last [refresh] started, for tests.
  @visibleForTesting
  Future<void> get foldersRead => _foldersRead ?? Future.value();

  Future<void> _readFolders() async {
    final folders = store.loadSettings().folders;
    if (folders.isEmpty) return;
    for (final f in folders) {
      await _readFolder(f.uri);
    }
    await reschedule(renewClips: false);
  }

  Future<void> _readFolder(String uri) async =>
      _folderSounds[uri] = await platform.folderSounds(uri);

  /// Hands the engine's plan to Android. With the generated sounds on, it
  /// makes new clips for the next scheduling; the first clips ever made
  /// get a scheduling of their own.
  Future<void> reschedule({bool renewClips = true}) async {
    final plan = _plan = engine.plan();
    final settings = store.loadSettings();
    log(
      'plan: nags ${plan.nags.take(1).join()}, rings '
      '${[for (final r in plan.rings.take(3)) '${r.alarmId}@${r.at}'].join(', ')}',
    );
    final system = _sounds ??= await platform.sounds();
    final clips = this.clips;
    final made = clips == null ? const <Sound>[] : clips.sounds;
    final sounds = availableSounds([
      ...system,
      for (final f in settings.folders) ...?_folderSounds[f.uri],
      ...made,
    ], settings);
    await platform.scheduleNags(plan.nags, chime: settings.chime);
    await platform.scheduleAwake([
      for (final ring in plan.awake)
        AwakeNotice(at: ring.subtract(awakeNoticeLead), until: ring),
    ]);
    await platform.scheduleRings([
      for (final r in plan.rings)
        ScheduledRing(
          alarmId: r.alarmId,
          at: r.at,
          sounds: pickSounds(sounds, _random),
          lowVolume: settings.lowVolume,
          mediumVolume: settings.mediumVolume,
          timeout: settings.alarmTimeout,
          snooze: settings.alarmSnooze,
        ),
    ]);
    if (clips != null && settings.generated && renewClips) {
      unawaited(_renew(clips, firstClips: made.isEmpty));
    }
    _reload();
    // A nag left in the shade from a night that is over opens nothing.
    if (!_isBedtime) await platform.clearNagNotice();
    notifyListeners();
  }

  Future<void> _renew(ClipMaker clips, {required bool firstClips}) async {
    try {
      await clips.renew(_random.nextInt(1 << 32));
      if (firstClips) await reschedule(renewClips: false);
    } catch (e) {
      log('generated sounds failed: $e');
    }
  }

  /// Lets the user pick a folder and adds it as a sound source.
  Future<void> addFolder() async {
    final folder = await platform.pickFolder();
    if (folder == null) return;
    final settings = store.loadSettings();
    if (settings.folders.any((f) => f.uri == folder.uri)) return;
    await _readFolder(folder.uri);
    await saveSettings(
      settings.copyWith(folders: [...settings.folders, folder]),
    );
  }

  /// Picks a folder anew in place of [uri], e.g. after its access was lost.
  Future<void> repickFolder(String uri) async {
    final folder = await platform.pickFolder();
    if (folder == null) return;
    final settings = store.loadSettings();
    if (folder.uri != uri) {
      await platform.releaseFolder(uri);
      _folderSounds.remove(uri);
    }
    await _readFolder(folder.uri);
    await saveSettings(
      settings.copyWith(
        folders: [
          for (final f in settings.folders)
            if (f.uri == uri)
              folder.copyWith(on: f.on)
            else if (f.uri != folder.uri)
              f,
        ],
      ),
    );
  }

  Future<void> removeFolder(String uri) async {
    await platform.releaseFolder(uri);
    _folderSounds.remove(uri);
    final settings = store.loadSettings();
    await saveSettings(
      settings.copyWith(
        folders: [
          for (final f in settings.folders)
            if (f.uri != uri) f,
        ],
      ),
    );
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

  /// "I'm in bed" without the word; returns whether it counted.
  Future<bool> inBed() async {
    final counted = engine.inBed();
    log(counted ? 'in bed' : 'in bed ignored');
    await reschedule();
    return counted;
  }

  /// Yes on the nag, or the word button: returns the word to remember;
  /// null outside bedtime or once it was shown, when nothing changes.
  Future<String?> wordNow() async {
    final word = engine.wordNow();
    log(word == null ? 'word ignored' : 'word given');
    await reschedule();
    return word;
  }

  Future<void> snoozeNag(Duration length) {
    log('nag snoozed for ${length.inMinutes} min');
    engine.snoozeNag(length);
    return reschedule();
  }

  /// What "I'm awake" shows.
  RingScreen awakeScreen() => engine.awakeScreen();

  Future<QuizOutcome?> awakeAnswer(String picked) async {
    final outcome = engine.awakeAnswer(picked);
    if (outcome != null && outcome.next) return outcome;
    if (outcome != null && outcome.correct) await platform.clearAwakeNotice();
    await reschedule();
    return outcome;
  }

  /// "I'm up" after the "I'm awake" quiz ends the night.
  Future<void> up() async {
    log('up');
    engine.up();
    await reschedule();
  }

  Future<void> awakeDismiss() async {
    engine.awakeDismiss();
    await platform.clearAwakeNotice();
    await reschedule();
  }

  /// What the ringing alarm [alarmId] shows.
  RingScreen screenFor(int alarmId) => engine.screenFor(alarmId);

  /// The sound stops first, so nothing after it can leave the alarm
  /// playing.
  Future<void> snoozeAlarm(int alarmId) async {
    log('alarm $alarmId snoozed on screen');
    await platform.stopRinging();
    engine.snoozeAlarm(alarmId);
    await reschedule();
  }

  /// A right letter quiz round leaves the alarm ringing for the next one.
  Future<QuizOutcome?> answer(int alarmId, String picked) async {
    final outcome = engine.answer(alarmId, picked);
    if (outcome != null && outcome.next) return outcome;
    log(
      'alarm $alarmId answered ${outcome?.correct == true ? 'right' : 'wrong'}',
    );
    await platform.stopRinging();
    await reschedule();
    return outcome;
  }

  Future<void> dismiss(int alarmId) async {
    log('alarm $alarmId dismissed');
    engine.dismiss(alarmId);
    await platform.stopRinging();
    await reschedule();
  }

  Future<void> timeout(int alarmId) async {
    log('alarm $alarmId timed out on screen');
    engine.timeout(alarmId);
    await platform.stopRinging();
    await reschedule();
  }
}

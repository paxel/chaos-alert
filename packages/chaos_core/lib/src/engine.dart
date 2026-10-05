import 'dart:math';

import 'model.dart';
import 'nights.dart';
import 'schedule.dart';
import 'state.dart';
import 'store.dart';
import 'words.dart';

/// How long before bedtime the "I'm in bed" button appears.
const inBedWindow = Duration(hours: 3);

/// How long a shown word waits for a wake-up alarm before it expires.
const wordLifetime = Duration(hours: 24);

/// How long before the first wake-up alarm "I'm awake" appears.
const awakeWindow = Duration(hours: 1);

/// How many nags and how many rings per alarm the plan looks ahead, so
/// Android keeps nagging and ringing on days the app never runs.
const planAhead = 3;

/// What the platform has to schedule next.
class Plan {
  const Plan({
    this.nags = const [],
    this.rings = const [],
    this.awake = const [],
  });

  /// When the bedtime nag pops up, earliest first; a time in the past
  /// means now.
  final List<DateTime> nags;

  /// The coming rings of every alarm, snoozes included, earliest first.
  final List<PlannedRing> rings;

  /// The coming mornings' first wake-up rings, for the silent "I'm awake"
  /// notice an hour before each.
  final List<DateTime> awake;

  DateTime? get nextNag => nags.isEmpty ? null : nags.first;
}

class PlannedRing {
  const PlannedRing(this.alarmId, this.at);

  final int alarmId;
  final DateTime at;
}

/// What a ringing alarm shows.
class RingScreen {
  const RingScreen.quiz(this.options) : quiz = true;
  const RingScreen.dismiss() : quiz = false, options = const [];

  /// Whether turning it off takes the quiz; else a plain dismiss button.
  final bool quiz;
  final List<String> options;
}

/// How a quiz answer went.
class QuizOutcome {
  const QuizOutcome.wrong({required this.snooze})
    : correct = false,
      wrongPicks = 0,
      word = null,
      stats = null;

  const QuizOutcome.right({
    required this.wrongPicks,
    required String this.word,
    required QuizStats this.stats,
  }) : correct = true,
       snooze = null;

  final bool correct;

  /// After a wrong pick: how long until the alarm rings again; null when
  /// nothing rings (the "I'm awake" quiz).
  final Duration? snooze;

  /// After the right pick: how many wrong ones came first.
  final int wrongPicks;

  /// After the right pick: the word, and the statistics including tonight.
  final String? word;
  final QuizStats? stats;

  /// Whether the night failed although the word was found in the end.
  bool get failed => correct && wrongPicks > 0;
}

/// Every rule of the night. Each event reads the store, applies the rule
/// and writes the store back, so the engine holds no state of its own and
/// can be rebuilt whenever the app starts.
///
/// Events Android saw while the app was not running arrive later with the
/// moment they happened as `at`; everything else happens now.
class Engine {
  Engine({
    required this.store,
    required this.words,
    this.nagLines = const [],
    required this.clock,
    Random? random,
  }) : _random = random ?? Random();

  final Store store;
  final List<String> words;

  /// What a nag says above its question; a nag without lines says nothing.
  final List<String> nagLines;
  final DateTime Function() clock;
  final Random _random;

  DateTime get _now => clock();

  /// What to schedule now.
  Plan plan() {
    final now = _now;
    final state = _load(now);
    final alarms = store.loadAlarms();
    final vacations = store.loadVacations();
    final settings = store.loadSettings();

    final nags = <DateTime>[];
    final night = state.night;
    final snoozed = night?.nagSnoozedUntil;
    final skipUntil = night?.expectedWake;
    if (night != null &&
        !night.confirmed &&
        snoozed != null &&
        (skipUntil == null || snoozed.isBefore(skipUntil))) {
      nags.add(snoozed);
    }
    var cursor = now;
    for (var i = 0; nags.length < planAhead && i < planAhead + 1; i++) {
      final m = nextMorning(cursor, alarms, vacations, settings);
      if (m == null) break;
      cursor = m.firstWakeUp;
      // The open night already had its nag.
      if (skipUntil != null && !m.firstWakeUp.isAfter(skipUntil)) continue;
      nags.add(m.bedtime);
    }

    final byId = {for (final a in alarms) a.id: a};
    state.alarmSnoozes.removeWhere((id, _) => !byId.containsKey(id));
    final rings = <PlannedRing>[];
    for (final a in alarms) {
      final last = state.lastRing[a.id];
      var after = last != null && last.isAfter(now) ? last : now;
      for (var i = 0; i < planAhead; i++) {
        final at = nextRingOf(a, after, vacations);
        if (at == null) break;
        rings.add(PlannedRing(a.id, at));
        after = at;
      }
      final snooze = state.alarmSnoozes[a.id];
      if (snooze != null) rings.add(PlannedRing(a.id, snooze));
    }
    rings.sort((a, b) => a.at.compareTo(b.at));
    final awake = <DateTime>[];
    var after = now;
    for (var i = 0; i < planAhead; i++) {
      final next = _firstWakeUpAfter(after, state, days: 8);
      if (next == null) break;
      awake.add(next);
      after = DateTime(next.year, next.month, next.day + 1);
    }
    _save(state);
    return Plan(nags: nags, rings: rings, awake: awake);
  }

  /// The first wake-up ring after [t] that has not rung or been cancelled
  /// yet, vacations respected, within the next [days] days.
  DateTime? _firstWakeUpAfter(DateTime t, EngineState state, {int days = 2}) {
    final alarms = store.loadAlarms();
    final vacations = store.loadVacations();
    DateTime? first;
    for (var d = 0; d <= days; d++) {
      final day = DateTime(t.year, t.month, t.day + d);
      for (final r in ringsOn(day, alarms, vacations)) {
        final done = state.lastRing[r.alarm.id];
        if (!r.alarm.wakeUp || !r.at.isAfter(t)) continue;
        if (done != null && !done.isBefore(r.at)) continue;
        if (first == null || r.at.isBefore(first)) first = r.at;
      }
      if (first != null) return first;
    }
    return null;
  }

  /// Whether the main screen offers "I'm awake" now: within an hour before
  /// the next wake-up ring.
  bool get canSayAwake {
    final now = _now;
    final next = _firstWakeUpAfter(now, _load(now));
    return next != null && !now.isBefore(next.subtract(awakeWindow));
  }

  /// What "I'm awake" shows: the night's quiz, or a plain turn-off.
  RingScreen awakeScreen() => _quiz();

  /// [picked] was chosen on the "I'm awake" quiz. The right word ends the
  /// night and cancels the morning's wake-up alarms; a wrong one drops the
  /// word and makes the night a failure, with nothing to snooze.
  QuizOutcome? awakeAnswer(String picked) {
    final t = _now;
    final state = _load(t);
    final night = state.night;
    final word = night?.word;
    if (night == null || word == null) return null;
    if (picked != word) {
      if (!night.wrongPicks.contains(picked)) night.wrongPicks.add(picked);
      _save(state);
      return const QuizOutcome.wrong(snooze: null);
    }
    _cancelMorning(state, t);
    return _found(state, night, word, t);
  }

  /// "I'm awake" without a word: the night ends as "no word", or nothing is
  /// recorded when there was no night; the morning's alarms are cancelled.
  void awakeDismiss() {
    final t = _now;
    final state = _load(t);
    _cancelMorning(state, t);
    final night = state.night;
    if (night != null) {
      _end(state, night, NightResult.noWord, t);
    } else {
      _save(state);
    }
  }

  /// Cancels the rest of the coming morning's wake-up rings; reminder
  /// alarms still ring.
  void _cancelMorning(EngineState state, DateTime t) {
    final next = _firstWakeUpAfter(t, state);
    if (next == null) return;
    for (final r in ringsOn(next, store.loadAlarms(), store.loadVacations())) {
      if (!r.alarm.wakeUp || r.at.isBefore(next)) continue;
      state.lastRing[r.alarm.id] = r.at;
      state.alarmSnoozes.remove(r.alarm.id);
      if (r.alarm.oneTime) store.saveAlarm(r.alarm.copyWith(enabled: false));
    }
  }

  /// Whether the main screen offers "I'm in bed" now.
  bool get canSayInBed {
    final now = _now;
    final night = _current(_load(now), now);
    if (night != null) return !night.confirmed;
    final morning = _nextMorning(now);
    if (morning == null) return false;
    return !now.isBefore(morning.bedtime.subtract(inBedWindow));
  }

  /// The nag popped up. Outside bedtime, a nag that fired late is dropped.
  void nagShown({DateTime? at}) {
    final t = at ?? _now;
    final state = _load(t);
    final night = _bedtimeNight(state, t);
    if (night == null) return;
    night
      ..lastNag = t
      ..nagSnoozedUntil = null
      ..nagLine = nagLines.isEmpty
          ? null
          : state.lineDeck.next(nagLines, _random);
    _save(state);
  }

  /// The line on the nag last shown tonight; null without one.
  String? get nagLine {
    final now = _now;
    return _current(_load(now), now)?.nagLine;
  }

  /// The user is in bed, by Yes on the nag or the button on the main
  /// screen. Returns the word to remember; null outside bedtime or when
  /// tonight's bedtime was already given, and then nothing changes.
  String? inBed() {
    final t = _now;
    final state = _load(t);
    final night = _bedtimeNight(state, t);
    if (night == null || night.confirmed) return null;
    final word = state.deck.next(words, _random);
    night
      ..bedtime = t
      ..word = word
      ..nagSnoozedUntil = null;
    _save(state);
    return word;
  }

  /// The nag was snoozed for [length]; ignored outside bedtime.
  void snoozeNag(Duration length) {
    final t = _now;
    final state = _load(t);
    final night = _bedtimeNight(state, t);
    if (night == null) return;
    night.nagSnoozedUntil = t.add(length);
    _save(state);
  }

  /// Alarm [alarmId] started ringing.
  void ring(int alarmId, {DateTime? at}) {
    final t = at ?? _now;
    final state = _load(t);
    state.lastRing[alarmId] = t;
    state.alarmSnoozes.remove(alarmId);
    final alarm = _alarm(alarmId);
    if (alarm != null && alarm.oneTime && alarm.enabled) {
      store.saveAlarm(alarm.copyWith(enabled: false));
    }
    _save(state);
  }

  /// What the ringing alarm [alarmId] shows: the quiz on a wake-up alarm
  /// while the night's word waits, else a plain dismiss button.
  RingScreen screenFor(int alarmId) {
    final alarm = _alarm(alarmId);
    if (alarm == null || !alarm.wakeUp) return const RingScreen.dismiss();
    return _quiz();
  }

  /// The quiz for the night's word: the same options all night, minus the
  /// ones already picked wrongly; a plain dismiss without a word.
  RingScreen _quiz() {
    final state = _load(_now);
    final night = state.night;
    final word = night?.word;
    if (night == null || word == null) return const RingScreen.dismiss();
    final options = night.options ??= quizOptions(word, words, _random);
    _save(state);
    return RingScreen.quiz([
      for (final o in options)
        if (!night.wrongPicks.contains(o)) o,
    ]);
  }

  /// Alarm [alarmId] was snoozed, on its screen or, while the app was not
  /// running, from its notification; it rings again after the alarm
  /// snooze.
  void snoozeAlarm(int alarmId, {DateTime? at}) {
    final t = at ?? _now;
    final state = _load(t);
    state.alarmSnoozes[alarmId] = t.add(store.loadSettings().alarmSnooze);
    _save(state);
  }

  /// [picked] was chosen on the quiz of alarm [alarmId]. The right word
  /// ends the night; a wrong one snoozes the alarm, drops that word from
  /// the next quiz and makes the night a failure.
  QuizOutcome? answer(int alarmId, String picked) {
    final t = _now;
    final state = _load(t);
    state.alarmSnoozes.remove(alarmId);
    final night = state.night;
    final word = night?.word;
    if (night == null || word == null) {
      _save(state);
      return null;
    }
    if (picked != word) {
      final snooze = store.loadSettings().alarmSnooze;
      if (!night.wrongPicks.contains(picked)) night.wrongPicks.add(picked);
      state.alarmSnoozes[alarmId] = t.add(snooze);
      _save(state);
      return QuizOutcome.wrong(snooze: snooze);
    }
    return _found(state, night, word, t);
  }

  /// The right word ends the night: a success, or a failure graded by the
  /// wrong picks before it.
  QuizOutcome _found(
    EngineState state,
    OpenNight night,
    String word,
    DateTime t,
  ) {
    final wrong = night.wrongPicks.length;
    _end(
      state,
      night,
      wrong == 0 ? NightResult.success : NightResult.failure,
      t,
    );
    return QuizOutcome.right(
      wrongPicks: wrong,
      word: word,
      stats: QuizStats.of(store.loadRecords()),
    );
  }

  /// Whether the main screen shows the hint card.
  bool get pendingHint => _load(_now).pendingHint;

  /// The hint card was read.
  void dismissHint() {
    final state = _load(_now)..pendingHint = false;
    _save(state);
  }

  /// Alarm [alarmId] was turned off with the plain dismiss button. On a
  /// wake-up alarm after a night without a word, that ends the night.
  void dismiss(int alarmId) {
    final t = _now;
    final state = _load(t);
    state.alarmSnoozes.remove(alarmId);
    final night = state.night;
    if (night != null && night.word == null && _isWakeUp(alarmId)) {
      _end(state, night, NightResult.noWord, t);
    } else {
      _save(state);
    }
  }

  /// Alarm [alarmId] rang unanswered until its timeout. When no other
  /// wake-up alarm of the morning is left, the night ends: missed, or a
  /// failure when a wrong word was already picked.
  void timeout(int alarmId, {DateTime? at}) {
    final t = at ?? _now;
    final state = _load(t);
    state.alarmSnoozes.remove(alarmId);
    final night = state.night;
    final otherSnoozed = state.alarmSnoozes.keys.any(_isWakeUp);
    final laterToday = wakeUpLaterToday(
      t,
      store.loadAlarms(),
      store.loadVacations(),
      exceptAlarmId: alarmId,
    );
    if (night != null && _isWakeUp(alarmId) && !otherSnoozed && !laterToday) {
      final failed = night.wrongPicks.isNotEmpty;
      _end(state, night, failed ? NightResult.failure : NightResult.missed, t);
      // No page follows a timeout: a due hint waits for the main screen.
      if (failed && QuizStats.of(store.loadRecords()).showHint) {
        final after = _load(t)..pendingHint = true;
        _save(after);
      }
    } else {
      _save(state);
    }
  }

  /// The state as of [t]: a word nobody was asked about within a day is
  /// gone, and the night with it.
  EngineState _load(DateTime t) {
    final state = store.loadState();
    final night = state.night;
    if (night != null &&
        state.alarmSnoozes.isEmpty &&
        t.difference(night.effectiveBedtime) > wordLifetime) {
      state.night = null;
    }
    return state;
  }

  /// The open night, unless its morning is over: a new evening's nag or
  /// "I'm in bed" after that morning starts a new night.
  OpenNight? _current(EngineState state, DateTime t) {
    final night = state.night;
    final wake = night?.expectedWake;
    if (night == null || (wake != null && t.isAfter(wake))) return null;
    return night;
  }

  /// The night a bedtime action at [t] belongs to: the open one, else a new
  /// one from the "I'm in bed" window on; null outside bedtime, so a stray
  /// action after the morning started cannot open the next night early.
  OpenNight? _bedtimeNight(EngineState state, DateTime t) {
    final current = _current(state, t);
    if (current != null) return current;
    final morning = _nextMorning(t);
    if (morning == null || t.isBefore(morning.bedtime.subtract(inBedWindow))) {
      return null;
    }
    return state.night = _openNight(t);
  }

  void _save(EngineState state) => store.saveState(state);

  void _end(
    EngineState state,
    OpenNight night,
    NightResult result,
    DateTime t,
  ) {
    store.addRecord(
      NightRecord(
        plannedBedtime: night.plannedBedtime,
        bedtime: night.effectiveBedtime,
        bedtimeAssumed: !night.confirmed,
        end: t,
        result: result,
        word: night.word,
        wrongPicks: night.wrongPicks.length,
      ),
    );
    state.night = null;
    _save(state);
  }

  Morning? _nextMorning(DateTime t) => nextMorning(
    t,
    store.loadAlarms(),
    store.loadVacations(),
    store.loadSettings(),
  );

  OpenNight _openNight(DateTime t) {
    final m = _nextMorning(t);
    return OpenNight(
      plannedBedtime: m?.bedtime ?? t,
      expectedWake: m?.firstWakeUp,
    );
  }

  Alarm? _alarm(int id) {
    for (final a in store.loadAlarms()) {
      if (a.id == id) return a;
    }
    return null;
  }

  bool _isWakeUp(int alarmId) => _alarm(alarmId)?.wakeUp ?? false;
}

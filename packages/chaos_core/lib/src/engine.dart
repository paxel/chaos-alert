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

/// What the platform has to schedule next.
class Plan {
  const Plan({this.nag, this.rings = const []});

  /// When the bedtime nag pops up; a time in the past means now.
  final DateTime? nag;

  /// The next ring of every alarm that rings again, snoozes included.
  final List<PlannedRing> rings;
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
  const QuizOutcome({
    required this.correct,
    required this.word,
    required this.stats,
  });

  final bool correct;

  /// The right word.
  final String word;
  final QuizStats stats;
}

/// Every rule of the night. Each event reads the store, applies the rule
/// and writes the store back, so the engine holds no state of its own and
/// can be rebuilt whenever the app starts.
class Engine {
  Engine({
    required this.store,
    required this.words,
    required this.clock,
    Random? random,
  }) : _random = random ?? Random();

  final Store store;
  final List<String> words;
  final DateTime Function() clock;
  final Random _random;

  DateTime get _now => clock();

  /// What to schedule now.
  Plan plan() {
    final state = _load();
    final now = _now;
    final alarms = store.loadAlarms();
    final vacations = store.loadVacations();

    DateTime? nag;
    final night = state.night;
    if (night == null) {
      nag = nextMorning(now, alarms, vacations, store.loadSettings())?.bedtime;
    } else if (!night.confirmed) {
      final snoozed = night.nagSnoozedUntil;
      final wake = nextMorning(now, alarms, vacations, store.loadSettings());
      if (snoozed != null &&
          (wake == null || snoozed.isBefore(wake.firstWakeUp))) {
        nag = snoozed;
      }
    }

    final byId = {for (final a in alarms) a.id: a};
    state.alarmSnoozes.removeWhere((id, _) => !byId.containsKey(id));
    final rings = <PlannedRing>[];
    for (final a in alarms) {
      final last = state.lastRing[a.id];
      final after = last != null && last.isAfter(now) ? last : now;
      var at = nextRingOf(a, after, vacations);
      final snooze = state.alarmSnoozes[a.id];
      if (snooze != null && (at == null || snooze.isBefore(at))) at = snooze;
      if (at != null) rings.add(PlannedRing(a.id, at));
    }
    rings.sort((a, b) => a.at.compareTo(b.at));
    _save(state);
    return Plan(nag: nag, rings: rings);
  }

  /// Whether the main screen offers "I'm in bed" now.
  bool get canSayInBed {
    final night = _load().night;
    if (night != null) return !night.confirmed;
    final morning = _nextMorning();
    if (morning == null) return false;
    return !_now.isBefore(morning.bedtime.subtract(inBedWindow));
  }

  /// The nag popped up.
  void nagShown() {
    final state = _load();
    final night = state.night ??= _openNight();
    night
      ..lastNag = _now
      ..nagSnoozedUntil = null;
    _save(state);
  }

  /// The user is in bed, by Yes on the nag or the button on the main
  /// screen. Returns the word to remember.
  String inBed() {
    final state = _load();
    final night = state.night ??= _openNight();
    if (night.confirmed) throw StateError('already in bed tonight');
    final word = state.deck.next(words, _random);
    night
      ..bedtime = _now
      ..word = word
      ..nagSnoozedUntil = null;
    _save(state);
    return word;
  }

  /// The nag was snoozed for [length].
  void snoozeNag(Duration length) {
    final state = _load();
    final night = state.night ??= _openNight();
    night.nagSnoozedUntil = _now.add(length);
    _save(state);
  }

  /// Alarm [alarmId] started ringing.
  RingScreen ring(int alarmId) {
    final state = _load();
    final now = _now;
    state.lastRing[alarmId] = now;
    state.alarmSnoozes.remove(alarmId);
    final alarm = _alarm(alarmId);
    if (alarm != null && alarm.oneTime && alarm.enabled) {
      store.saveAlarm(alarm.copyWith(enabled: false));
    }
    _save(state);
    final word = state.night?.word;
    if (alarm == null || !alarm.wakeUp || word == null) {
      return const RingScreen.dismiss();
    }
    return RingScreen.quiz(quizOptions(word, words, _random));
  }

  /// Alarm [alarmId] was snoozed; it rings again after the alarm snooze.
  void snoozeAlarm(int alarmId) {
    final state = _load();
    state.alarmSnoozes[alarmId] = _now.add(store.loadSettings().alarmSnooze);
    _save(state);
  }

  /// [picked] was chosen on the quiz of alarm [alarmId]. Ends the night.
  QuizOutcome? answer(int alarmId, String picked) {
    final state = _load();
    state.alarmSnoozes.remove(alarmId);
    final night = state.night;
    final word = night?.word;
    if (night == null || word == null) {
      _save(state);
      return null;
    }
    final correct = picked == word;
    _end(state, night, correct ? NightResult.success : NightResult.failure);
    return QuizOutcome(
      correct: correct,
      word: word,
      stats: QuizStats.of(store.loadRecords()),
    );
  }

  /// Alarm [alarmId] was turned off with the plain dismiss button. On a
  /// wake-up alarm after a night without a word, that ends the night.
  void dismiss(int alarmId) {
    final state = _load();
    state.alarmSnoozes.remove(alarmId);
    final night = state.night;
    if (night != null && night.word == null && _isWakeUp(alarmId)) {
      _end(state, night, NightResult.noWord);
    } else {
      _save(state);
    }
  }

  /// Alarm [alarmId] rang unanswered until its timeout. When no other
  /// wake-up alarm of the morning is left, the night is missed.
  void timeout(int alarmId) {
    final state = _load();
    state.alarmSnoozes.remove(alarmId);
    final night = state.night;
    final now = _now;
    final otherSnoozed = state.alarmSnoozes.keys.any(_isWakeUp);
    final laterToday = wakeUpLaterToday(
      now,
      store.loadAlarms(),
      store.loadVacations(),
      exceptAlarmId: alarmId,
    );
    if (night != null && _isWakeUp(alarmId) && !otherSnoozed && !laterToday) {
      _end(state, night, NightResult.missed);
    } else {
      _save(state);
    }
  }

  EngineState _load() {
    final state = store.loadState();
    final night = state.night;
    // A word nobody was asked about within a day is gone; the night with it.
    if (night != null &&
        state.alarmSnoozes.isEmpty &&
        _now.difference(night.effectiveBedtime) > wordLifetime) {
      state.night = null;
    }
    return state;
  }

  void _save(EngineState state) => store.saveState(state);

  void _end(EngineState state, OpenNight night, NightResult result) {
    store.addRecord(
      NightRecord(
        plannedBedtime: night.plannedBedtime,
        bedtime: night.effectiveBedtime,
        bedtimeAssumed: !night.confirmed,
        end: _now,
        result: result,
        word: night.word,
      ),
    );
    state.night = null;
    _save(state);
  }

  Morning? _nextMorning() => nextMorning(
    _now,
    store.loadAlarms(),
    store.loadVacations(),
    store.loadSettings(),
  );

  OpenNight _openNight() =>
      OpenNight(plannedBedtime: _nextMorning()?.bedtime ?? _now);

  Alarm? _alarm(int id) {
    for (final a in store.loadAlarms()) {
      if (a.id == id) return a;
    }
    return null;
  }

  bool _isWakeUp(int alarmId) => _alarm(alarmId)?.wakeUp ?? false;
}

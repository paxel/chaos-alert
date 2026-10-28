import 'model.dart';

/// How a night's quiz went.
enum NightResult {
  /// The right word was picked.
  success,

  /// At least one wrong word was picked before the right one, or before
  /// the alarm gave up.
  failure,

  /// No word was shown that night, so there was no quiz.
  noWord,

  /// Every wake-up alarm of the morning timed out unanswered.
  missed,
}

/// One observed night, from bedtime (in bed) to the end of the night (up),
/// with the supposed sleep from asleep to awake inside it.
class NightRecord {
  const NightRecord({
    required this.plannedBedtime,
    required this.bedtime,
    required this.bedtimeAssumed,
    required this.end,
    required this.result,
    this.word,
    this.wrongPicks = 0,
    this.asleep,
    this.asleepAssumed = false,
    this.awake,
  });

  /// The bedtime the nag was planned for.
  final DateTime plannedBedtime;

  /// When the user said they were in bed, or the last unanswered nag.
  final DateTime bedtime;

  /// Whether [bedtime] comes from an unanswered nag rather than a Yes.
  final bool bedtimeAssumed;

  /// When the night ended (up): the answered or dismissed wake-up alarm,
  /// "I'm up", the first ring after an early quiz that timed out, or the
  /// last timeout of a missed morning.
  final DateTime end;
  final NightResult result;
  final String? word;

  /// How many wrong words were picked, 0 to 3; how bad a failure was.
  final int wrongPicks;

  /// When the word was shown, or assumed from the last unanswered nag;
  /// null on nights recorded before asleep was kept apart from [bedtime].
  final DateTime? asleep;

  /// Whether [asleep] comes from an unanswered nag rather than the word.
  final bool asleepAssumed;

  /// When the quiz was taken early with "I'm awake"; null when awake and
  /// up were the same moment.
  final DateTime? awake;

  /// The morning this night belongs to.
  DateTime get morning => dateOf(end);

  /// When the supposed sleep started.
  DateTime get asleepAt => asleep ?? bedtime;

  /// When the supposed sleep ended.
  DateTime get awakeAt => awake ?? end;

  /// The time in bed, from in bed to up.
  Duration get inBed => end.difference(bedtime);

  /// The supposed sleep, from asleep to awake.
  Duration get asleepFor => awakeAt.difference(asleepAt);
}

/// How many results the strip on the failure page shows.
const stripLength = 30;

/// The failure streak at which the hint appears.
const hintStreak = 5;

/// Quiz statistics over all nights.
class QuizStats {
  const QuizStats({
    required this.streak,
    required this.failures,
    required this.successes,
    required this.strip,
  });

  /// [records] in any order.
  factory QuizStats.of(Iterable<NightRecord> records) {
    final sorted = records.toList()..sort((a, b) => a.end.compareTo(b.end));
    var streak = 0;
    var failures = 0;
    var successes = 0;
    for (final r in sorted) {
      switch (r.result) {
        case NightResult.success:
          successes++;
          streak = 0;
        case NightResult.failure:
          failures++;
          streak++;
        case NightResult.noWord || NightResult.missed:
          break;
      }
    }
    final strip = sorted
        .skip(sorted.length > stripLength ? sorted.length - stripLength : 0)
        .toList();
    return QuizStats(
      streak: streak,
      failures: failures,
      successes: successes,
      strip: strip,
    );
  }

  /// Failures in a row; nights without a word and missed nights neither
  /// extend nor reset it.
  final int streak;
  final int failures;
  final int successes;

  /// The last [stripLength] nights, oldest first.
  final List<NightRecord> strip;

  /// Whether the "get it checked" hint belongs on this failure page: only
  /// on the failure that makes the streak reach [hintStreak], so once per
  /// streak.
  bool get showHint => streak == hintStreak;
}

/// The averages of a timeline period.
class TimelineSummary {
  const TimelineSummary({
    this.averageInBed,
    this.averageAsleep,
    this.averageBedtime,
  });

  factory TimelineSummary.of(Iterable<NightRecord> records) {
    final list = records.toList();
    if (list.isEmpty) return const TimelineSummary();
    Duration average(Duration Function(NightRecord) of) =>
        list.fold(Duration.zero, (sum, r) => sum + of(r)) ~/ list.length;
    // Bedtimes around midnight average on a clock that starts at noon, so
    // 23:00 and 01:00 give midnight, not noon.
    final fromNoon =
        list
            .map((r) => (r.bedtime.hour * 60 + r.bedtime.minute + 720) % 1440)
            .reduce((a, b) => a + b) ~/
        list.length;
    final minutes = (fromNoon + 720) % 1440;
    return TimelineSummary(
      averageInBed: average((r) => r.inBed),
      averageAsleep: average((r) => r.asleepFor),
      averageBedtime: ClockTime(minutes ~/ 60, minutes % 60),
    );
  }

  final Duration? averageInBed;
  final Duration? averageAsleep;
  final ClockTime? averageBedtime;
}

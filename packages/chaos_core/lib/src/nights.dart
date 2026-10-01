import 'model.dart';

/// How a night's quiz went.
enum NightResult {
  /// The right word was picked.
  success,

  /// A wrong word was picked.
  failure,

  /// No word was shown that night, so there was no quiz.
  noWord,

  /// Every wake-up alarm of the morning timed out unanswered.
  missed,
}

/// One observed night, from bedtime to the end of the night.
class NightRecord {
  const NightRecord({
    required this.plannedBedtime,
    required this.bedtime,
    required this.bedtimeAssumed,
    required this.end,
    required this.result,
    this.word,
  });

  /// The bedtime the nag was planned for.
  final DateTime plannedBedtime;

  /// When the user said they were in bed, or the last unanswered nag.
  final DateTime bedtime;

  /// Whether [bedtime] comes from an unanswered nag rather than a Yes.
  final bool bedtimeAssumed;

  /// When the first answered wake-up alarm was turned off, or the last
  /// timeout of a missed morning.
  final DateTime end;
  final NightResult result;
  final String? word;

  /// The morning this night belongs to.
  DateTime get morning => dateOf(end);

  Duration get inBed => end.difference(bedtime);
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
    final strip = [
      for (final r in sorted.skip(
        sorted.length > stripLength ? sorted.length - stripLength : 0,
      ))
        r.result,
    ];
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

  /// The results of the last [stripLength] nights, oldest first.
  final List<NightResult> strip;

  /// Whether the "get it checked" hint belongs on this failure page: only
  /// on the failure that makes the streak reach [hintStreak], so once per
  /// streak.
  bool get showHint => streak == hintStreak;
}

/// The averages of a timeline period.
class TimelineSummary {
  const TimelineSummary({this.averageInBed, this.averageBedtime});

  factory TimelineSummary.of(Iterable<NightRecord> records) {
    final list = records.toList();
    if (list.isEmpty) return const TimelineSummary();
    final inBed =
        list.fold(Duration.zero, (sum, r) => sum + r.inBed) ~/ list.length;
    // Bedtimes around midnight average on a clock that starts at noon, so
    // 23:00 and 01:00 give midnight, not noon.
    final fromNoon =
        list
            .map((r) => (r.bedtime.hour * 60 + r.bedtime.minute + 720) % 1440)
            .reduce((a, b) => a + b) ~/
        list.length;
    final minutes = (fromNoon + 720) % 1440;
    return TimelineSummary(
      averageInBed: inBed,
      averageBedtime: ClockTime(minutes ~/ 60, minutes % 60),
    );
  }

  final Duration? averageInBed;
  final ClockTime? averageBedtime;
}

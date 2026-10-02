import 'package:chaos_core/chaos_core.dart';
import 'package:test/test.dart';

/// A night ending on October [day] with [result], in bed 22:30 to 06:30.
NightRecord night(int day, NightResult result) => NightRecord(
  plannedBedtime: DateTime(2026, 10, day - 1, 22, 30),
  bedtime: DateTime(2026, 10, day - 1, 22, 30),
  bedtimeAssumed: false,
  end: DateTime(2026, 10, day, 6, 30),
  result: result,
  word: 'verdict',
);

void main() {
  const s = NightResult.success;
  const f = NightResult.failure;
  const n = NightResult.noWord;
  const m = NightResult.missed;

  QuizStats stats(List<NightResult> results) => QuizStats.of([
    for (var i = 0; i < results.length; i++) night(2 + i, results[i]),
  ]);

  group('streak', () {
    test('counts failures in a row since the last success', () {
      expect(stats([f, s, f, f]).streak, 2);
      expect(stats([f, f, s]).streak, 0);
    });

    test('skips nights without a word and missed nights', () {
      expect(stats([f, n, f, m, f]).streak, 3);
      expect(stats([s, n, m]).streak, 0);
    });

    test('totals count failures and successes only', () {
      final st = stats([s, f, n, m, f]);
      expect(st.failures, 2);
      expect(st.successes, 1);
    });
  });

  group('hint', () {
    test('shows on the failure that makes five in a row', () {
      expect(stats([f, f, f, f]).showHint, isFalse);
      expect(stats([f, f, f, f, f]).showHint, isTrue);
      expect(stats([f, f, n, f, f, m, f]).showHint, isTrue);
    });

    test('shows once per streak, again only after a success', () {
      expect(stats([f, f, f, f, f, f]).showHint, isFalse);
      expect(stats([f, f, f, f, f, s, f, f, f, f, f]).showHint, isTrue);
    });
  });

  test('the strip holds the last 30 nights, oldest first', () {
    final results = [
      for (var i = 0; i < 25; i++) s,
      for (var i = 0; i < 10; i++) f,
    ];
    final records = [
      for (var i = 0; i < results.length; i++)
        NightRecord(
          plannedBedtime: DateTime(2026, 9, 1 + i, 22),
          bedtime: DateTime(2026, 9, 1 + i, 22),
          bedtimeAssumed: false,
          end: DateTime(2026, 9, 2 + i, 6),
          result: results[i],
        ),
    ].reversed;
    final strip = QuizStats.of(records).strip;
    expect(strip, hasLength(30));
    expect(strip.first.result, s);
    expect(strip.last.result, f);
    expect(strip.where((r) => r.result == f), hasLength(10));
  });

  group('timeline summary', () {
    test('averages time in bed and bedtime across midnight', () {
      final records = [
        NightRecord(
          plannedBedtime: DateTime(2026, 10, 4, 22, 30),
          bedtime: DateTime(2026, 10, 4, 23),
          bedtimeAssumed: false,
          end: DateTime(2026, 10, 5, 7),
          result: s,
        ),
        NightRecord(
          plannedBedtime: DateTime(2026, 10, 5, 22, 30),
          bedtime: DateTime(2026, 10, 6, 1),
          bedtimeAssumed: true,
          end: DateTime(2026, 10, 6, 7),
          result: f,
        ),
      ];
      final summary = TimelineSummary.of(records);
      expect(summary.averageInBed, const Duration(hours: 7));
      expect(summary.averageBedtime, const ClockTime(0, 0));
    });

    test('is empty without nights', () {
      final summary = TimelineSummary.of(const []);
      expect(summary.averageInBed, isNull);
      expect(summary.averageBedtime, isNull);
    });
  });
}

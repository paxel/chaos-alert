import 'package:chaos_alert/src/results.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A failed night, by wrong picks or, on the typing quiz, by typos.
NightRecord failure({int wrongPicks = 0, int? typedOff}) => NightRecord(
  plannedBedtime: DateTime(2026, 10, 5, 22, 30),
  bedtime: DateTime(2026, 10, 5, 22, 30),
  bedtimeAssumed: false,
  end: DateTime(2026, 10, 6, 6, 30),
  result: NightResult.failure,
  wrongPicks: wrongPicks,
  typedOff: typedOff,
);

void main() {
  const light = Color(0xFFEF9A9A);
  const medium = Color(0xFFE53935);
  const dark = Color(0xFFB71C1C);

  test('a failure is shaded by its wrong picks', () {
    expect(nightColor(failure(wrongPicks: 1)), light);
    expect(nightColor(failure(wrongPicks: 2)), medium);
    expect(nightColor(failure(wrongPicks: 3)), dark);
  });

  test('a failed typing quiz is shaded by how far off it was', () {
    expect(nightColor(failure(typedOff: 3)), light);
    expect(nightColor(failure(typedOff: 4)), medium);
    expect(nightColor(failure(typedOff: 7)), dark);
  });
}

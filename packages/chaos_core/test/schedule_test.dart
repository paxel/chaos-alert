import 'package:chaos_core/chaos_core.dart';
import 'package:test/test.dart';

const weekdays = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
};

// 2026-10-05 is a Monday.
final monday = DateTime(2026, 10, 5);
DateTime at(int day, int h, [int m = 0]) => DateTime(2026, 10, day, h, m);

void main() {
  const settings = Settings();

  group('rings', () {
    test('a repeating alarm rings on its weekdays only', () {
      const a = Alarm(id: 1, time: ClockTime(6, 30), weekdays: weekdays);
      expect(ringOn(a, monday, []), at(5, 6, 30));
      expect(ringOn(a, DateTime(2026, 10, 10), []), isNull); // Saturday
    });

    test('a one-time alarm rings on its date only', () {
      final a = Alarm(id: 1, time: const ClockTime(5, 0), date: monday);
      expect(ringOn(a, monday, []), at(5, 5));
      expect(ringOn(a, DateTime(2026, 10, 6), []), isNull);
    });

    test('a disabled alarm never rings', () {
      const a = Alarm(
        id: 1,
        time: ClockTime(6, 30),
        weekdays: weekdays,
        enabled: false,
      );
      expect(ringOn(a, monday, []), isNull);
    });

    test('a vacation silences repeating alarms but not one-time alarms', () {
      final vacation = Vacation(id: 1, from: monday, to: at(9, 0));
      const repeating = Alarm(
        id: 1,
        time: ClockTime(6, 30),
        weekdays: weekdays,
      );
      final once = Alarm(id: 2, time: const ClockTime(8, 0), date: monday);
      expect(ringOn(repeating, monday, [vacation]), isNull);
      expect(ringOn(repeating, at(9, 0), [vacation]), isNull);
      expect(ringOn(repeating, at(12, 0), [vacation]), at(12, 6, 30));
      expect(ringOn(once, monday, [vacation]), at(5, 8));
    });

    test('the next ring skips past the given moment', () {
      const a = Alarm(id: 1, time: ClockTime(6, 30), weekdays: weekdays);
      expect(nextRingOf(a, at(5, 6, 30), []), at(6, 6, 30));
      expect(nextRingOf(a, at(9, 7), []), at(12, 6, 30));
    });
  });

  group('bedtime', () {
    test('is the earliest wake-up alarm of the morning minus the sleep '
        'length', () {
      final alarms = [
        const Alarm(id: 1, time: ClockTime(6, 30), weekdays: weekdays),
        Alarm(id: 2, time: const ClockTime(6, 0), date: at(6, 0)),
      ];
      final m = nextMorning(at(5, 12), alarms, [], settings)!;
      expect(m.firstWakeUp, at(6, 6));
      expect(m.bedtime, at(5, 22));
    });

    test('ignores alarms whose wake-up switch is off', () {
      final alarms = [
        const Alarm(id: 1, time: ClockTime(6, 30), weekdays: weekdays),
        const Alarm(
          id: 2,
          time: ClockTime(5, 0),
          weekdays: weekdays,
          wakeUp: false,
        ),
      ];
      final m = nextMorning(at(5, 12), alarms, [], settings)!;
      expect(m.bedtime, at(5, 22, 30));
    });

    test('follows the sleep length setting', () {
      const alarms = [Alarm(id: 1, time: ClockTime(6, 30), weekdays: weekdays)];
      final m = nextMorning(
        at(5, 12),
        alarms,
        [],
        settings.copyWith(sleepLength: const Duration(hours: 7, minutes: 15)),
      )!;
      expect(m.bedtime, at(5, 23, 15));
    });

    test('skips mornings without a wake-up alarm', () {
      const alarms = [Alarm(id: 1, time: ClockTime(6, 30), weekdays: weekdays)];
      // Friday noon: Saturday and Sunday are free, Monday is next.
      final m = nextMorning(at(9, 12), alarms, [], settings)!;
      expect(m.firstWakeUp, at(12, 6, 30));
    });

    test('skips a morning whose first wake-up alarm has already rung', () {
      final alarms = [
        const Alarm(id: 1, time: ClockTime(6, 30), weekdays: weekdays),
        const Alarm(id: 2, time: ClockTime(6, 45), weekdays: weekdays),
      ];
      final m = nextMorning(at(5, 6, 40), alarms, [], settings)!;
      expect(m.firstWakeUp, at(6, 6, 30));
    });

    test("skips a morning whose wake-up alarms \"I'm awake\" turned off", () {
      const alarms = [Alarm(id: 1, time: ClockTime(6, 30), weekdays: weekdays)];
      final m = nextMorning(
        at(6, 6, 5),
        alarms,
        [],
        settings,
        lastRing: {1: at(6, 6, 30)},
      )!;
      expect(m.firstWakeUp, at(7, 6, 30));
    });

    test('a night belongs to the morning it ends in: the vacation mornings '
        'have no nag, the morning after does', () {
      const alarms = [Alarm(id: 1, time: ClockTime(6, 30), weekdays: weekdays)];
      final vacation = Vacation(id: 1, from: monday, to: at(9, 0));
      // Sunday evening before the vacation: the next nag is for Monday 12th,
      // so it comes on Sunday 11th.
      final m = nextMorning(at(4, 12), alarms, [vacation], settings)!;
      expect(m.firstWakeUp, at(12, 6, 30));
      expect(m.bedtime, at(11, 22, 30));
    });

    test('a one-time alarm on a vacation morning gets no nag', () {
      final alarms = [Alarm(id: 1, time: const ClockTime(7, 0), date: monday)];
      final vacation = Vacation(id: 1, from: monday, to: monday);
      expect(nextMorning(at(4, 12), alarms, [vacation], settings), isNull);
    });

    test('there is no morning without any wake-up alarm', () {
      expect(nextMorning(at(4, 12), const [], [], settings), isNull);
    });
  });

  test('a later wake-up ring today is seen, other kinds are not', () {
    final alarms = [
      const Alarm(id: 1, time: ClockTime(6, 30), weekdays: weekdays),
      const Alarm(id: 2, time: ClockTime(6, 45), weekdays: weekdays),
      const Alarm(
        id: 3,
        time: ClockTime(7, 0),
        weekdays: weekdays,
        wakeUp: false,
      ),
    ];
    expect(wakeUpLaterToday(at(5, 6, 40), alarms, []), isTrue);
    expect(wakeUpLaterToday(at(5, 6, 50), alarms, []), isFalse);
  });
}

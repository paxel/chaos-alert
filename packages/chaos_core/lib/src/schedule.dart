import 'model.dart';

/// How far ahead the schedule looks for the next ring or morning.
const _horizonDays = 400;

/// When [alarm] rings on the morning of [day], or null if it does not.
///
/// Vacations silence repeating alarms only; one-time alarms always ring.
DateTime? ringOn(Alarm alarm, DateTime day, List<Vacation> vacations) {
  if (!alarm.enabled) return null;
  final d = dateOf(day);
  final date = alarm.date;
  if (date != null) {
    return dateOf(date) == d ? alarm.time.on(d) : null;
  }
  if (!alarm.weekdays.contains(d.weekday)) return null;
  if (vacations.any((v) => v.covers(d))) return null;
  return alarm.time.on(d);
}

/// One ring of one alarm.
class Ring {
  const Ring(this.alarm, this.at);

  final Alarm alarm;
  final DateTime at;
}

/// Every ring on the morning of [day], earliest first.
List<Ring> ringsOn(DateTime day, List<Alarm> alarms, List<Vacation> vacations) {
  final rings = [
    for (final a in alarms)
      if (ringOn(a, day, vacations) case final at?) Ring(a, at),
  ]..sort((a, b) => a.at.compareTo(b.at));
  return rings;
}

/// A morning the bedtime nag is planned for.
class Morning {
  const Morning({required this.firstWakeUp, required this.bedtime});

  /// The earliest wake-up ring of the morning.
  final DateTime firstWakeUp;

  /// [firstWakeUp] minus the sleep length.
  final DateTime bedtime;

  DateTime get day => dateOf(firstWakeUp);
}

/// The next morning that gets a bedtime nag: the first day whose earliest
/// wake-up ring is still ahead of [now] and which is not a vacation morning.
///
/// [lastRing] holds each alarm's last ring; a morning whose earliest
/// wake-up ring is already in it was turned off by "I'm awake" and is over.
Morning? nextMorning(
  DateTime now,
  List<Alarm> alarms,
  List<Vacation> vacations,
  Settings settings, {
  Map<int, DateTime> lastRing = const {},
}) {
  final today = dateOf(now);
  for (var i = 0; i <= _horizonDays; i++) {
    final day = DateTime(today.year, today.month, today.day + i);
    if (vacations.any((v) => v.covers(day))) continue;
    final first = ringsOn(
      day,
      alarms,
      vacations,
    ).where((r) => r.alarm.wakeUp).firstOrNull;
    if (first == null || !first.at.isAfter(now)) continue;
    final done = lastRing[first.alarm.id];
    if (done != null && !done.isBefore(first.at)) continue;
    return Morning(
      firstWakeUp: first.at,
      bedtime: first.at.subtract(settings.sleepLength),
    );
  }
  return null;
}

/// The next ring of [alarm] strictly after [after], or null.
DateTime? nextRingOf(Alarm alarm, DateTime after, List<Vacation> vacations) {
  final start = dateOf(after);
  for (var i = 0; i <= _horizonDays; i++) {
    final day = DateTime(start.year, start.month, start.day + i);
    final at = ringOn(alarm, day, vacations);
    if (at != null && at.isAfter(after)) return at;
  }
  return null;
}

/// Whether a wake-up alarm other than [exceptAlarmId] still rings later on
/// the day of [now].
bool wakeUpLaterToday(
  DateTime now,
  List<Alarm> alarms,
  List<Vacation> vacations, {
  int? exceptAlarmId,
}) => ringsOn(now, alarms, vacations).any(
  (r) => r.alarm.wakeUp && r.alarm.id != exceptAlarmId && r.at.isAfter(now),
);

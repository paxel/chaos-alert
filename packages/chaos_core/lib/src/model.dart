/// A time on the clock, without a date.
class ClockTime {
  const ClockTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  final int hour;
  final int minute;

  /// This time on [day] (the date part of [day] only).
  DateTime on(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  int get minutesOfDay => hour * 60 + minute;

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// The date part of [t], at midnight local time.
DateTime dateOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// An alarm: repeating on a set of weekdays, or once on [date].
class Alarm {
  const Alarm({
    required this.id,
    required this.time,
    this.weekdays = const {},
    this.date,
    this.enabled = true,
    this.wakeUp = true,
  });

  final int id;
  final ClockTime time;

  /// [DateTime.monday] … [DateTime.sunday]; empty for a one-time alarm.
  final Set<int> weekdays;

  /// The day of a one-time alarm; null for a repeating one.
  final DateTime? date;
  final bool enabled;

  /// Only wake-up alarms set the bedtime, carry the quiz and end the night.
  final bool wakeUp;

  bool get oneTime => date != null;

  Alarm copyWith({
    int? id,
    ClockTime? time,
    Set<int>? weekdays,
    DateTime? date,
    bool clearDate = false,
    bool? enabled,
    bool? wakeUp,
  }) => Alarm(
    id: id ?? this.id,
    time: time ?? this.time,
    weekdays: weekdays ?? this.weekdays,
    date: clearDate ? null : (date ?? this.date),
    enabled: enabled ?? this.enabled,
    wakeUp: wakeUp ?? this.wakeUp,
  );
}

/// A vacation over the mornings [from] to [to], both included.
class Vacation {
  Vacation({required this.id, required DateTime from, required DateTime to})
    : from = dateOf(from),
      to = dateOf(to);

  final int id;
  final DateTime from;
  final DateTime to;

  /// Whether the morning of [day] lies in this vacation.
  bool covers(DateTime day) {
    final d = dateOf(day);
    return !d.isBefore(from) && !d.isAfter(to);
  }
}

/// Everything the user can set that is not an alarm or a vacation.
class Settings {
  const Settings({
    this.sleepLength = const Duration(hours: 8),
    this.nagSnooze = const Duration(minutes: 10),
    this.alarmSnooze = const Duration(minutes: 9),
    this.alarmTimeout = const Duration(minutes: 10),
    this.lowVolume = 0.2,
    this.mediumVolume = 0.5,
    this.chime = true,
  });

  final Duration sleepLength;
  final Duration nagSnooze;
  final Duration alarmSnooze;
  final Duration alarmTimeout;

  /// Share of the alarm stream's maximum, 0 to 1.
  final double lowVolume;
  final double mediumVolume;

  /// Whether the bedtime nag plays its short chime.
  final bool chime;

  Settings copyWith({
    Duration? sleepLength,
    Duration? nagSnooze,
    Duration? alarmSnooze,
    Duration? alarmTimeout,
    double? lowVolume,
    double? mediumVolume,
    bool? chime,
  }) => Settings(
    sleepLength: sleepLength ?? this.sleepLength,
    nagSnooze: nagSnooze ?? this.nagSnooze,
    alarmSnooze: alarmSnooze ?? this.alarmSnooze,
    alarmTimeout: alarmTimeout ?? this.alarmTimeout,
    lowVolume: lowVolume ?? this.lowVolume,
    mediumVolume: mediumVolume ?? this.mediumVolume,
    chime: chime ?? this.chime,
  );
}

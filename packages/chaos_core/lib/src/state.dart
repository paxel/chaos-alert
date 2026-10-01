import 'words.dart';

/// The night between the first nag (or "I'm in bed") and the end of the
/// night.
class OpenNight {
  OpenNight({
    required this.plannedBedtime,
    this.lastNag,
    this.bedtime,
    this.word,
    this.nagSnoozedUntil,
  });

  factory OpenNight.fromJson(Map<String, Object?> json) => OpenNight(
    plannedBedtime: _time(json['plannedBedtime'])!,
    lastNag: _time(json['lastNag']),
    bedtime: _time(json['bedtime']),
    word: json['word'] as String?,
    nagSnoozedUntil: _time(json['nagSnoozedUntil']),
  );

  final DateTime plannedBedtime;

  /// When the nag was last shown.
  DateTime? lastNag;

  /// When the user said they were in bed; null until then.
  DateTime? bedtime;

  /// The word shown at [bedtime].
  String? word;

  /// When the snoozed nag comes back.
  DateTime? nagSnoozedUntil;

  bool get confirmed => bedtime != null;

  /// The bedtime the night records: confirmed, else the last nag.
  DateTime get effectiveBedtime => bedtime ?? lastNag ?? plannedBedtime;

  Map<String, Object?> toJson() => {
    'plannedBedtime': plannedBedtime.toIso8601String(),
    'lastNag': lastNag?.toIso8601String(),
    'bedtime': bedtime?.toIso8601String(),
    'word': word,
    'nagSnoozedUntil': nagSnoozedUntil?.toIso8601String(),
  };
}

/// What the engine remembers between events.
class EngineState {
  EngineState({
    this.night,
    Map<int, DateTime>? alarmSnoozes,
    Map<int, DateTime>? lastRing,
    WordDeck? deck,
    this.setupDone = false,
  }) : alarmSnoozes = alarmSnoozes ?? {},
       lastRing = lastRing ?? {},
       deck = deck ?? WordDeck();

  factory EngineState.fromJson(Map<String, Object?> json) {
    final night = json['night'] as Map<String, Object?>?;
    final deck = json['deck'] as Map<String, Object?>?;
    return EngineState(
      night: night == null ? null : OpenNight.fromJson(night),
      alarmSnoozes: _times(json['alarmSnoozes']),
      lastRing: _times(json['lastRing']),
      deck: deck == null
          ? null
          : WordDeck(
              order: (deck['order'] as List).cast<int>().toList(),
              cursor: deck['cursor'] as int,
            ),
      setupDone: json['setupDone'] as bool? ?? false,
    );
  }

  OpenNight? night;

  /// Alarm id to the moment its snooze rings again.
  final Map<int, DateTime> alarmSnoozes;

  /// Alarm id to the moment it last started ringing.
  final Map<int, DateTime> lastRing;
  final WordDeck deck;

  /// Whether the first-start setup was walked through.
  bool setupDone;

  Map<String, Object?> toJson() => {
    'night': night?.toJson(),
    'alarmSnoozes': {
      for (final e in alarmSnoozes.entries)
        '${e.key}': e.value.toIso8601String(),
    },
    'lastRing': {
      for (final e in lastRing.entries) '${e.key}': e.value.toIso8601String(),
    },
    'deck': {'order': deck.order, 'cursor': deck.cursor},
    'setupDone': setupDone,
  };
}

DateTime? _time(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

Map<int, DateTime> _times(Object? value) => {
  for (final e in ((value as Map?) ?? const {}).entries)
    int.parse(e.key as String): DateTime.parse(e.value as String),
};

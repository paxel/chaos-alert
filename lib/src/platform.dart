import 'dart:async';

import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/services.dart';

/// What the app needs from Android to ring reliably.
enum Permission { exactAlarms, notifications, fullScreen, battery, music }

/// One alarm ring as Android schedules it, with everything it needs to ring
/// while the app is not running.
class ScheduledRing {
  const ScheduledRing({
    required this.alarmId,
    required this.at,
    required this.sounds,
    required this.lowVolume,
    required this.mediumVolume,
    required this.timeout,
    required this.snooze,
  });

  final int alarmId;
  final DateTime at;

  /// The pick and its backups, tried in order.
  final List<SoundChoice> sounds;
  final double lowVolume;
  final double mediumVolume;
  final Duration timeout;

  /// How long the Snooze action on the ring's notification snoozes it.
  final Duration snooze;
}

/// The silent "I'm awake" notice of one morning.
class AwakeNotice {
  const AwakeNotice({required this.at, required this.until});

  final DateTime at;
  final DateTime until;
}

/// Why Android opened the app.
sealed class Launch {
  const Launch();
}

class NagLaunch extends Launch {
  const NagLaunch();

  @override
  String toString() => 'nag';
}

class AwakeLaunch extends Launch {
  const AwakeLaunch();

  @override
  String toString() => "I'm awake";
}

class RingLaunch extends Launch {
  const RingLaunch(this.alarmId);

  final int alarmId;

  @override
  String toString() => 'ring of alarm $alarmId';
}

/// Something Android did on its own, kept in a queue until the app reads
/// it, with the moment it happened.
sealed class PlatformEvent {
  const PlatformEvent(this.at);

  final DateTime at;
}

/// The bedtime nag popped up.
class NagFired extends PlatformEvent {
  const NagFired(super.at);
}

/// An alarm started ringing.
class RingStarted extends PlatformEvent {
  const RingStarted(this.alarmId, DateTime at) : super(at);

  final int alarmId;
}

/// A ring was snoozed from its notification.
class RingSnoozed extends PlatformEvent {
  const RingSnoozed(this.alarmId, DateTime at) : super(at);

  final int alarmId;
}

/// A ring ran into its timeout unanswered.
class RingTimedOut extends PlatformEvent {
  const RingTimedOut(this.alarmId, DateTime at) : super(at);

  final int alarmId;
}

/// The seam to the Kotlin side. Tests use a fake.
abstract interface class AlarmPlatform {
  /// Schedules exactly [nags], replacing every nag scheduled before.
  Future<void> scheduleNags(List<DateTime> nags, {required bool chime});

  /// Schedules the silent "I'm awake" notices, replacing the ones before:
  /// each shows at [AwakeNotice.at] and goes away at [AwakeNotice.until],
  /// when the alarm rings.
  Future<void> scheduleAwake(List<AwakeNotice> notices);

  /// Removes the "I'm awake" notice that is showing, once it is done.
  Future<void> clearAwakeNotice();

  /// Schedules exactly [rings], replacing every ring scheduled before.
  Future<void> scheduleRings(List<ScheduledRing> rings);

  /// Everything Android did since the last call, oldest first; reading
  /// empties the queue.
  Future<List<PlatformEvent>> drainEvents();

  /// Stops the ring that is playing now.
  Future<void> stopRinging();

  /// The sounds on the phone; songs only while music access is granted.
  Future<List<Sound>> sounds();

  Future<Map<Permission, bool>> permissions();

  /// Asks for [permission], or opens its system settings page.
  Future<void> request(Permission permission);

  /// Why the app was started, if by a nag or a ring.
  Future<Launch?> initialLaunch();

  /// Nags and rings that arrive while the app runs.
  Stream<Launch> get launches;

  /// Android queued an event while the app runs, e.g. a ring snoozed from
  /// its notification; [drainEvents] reads it.
  Stream<void> get eventsArrived;

  /// Adds [text] to the event log on the phone.
  Future<void> log(String text);

  /// The event log of the last seven days, oldest first.
  Future<List<LogEntry>> readLog();
}

/// One line of the event log.
class LogEntry {
  const LogEntry(this.at, this.text);

  final DateTime at;
  final String text;
}

/// [AlarmPlatform] over the app's method channel.
class ChannelAlarmPlatform implements AlarmPlatform {
  ChannelAlarmPlatform() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'launch') {
        final launch = _launch(call.arguments);
        if (launch != null) _launches.add(launch);
      } else if (call.method == 'events') {
        _events.add(null);
      }
    });
  }

  static const _channel = MethodChannel('io.github.paxel.chaos_alert/alarm');
  final _launches = StreamController<Launch>.broadcast();
  final _events = StreamController<void>.broadcast();

  @override
  Future<void> scheduleNags(List<DateTime> nags, {required bool chime}) =>
      _channel.invokeMethod('scheduleNags', {
        'local': [for (final n in nags) _local(n)],
        'chime': chime,
      });

  @override
  Future<void> scheduleAwake(List<AwakeNotice> notices) =>
      _channel.invokeMethod('scheduleAwake', [
        for (final n in notices)
          {'local': _local(n.at), 'until': _local(n.until)},
      ]);

  @override
  Future<void> clearAwakeNotice() => _channel.invokeMethod('clearAwakeNotice');

  @override
  Future<List<PlatformEvent>> drainEvents() async {
    final raw = await _channel.invokeListMethod<Map>('drainEvents') ?? const [];
    final events = <PlatformEvent>[];
    for (final m in raw) {
      final at = DateTime.fromMillisecondsSinceEpoch(m['at'] as int);
      final alarmId = m['alarmId'] as int?;
      switch (m['kind']) {
        case 'nag':
          events.add(NagFired(at));
        case 'ring' when alarmId != null:
          events.add(RingStarted(alarmId, at));
        case 'snooze' when alarmId != null:
          events.add(RingSnoozed(alarmId, at));
        case 'timeout' when alarmId != null:
          events.add(RingTimedOut(alarmId, at));
      }
    }
    return events;
  }

  @override
  Future<void> scheduleRings(List<ScheduledRing> rings) =>
      _channel.invokeMethod('scheduleRings', [
        for (final r in rings)
          {
            'alarmId': r.alarmId,
            'local': _local(r.at),
            'sounds': [
              for (final s in r.sounds)
                {'uri': s.sound.uri, 'startMs': s.start.inMilliseconds},
            ],
            'low': r.lowVolume,
            'medium': r.mediumVolume,
            'timeoutMs': r.timeout.inMilliseconds,
            'snoozeMs': r.snooze.inMilliseconds,
          },
      ]);

  @override
  Future<void> stopRinging() => _channel.invokeMethod('stopRinging');

  @override
  Future<List<Sound>> sounds() async {
    final raw = await _channel.invokeListMethod<Map>('sounds') ?? const [];
    return [
      for (final m in raw)
        Sound(
          uri: m['uri'] as String,
          group: SoundGroup.values.byName(m['group'] as String),
          length: switch (m['lengthMs']) {
            final int ms => Duration(milliseconds: ms),
            _ => null,
          },
        ),
    ];
  }

  @override
  Future<Map<Permission, bool>> permissions() async {
    final raw =
        await _channel.invokeMapMethod<String, bool>('permissions') ?? const {};
    return {for (final p in Permission.values) p: raw[p.name] ?? false};
  }

  @override
  Future<void> request(Permission permission) =>
      _channel.invokeMethod('request', permission.name);

  @override
  Future<Launch?> initialLaunch() async =>
      _launch(await _channel.invokeMethod<Object?>('initialLaunch'));

  @override
  Stream<Launch> get launches => _launches.stream;

  @override
  Stream<void> get eventsArrived => _events.stream;

  @override
  Future<void> log(String text) => _channel.invokeMethod('log', text);

  @override
  Future<List<LogEntry>> readLog() async {
    final raw = await _channel.invokeListMethod<Map>('readLog') ?? const [];
    return [
      for (final m in raw)
        LogEntry(
          DateTime.fromMillisecondsSinceEpoch(m['at'] as int),
          m['text'] as String,
        ),
    ];
  }

  /// Wall-clock fields, so Android re-arms at the same local time after a
  /// time-zone or clock change.
  static List<int> _local(DateTime t) => [
    t.year,
    t.month,
    t.day,
    t.hour,
    t.minute,
    t.second,
  ];

  static Launch? _launch(Object? raw) {
    if (raw is! Map) return null;
    return switch (raw['kind']) {
      'nag' => const NagLaunch(),
      'awake' => const AwakeLaunch(),
      'ring' => RingLaunch(raw['alarmId'] as int),
      _ => null,
    };
  }
}

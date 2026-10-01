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
  });

  final int alarmId;
  final DateTime at;

  /// The pick and its backups, tried in order.
  final List<SoundChoice> sounds;
  final double lowVolume;
  final double mediumVolume;
  final Duration timeout;
}

/// Why Android opened the app.
sealed class Launch {
  const Launch();
}

class NagLaunch extends Launch {
  const NagLaunch();
}

class RingLaunch extends Launch {
  const RingLaunch(this.alarmId);

  final int alarmId;
}

/// The seam to the Kotlin side. Tests use a fake.
abstract interface class AlarmPlatform {
  /// Schedules the bedtime nag at [at], replacing any earlier one; null
  /// cancels it.
  Future<void> scheduleNag(DateTime? at, {required bool chime});

  /// Schedules exactly [rings], replacing every ring scheduled before.
  Future<void> scheduleRings(List<ScheduledRing> rings);

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
}

/// [AlarmPlatform] over the app's method channel.
class ChannelAlarmPlatform implements AlarmPlatform {
  ChannelAlarmPlatform() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'launch') {
        final launch = _launch(call.arguments);
        if (launch != null) _launches.add(launch);
      }
    });
  }

  static const _channel = MethodChannel('io.github.paxel.chaos_alert/alarm');
  final _launches = StreamController<Launch>.broadcast();

  @override
  Future<void> scheduleNag(DateTime? at, {required bool chime}) =>
      _channel.invokeMethod('scheduleNag', {
        'at': at?.millisecondsSinceEpoch,
        'chime': chime,
      });

  @override
  Future<void> scheduleRings(List<ScheduledRing> rings) =>
      _channel.invokeMethod('scheduleRings', [
        for (final r in rings)
          {
            'alarmId': r.alarmId,
            'at': r.at.millisecondsSinceEpoch,
            'sounds': [
              for (final s in r.sounds)
                {'uri': s.sound.uri, 'startMs': s.start.inMilliseconds},
            ],
            'low': r.lowVolume,
            'medium': r.mediumVolume,
            'timeoutMs': r.timeout.inMilliseconds,
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

  static Launch? _launch(Object? raw) {
    if (raw is! Map) return null;
    return switch (raw['kind']) {
      'nag' => const NagLaunch(),
      'ring' => RingLaunch(raw['alarmId'] as int),
      _ => null,
    };
  }
}

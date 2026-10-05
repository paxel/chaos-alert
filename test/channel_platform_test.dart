import 'package:chaos_alert/src/platform.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('io.github.paxel.chaos_alert/alarm');
  final calls = <MethodCall>[];
  Object? Function(MethodCall) answer = (_) => null;

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return answer(call);
        });
  });

  test('nags travel as wall-clock fields with the chime', () async {
    await ChannelAlarmPlatform().scheduleNags([
      DateTime(2026, 10, 5, 22, 30),
    ], chime: false);
    expect(calls.single.method, 'scheduleNags');
    expect(calls.single.arguments, {
      'local': [
        [2026, 10, 5, 22, 30, 0],
      ],
      'chime': false,
    });
  });

  test('awake notices travel with their show and hide times', () async {
    await ChannelAlarmPlatform().scheduleAwake([
      AwakeNotice(
        at: DateTime(2026, 10, 6, 5, 30),
        until: DateTime(2026, 10, 6, 6, 30),
      ),
    ]);
    expect(calls.single.method, 'scheduleAwake');
    expect(calls.single.arguments, [
      {
        'local': [2026, 10, 6, 5, 30, 0],
        'until': [2026, 10, 6, 6, 30, 0],
      },
    ]);
  });

  test('rings carry everything Android needs to ring alone', () async {
    await ChannelAlarmPlatform().scheduleRings([
      ScheduledRing(
        alarmId: 3,
        at: DateTime(2026, 10, 6, 6, 30),
        sounds: [
          const SoundChoice(
            Sound(uri: 'content://song/1', group: SoundGroup.song),
            Duration(seconds: 42),
          ),
        ],
        lowVolume: 0.2,
        mediumVolume: 0.5,
        timeout: const Duration(minutes: 10),
        snooze: const Duration(minutes: 9),
      ),
    ]);
    expect(calls.single.arguments, [
      {
        'alarmId': 3,
        'local': [2026, 10, 6, 6, 30, 0],
        'sounds': [
          {'uri': 'content://song/1', 'startMs': 42000},
        ],
        'low': 0.2,
        'medium': 0.5,
        'timeoutMs': 600000,
        'snoozeMs': 540000,
      },
    ]);
  });

  test('queued events come back typed, unknown kinds are skipped', () async {
    final at = DateTime(2026, 10, 6, 6, 30);
    answer = (_) => [
      {'kind': 'nag', 'at': at.millisecondsSinceEpoch},
      {'kind': 'ring', 'alarmId': 3, 'at': at.millisecondsSinceEpoch},
      {'kind': 'timeout', 'alarmId': 3, 'at': at.millisecondsSinceEpoch},
      {'kind': 'snooze', 'alarmId': 3, 'at': at.millisecondsSinceEpoch},
      {'kind': 'other', 'at': at.millisecondsSinceEpoch},
    ];
    final events = await ChannelAlarmPlatform().drainEvents();
    expect(events, hasLength(4));
    expect(events[0], isA<NagFired>().having((e) => e.at, 'at', at));
    expect(events[1], isA<RingStarted>().having((e) => e.alarmId, 'id', 3));
    expect(events[2], isA<RingTimedOut>());
    expect(events[3], isA<RingSnoozed>().having((e) => e.alarmId, 'id', 3));
  });

  test('the event log goes to Android and comes back with its times', () async {
    final at = DateTime(2026, 10, 6, 6, 31);
    answer = (call) => switch (call.method) {
      'readLog' => [
        {'at': at.millisecondsSinceEpoch, 'text': 'android: ring stopped'},
      ],
      _ => null,
    };
    final p = ChannelAlarmPlatform();
    await p.log('app: hello');
    expect(calls.last.method, 'log');
    expect(calls.last.arguments, 'app: hello');
    final log = await p.readLog();
    expect(log.single.at, at);
    expect(log.single.text, 'android: ring stopped');
  });

  test('sounds and permissions are read from Android', () async {
    answer = (call) => switch (call.method) {
      'sounds' => [
        {'uri': 'content://a', 'group': 'alarm'},
        {'uri': 'content://s', 'group': 'song', 'lengthMs': 180000},
      ],
      'permissions' => {'exactAlarms': true, 'music': false},
      _ => null,
    };
    final p = ChannelAlarmPlatform();
    final sounds = await p.sounds();
    expect(sounds.last.group, SoundGroup.song);
    expect(sounds.last.length, const Duration(minutes: 3));
    final perms = await p.permissions();
    expect(perms[Permission.exactAlarms], isTrue);
    expect(perms[Permission.music], isFalse);
    expect(perms[Permission.battery], isFalse);
  });

  test('a launch from the awake notice opens I am awake', () async {
    answer = (_) => {'kind': 'awake'};
    expect(await ChannelAlarmPlatform().initialLaunch(), isA<AwakeLaunch>());
  });

  test('a launch reads the nag or the ring', () async {
    answer = (_) => {'kind': 'ring', 'alarmId': 7};
    final launch = await ChannelAlarmPlatform().initialLaunch();
    expect(launch, isA<RingLaunch>().having((l) => l.alarmId, 'id', 7));
  });
}

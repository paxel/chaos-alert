import 'dart:math';

import 'package:chaos_alert/src/controller.dart';
import 'package:chaos_alert/src/platform.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_platform.dart';

const words = ['verdict', 'venture', 'harbour', 'lantern', 'quarrel'];

void main() {
  late FakePlatform platform;
  late Controller c;
  var now = DateTime(2026, 10, 5, 12);

  setUp(() {
    now = DateTime(2026, 10, 5, 12);
    platform = FakePlatform();
    c = Controller(
      store: MemoryStore(),
      platform: platform,
      words: words,
      clock: () => now,
      random: Random(1),
    );
  });

  Future<Alarm> addAlarm() async {
    await c.saveAlarm(
      const Alarm(id: 0, time: ClockTime(6, 30), weekdays: {DateTime.tuesday}),
    );
    return c.alarms.single;
  }

  test('saving an alarm schedules its ring and the nag', () async {
    final a = await addAlarm();
    expect(platform.nag, DateTime(2026, 10, 5, 22, 30));
    expect(platform.chime, isTrue);
    final ring = platform.rings.single;
    expect(ring.alarmId, a.id);
    expect(ring.at, DateTime(2026, 10, 6, 6, 30));
    expect(ring.sounds, hasLength(4));
    expect(ring.lowVolume, 0.2);
    expect(ring.mediumVolume, 0.5);
    expect(ring.timeout, const Duration(minutes: 10));
  });

  test('settings travel with the schedule', () async {
    await addAlarm();
    await c.saveSettings(
      const Settings(
        chime: false,
        lowVolume: 0.1,
        mediumVolume: 0.8,
        alarmTimeout: Duration(minutes: 3),
      ),
    );
    expect(platform.chime, isFalse);
    expect(platform.rings.single.lowVolume, 0.1);
    expect(platform.rings.single.mediumVolume, 0.8);
    expect(platform.rings.single.timeout, const Duration(minutes: 3));
  });

  test('deleting the alarm clears the schedule', () async {
    final a = await addAlarm();
    await c.deleteAlarm(a.id);
    expect(platform.nag, isNull);
    expect(platform.rings, isEmpty);
  });

  test('without music access no song is scheduled', () async {
    platform.inventory = platform.inventory
        .where((s) => s.group != SoundGroup.song)
        .toList();
    await c.refresh();
    await addAlarm();
    for (final s in platform.rings.single.sounds) {
      expect(s.sound.group, isNot(SoundGroup.song));
    }
  });

  test('turning a ring off stops the sound', () async {
    final a = await addAlarm();
    now = DateTime(2026, 10, 5, 22, 30);
    final word = await c.inBed();
    expect(platform.nag, isNull);
    now = DateTime(2026, 10, 6, 6, 30);
    await c.ring(a.id);
    await c.snoozeAlarm(a.id);
    expect(platform.stops, 1);
    expect(platform.rings.single.at, DateTime(2026, 10, 6, 6, 39));
    now = DateTime(2026, 10, 6, 6, 39);
    await c.ring(a.id);
    final outcome = await c.answer(a.id, word);
    expect(outcome!.correct, isTrue);
    expect(platform.stops, 2);
    expect(platform.rings.single.at, DateTime(2026, 10, 13, 6, 30));
  });

  test('missing permissions are listed until granted', () async {
    platform.granted[Permission.fullScreen] = false;
    await c.refresh();
    expect(c.missingPermissions, [Permission.fullScreen]);
    await c.request(Permission.fullScreen);
    expect(platform.requested, [Permission.fullScreen]);
    expect(c.missingPermissions, isEmpty);
  });
}

import 'dart:async';
import 'dart:math';

import 'package:chaos_alert/src/controller.dart';
import 'package:chaos_alert/src/generated_sounds.dart';
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
      store: MemoryStore()..saveSettings(const Settings(quiz: QuizForm.word)),
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
    expect(platform.rings.map((r) => r.at), [
      DateTime(2026, 10, 6, 6, 30),
      DateTime(2026, 10, 13, 6, 30),
      DateTime(2026, 10, 20, 6, 30),
    ]);
    final ring = platform.rings.first;
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
    expect(platform.rings.first.lowVolume, 0.1);
    expect(platform.rings.first.mediumVolume, 0.8);
    expect(platform.rings.first.timeout, const Duration(minutes: 3));
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
    for (final s in platform.rings.first.sounds) {
      expect(s.sound.group, isNot(SoundGroup.song));
    }
  });

  group('sound sources', () {
    late FakeClipMaker clips;

    setUp(() {
      clips = FakeClipMaker();
      c = Controller(
        store: MemoryStore(),
        platform: platform,
        clips: clips,
        words: words,
        clock: () => now,
        random: Random(1),
      );
    });

    Set<SoundGroup> scheduledGroups() => {
      for (final r in platform.rings)
        for (final s in r.sounds) s.sound.group,
    };

    test('switched-off sources are left out of the rings', () async {
      await c.refresh();
      await addAlarm();
      await c.saveSettings(
        const Settings(alarmSounds: false, notificationSounds: false),
      );
      expect(scheduledGroups(), {SoundGroup.song, SoundGroup.generated});
    });

    test('with every source off the rings get no sound to try', () async {
      await addAlarm();
      await c.saveSettings(
        const Settings(
          alarmSounds: false,
          notificationSounds: false,
          songs: false,
          generated: false,
        ),
      );
      expect(platform.rings.first.sounds, isEmpty);
    });

    test(
      'every scheduling makes new clips, the first ones schedule again',
      () async {
        clips.made = false;
        await addAlarm();
        expect(clips.renewed, 1);
        expect(scheduledGroups(), isNot(contains(SoundGroup.generated)));
        // The first clips are written: the rings are scheduled with them,
        // without making new ones for that.
        clips.made = true;
        clips.done.complete();
        await pumpEventQueue();
        expect(clips.renewed, 1);
        expect(scheduledGroups(), contains(SoundGroup.generated));
        clips.done = Completer();
        await c.saveSettings(const Settings(chime: false));
        expect(clips.renewed, 2);
      },
    );

    test('with generated sounds off no clips are made', () async {
      await c.saveSettings(const Settings(generated: false));
      await addAlarm();
      expect(clips.renewed, 0);
      expect(scheduledGroups(), isNot(contains(SoundGroup.generated)));
    });

    test('an added folder is read and rings draw from it', () async {
      platform.folders['tree/rock'] = [
        for (var i = 0; i < 5; i++)
          Sound(uri: 'rock/$i', group: SoundGroup.folder, folder: 'tree/rock'),
      ];
      platform.nextFolder = const SoundFolder(uri: 'tree/rock', name: 'Rock');
      await addAlarm();
      await c.addFolder();
      expect(c.settings.folders.single.name, 'Rock');
      expect(c.folderCounts, {'tree/rock': 5});
      await c.saveSettings(
        c.settings.copyWith(
          alarmSounds: false,
          notificationSounds: false,
          songs: false,
          generated: false,
        ),
      );
      expect(scheduledGroups(), {SoundGroup.folder});
      // The same folder twice stays one source.
      await c.addFolder();
      expect(c.settings.folders, hasLength(1));
    });

    test('no folder picked changes nothing', () async {
      await c.addFolder();
      expect(c.settings.folders, isEmpty);
    });

    test('a lost folder shows as lost and can be picked again', () async {
      await c.saveSettings(
        const Settings(
          folders: [SoundFolder(uri: 'tree/old', name: 'Old', on: false)],
        ),
      );
      await c.refresh();
      await c.foldersRead;
      expect(c.folderCounts, {'tree/old': null});
      platform.folders['tree/new'] = [
        const Sound(uri: 'new/1', group: SoundGroup.folder, folder: 'tree/new'),
      ];
      platform.nextFolder = const SoundFolder(uri: 'tree/new', name: 'New');
      await c.repickFolder('tree/old');
      expect(platform.released, ['tree/old']);
      final f = c.settings.folders.single;
      expect((f.uri, f.name, f.on), ('tree/new', 'New', false));
      expect(c.folderCounts, {'tree/new': 1});
    });

    test('a refresh does not wait for slow folders', () async {
      platform.folders['tree/rock'] = const [
        Sound(uri: 'rock/1', group: SoundGroup.folder, folder: 'tree/rock'),
      ];
      await addAlarm();
      await c.saveSettings(
        const Settings(
          alarmSounds: false,
          notificationSounds: false,
          songs: false,
          generated: false,
          folders: [SoundFolder(uri: 'tree/rock', name: 'Rock')],
        ),
      );
      platform.folderHold = Completer();
      await c.refresh();
      expect(c.folderCounts, isEmpty);
      expect(platform.rings.first.sounds, isEmpty);
      platform.folderHold!.complete();
      await c.foldersRead;
      expect(c.folderCounts, {'tree/rock': 1});
      expect(scheduledGroups(), {SoundGroup.folder});
    });

    test('a removed folder gives up its access', () async {
      platform.folders['tree/rock'] = const [];
      platform.nextFolder = const SoundFolder(uri: 'tree/rock', name: 'Rock');
      await c.addFolder();
      expect(c.folderCounts, {'tree/rock': 0});
      await c.removeFolder('tree/rock');
      expect(platform.released, ['tree/rock']);
      expect(c.settings.folders, isEmpty);
      expect(c.folderCounts, isEmpty);
    });
  });

  test('turning a ring off stops the sound', () async {
    final a = await addAlarm();
    now = DateTime(2026, 10, 5, 22, 30);
    final word = (await c.inBed())!;
    // Tonight's nag is done; next Monday's comes next.
    expect(platform.nag, DateTime(2026, 10, 12, 22, 30));
    now = DateTime(2026, 10, 6, 6, 30);
    platform.events.add(RingStarted(a.id, now));
    await c.refresh();
    await c.snoozeAlarm(a.id);
    expect(platform.stops, 1);
    expect(platform.rings.first.at, DateTime(2026, 10, 6, 6, 39));
    now = DateTime(2026, 10, 6, 6, 39);
    platform.events.add(RingStarted(a.id, now));
    await c.refresh();
    final outcome = await c.answer(a.id, word);
    expect(outcome!.correct, isTrue);
    expect(platform.stops, 2);
    expect(platform.rings.first.at, DateTime(2026, 10, 13, 6, 30));
  });

  test('a right letter quiz round leaves the alarm ringing; the last one '
      'stops it', () async {
    await c.saveSettings(const Settings());
    final a = await addAlarm();
    now = DateTime(2026, 10, 5, 22, 30);
    final word = (await c.inBed())!;
    now = DateTime(2026, 10, 6, 6, 30);
    platform.events.add(RingStarted(a.id, now));
    await c.refresh();
    expect(c.screenFor(a.id).letters, isTrue);
    expect((await c.answer(a.id, word.substring(0, 1)))!.next, isTrue);
    expect((await c.answer(a.id, word.substring(0, 2)))!.next, isTrue);
    expect(platform.stops, 0);
    expect((await c.answer(a.id, word.substring(0, 3)))!.correct, isTrue);
    expect(platform.stops, 1);
  });

  test('events Android queued are replayed with their own time', () async {
    final a = await addAlarm();
    now = DateTime(2026, 10, 6, 7);
    platform.events.addAll([
      RingTimedOut(a.id, DateTime(2026, 10, 6, 6, 40)),
      NagFired(DateTime(2026, 10, 5, 22, 30)),
      RingStarted(a.id, DateTime(2026, 10, 6, 6, 30)),
    ]);
    await c.refresh();
    final night = c.nights.single;
    expect(night.result, NightResult.missed);
    expect(night.bedtime, DateTime(2026, 10, 5, 22, 30));
    expect(night.bedtimeAssumed, isTrue);
    expect(night.end, DateTime(2026, 10, 6, 6, 40));
    expect(platform.events, isEmpty);
  });

  test('several nags are scheduled ahead', () async {
    await addAlarm();
    expect(platform.nags, [
      DateTime(2026, 10, 5, 22, 30),
      DateTime(2026, 10, 12, 22, 30),
      DateTime(2026, 10, 19, 22, 30),
    ]);
  });

  test(
    'the silent awake notice comes an hour before each first alarm',
    () async {
      await addAlarm();
      expect(platform.awake.first.at, DateTime(2026, 10, 6, 5, 30));
      expect(platform.awake.first.until, DateTime(2026, 10, 6, 6, 30));
      expect(platform.awake, hasLength(3));
    },
  );

  test("answering I'm awake clears the notice", () async {
    await addAlarm();
    now = DateTime(2026, 10, 5, 22, 30);
    final word = (await c.inBed())!;
    now = DateTime(2026, 10, 6, 5, 45);
    await c.awakeAnswer(word);
    expect(platform.awakeCleared, 1);
    expect(platform.awake.first.until, DateTime(2026, 10, 13, 6, 30));
  });

  test("a right letter quiz round on I'm awake keeps the notice", () async {
    await c.saveSettings(const Settings());
    await addAlarm();
    now = DateTime(2026, 10, 5, 22, 30);
    final word = (await c.inBed())!;
    now = DateTime(2026, 10, 6, 5, 45);
    await c.awakeAnswer(word.substring(0, 1));
    expect(platform.awakeCleared, 0);
    await c.awakeAnswer(word.substring(0, 2));
    await c.awakeAnswer(word.substring(0, 3));
    expect(platform.awakeCleared, 1);
  });

  test('missing permissions are listed until granted', () async {
    platform.granted[Permission.fullScreen] = false;
    await c.refresh();
    expect(c.missingPermissions, [Permission.fullScreen]);
    await c.request(Permission.fullScreen);
    expect(platform.requested, [Permission.fullScreen]);
    expect(c.missingPermissions, isEmpty);
  });

  group('alarm snooze', () {
    Future<Alarm> ringing() async {
      final a = await addAlarm();
      now = DateTime(2026, 10, 6, 6, 30);
      platform.events.add(RingStarted(a.id, now));
      await c.refresh();
      return a;
    }

    test('stops the sound before anything else is recorded', () async {
      final a = await ringing();
      platform.store = c.store;
      now = DateTime(2026, 10, 6, 6, 31);
      await c.snoozeAlarm(a.id);
      expect(platform.stateAtStop.single.alarmSnoozes, isEmpty);
      expect(c.alarmSnoozes[a.id], DateTime(2026, 10, 6, 6, 40));
    });

    test('from the notification is read with the queue and rings again '
        'after the snooze', () async {
      final a = await ringing();
      now = DateTime(2026, 10, 6, 6, 45);
      platform.events.add(RingSnoozed(a.id, DateTime(2026, 10, 6, 6, 31)));
      await c.refresh();
      expect(platform.rings.first.alarmId, a.id);
      expect(platform.rings.first.at, DateTime(2026, 10, 6, 6, 40));
      expect(platform.rings.first.snooze, const Duration(minutes: 9));
    });

    test('lands in the event log', () async {
      final a = await ringing();
      await c.snoozeAlarm(a.id);
      expect(platform.logged, contains('app: alarm ${a.id} snoozed on screen'));
    });
  });

  test('"I\'m in bed" outside bedtime gives no word and logs it', () async {
    await addAlarm();
    expect(await c.inBed(), isNull);
    expect(platform.logged, contains('app: in bed ignored'));
  });
}

/// Clips that are written when the test says so.
class FakeClipMaker implements ClipMaker {
  bool made = true;
  int renewed = 0;
  Completer<void> done = Completer();

  @override
  List<Sound> get sounds => [
    if (made)
      for (var i = 0; i < generatedClipCount; i++)
        Sound(uri: 'file:///clip-$i.wav', group: SoundGroup.generated),
  ];

  @override
  Future<void> renew(int seed) {
    renewed++;
    return done.future;
  }
}

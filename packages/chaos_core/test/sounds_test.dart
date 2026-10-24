import 'dart:math';

import 'package:chaos_core/chaos_core.dart';
import 'package:test/test.dart';

void main() {
  final alarms = [
    for (var i = 0; i < 3; i++) Sound(uri: 'alarm/$i', group: SoundGroup.alarm),
  ];
  final notifications = [
    for (var i = 0; i < 3; i++)
      Sound(uri: 'notification/$i', group: SoundGroup.notification),
  ];
  final songs = [
    for (var i = 0; i < 2000; i++)
      Sound(
        uri: 'song/$i',
        group: SoundGroup.song,
        length: const Duration(minutes: 4),
      ),
  ];
  final inventory = [...alarms, ...notifications, ...songs];

  test('a ring gets a pick and three distinct backups', () {
    final choices = pickSounds(inventory, Random(1));
    expect(choices, hasLength(4));
    expect(choices.map((c) => c.sound.uri).toSet(), hasLength(4));
  });

  test('every group comes up about equally, however many songs there are', () {
    final counts = {
      for (final g in [
        SoundGroup.alarm,
        SoundGroup.notification,
        SoundGroup.song,
      ])
        g: 0,
    };
    final random = Random(7);
    for (var i = 0; i < 3000; i++) {
      final group = pickSounds(inventory, random).first.sound.group;
      counts[group] = counts[group]! + 1;
    }
    for (final g in counts.keys) {
      expect(counts[g], inInclusiveRange(800, 1200), reason: '$g');
    }
  });

  test('songs start in their first half, system sounds at the start', () {
    final random = Random(3);
    for (var i = 0; i < 200; i++) {
      for (final c in pickSounds(inventory, random)) {
        if (c.sound.group == SoundGroup.song) {
          expect(c.start, lessThanOrEqualTo(const Duration(minutes: 2)));
        } else {
          expect(c.start, Duration.zero);
        }
      }
    }
  });

  test('song starts spread over the first half', () {
    final random = Random(5);
    final starts = [
      for (var i = 0; i < 300; i++)
        pickSounds(songs, random).first.start.inSeconds,
    ];
    expect(starts.reduce(min), lessThan(20));
    expect(starts.reduce(max), greaterThan(100));
  });

  test('without music access the songs group is simply absent', () {
    final random = Random(9);
    for (var i = 0; i < 100; i++) {
      final choices = pickSounds([...alarms, ...notifications], random);
      expect(choices.any((c) => c.sound.group == SoundGroup.song), isFalse);
    }
  });

  test('a phone with few sounds gives fewer candidates', () {
    expect(pickSounds([alarms.first], Random(1)), hasLength(1));
    expect(pickSounds(const [], Random(1)), isEmpty);
  });

  group('folders and generated sounds', () {
    List<Sound> folder(String tree, int count) => [
      for (var i = 0; i < count; i++)
        Sound(uri: '$tree/$i', group: SoundGroup.folder, folder: tree),
    ];
    final rock = folder('tree/rock', 500);
    final jazz = folder('tree/jazz', 3);
    final generated = [
      for (var i = 0; i < 4; i++)
        Sound(uri: 'clip/$i', group: SoundGroup.generated),
    ];

    test('each folder is its own source, as likely as any other', () {
      final counts = <String, int>{};
      final random = Random(11);
      for (var i = 0; i < 4000; i++) {
        final source = pickSounds([
          ...alarms,
          ...songs,
          ...rock,
          ...jazz,
        ], random).first.sound.source;
        counts[source] = (counts[source] ?? 0) + 1;
      }
      expect(
        counts.keys,
        unorderedEquals(['alarm', 'song', 'tree/rock', 'tree/jazz']),
      );
      for (final c in counts.values) {
        expect(c, inInclusiveRange(800, 1200));
      }
    });

    test('folder sounds start somewhere in their first half', () {
      final random = Random(4);
      final shares = [
        for (var i = 0; i < 300; i++) pickSounds(rock, random).first,
      ];
      for (final c in shares) {
        expect(c.start, Duration.zero);
        expect(c.startShare, inInclusiveRange(0, 0.5));
      }
      expect(shares.map((c) => c.startShare).reduce(max), greaterThan(0.4));
    });

    test('generated clips play from their start', () {
      for (final c in pickSounds(generated, Random(2))) {
        expect(c.start, Duration.zero);
        expect(c.startShare, 0);
      }
    });

    test('only switched-on sources are available', () {
      final everything = [
        ...alarms,
        ...notifications,
        ...songs.take(2),
        ...rock.take(2),
        ...jazz,
        ...generated,
      ];
      Set<String> sources(Settings s) => {
        for (final sound in availableSounds(everything, s)) sound.source,
      };
      const folders = [
        SoundFolder(uri: 'tree/rock', name: 'Rock'),
        SoundFolder(uri: 'tree/jazz', name: 'Jazz', on: false),
      ];
      expect(sources(const Settings(folders: folders)), {
        'alarm',
        'notification',
        'song',
        'generated',
        'tree/rock',
      });
      expect(
        sources(
          const Settings(
            alarmSounds: false,
            notificationSounds: false,
            songs: false,
            generated: false,
          ),
        ),
        isEmpty,
      );
      expect(sources(const Settings(songs: false, generated: false)), {
        'alarm',
        'notification',
      });
    });

    test('every source off means only the default alarm sound', () {
      const off = Settings(
        alarmSounds: false,
        notificationSounds: false,
        songs: false,
        generated: false,
        folders: [SoundFolder(uri: 'tree/rock', name: 'Rock', on: false)],
      );
      expect(off.allSoundsOff, isTrue);
      expect(const Settings().allSoundsOff, isFalse);
      expect(
        off
            .copyWith(
              folders: [const SoundFolder(uri: 'r', name: 'R')],
            )
            .allSoundsOff,
        isFalse,
      );
    });
  });
}

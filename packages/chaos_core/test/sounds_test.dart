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
    final counts = {for (final g in SoundGroup.values) g: 0};
    final random = Random(7);
    for (var i = 0; i < 3000; i++) {
      final group = pickSounds(inventory, random).first.sound.group;
      counts[group] = counts[group]! + 1;
    }
    for (final g in SoundGroup.values) {
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
}

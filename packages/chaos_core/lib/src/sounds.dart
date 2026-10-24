import 'dart:math';

import 'model.dart';

/// The kinds of sound a ring draws from.
enum SoundGroup { alarm, notification, song, folder, generated }

/// One playable sound on the phone.
class Sound {
  const Sound({
    required this.uri,
    required this.group,
    this.length,
    this.folder,
  });

  final String uri;
  final SoundGroup group;

  /// The length of a song; null for every other sound.
  final Duration? length;

  /// The tree uri of the picked folder a folder sound lies in.
  final String? folder;

  /// The sound source this sound belongs to: each folder is its own.
  String get source => folder ?? group.name;
}

/// A sound to play and where in it to start.
class SoundChoice {
  const SoundChoice(this.sound, this.start, {this.startShare = 0});

  final Sound sound;
  final Duration start;

  /// For a sound of unknown length: where to start, as a share of its
  /// length, which the player works out once the file is open.
  final double startShare;
}

/// How many sounds a ring hands to the player: the pick and its backups.
const soundCandidates = 4;

/// The sounds of the switched-on sources in [settings].
List<Sound> availableSounds(List<Sound> inventory, Settings settings) {
  final folders = {
    for (final f in settings.folders)
      if (f.on) f.uri,
  };
  return [
    for (final s in inventory)
      if (switch (s.group) {
        SoundGroup.alarm => settings.alarmSounds,
        SoundGroup.notification => settings.notificationSounds,
        SoundGroup.song => settings.songs,
        SoundGroup.generated => settings.generated,
        SoundGroup.folder => folders.contains(s.folder),
      })
        s,
  ];
}

/// The sounds for one ring: a source picked at random, then a sound from
/// it, repeated for the backups the player tries when a sound fails. Songs
/// and folder sounds start at a random point in their first half. No sound
/// is picked twice; fewer come back when the phone has fewer sounds.
List<SoundChoice> pickSounds(List<Sound> inventory, Random random) {
  final sources = <String, List<Sound>>{};
  for (final s in inventory) {
    (sources[s.source] ??= []).add(s);
  }
  final choices = <SoundChoice>[];
  while (choices.length < soundCandidates && sources.isNotEmpty) {
    final names = sources.keys.toList();
    final source = names[random.nextInt(names.length)];
    final sounds = sources[source]!;
    final sound = sounds.removeAt(random.nextInt(sounds.length));
    if (sounds.isEmpty) sources.remove(source);
    choices.add(
      sound.group == SoundGroup.folder
          ? SoundChoice(
              sound,
              Duration.zero,
              startShare: random.nextDouble() / 2,
            )
          : SoundChoice(sound, _start(sound, random)),
    );
  }
  return choices;
}

Duration _start(Sound sound, Random random) {
  final length = sound.length;
  if (sound.group != SoundGroup.song || length == null) return Duration.zero;
  final half = length.inMilliseconds ~/ 2;
  if (half <= 0) return Duration.zero;
  return Duration(milliseconds: random.nextInt(half + 1));
}

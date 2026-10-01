import 'dart:math';

/// The kinds of sound a ring draws from.
enum SoundGroup { alarm, notification, song }

/// One playable sound on the phone.
class Sound {
  const Sound({required this.uri, required this.group, this.length});

  final String uri;
  final SoundGroup group;

  /// The length of a song; null for system sounds.
  final Duration? length;
}

/// A sound to play and where in it to start.
class SoundChoice {
  const SoundChoice(this.sound, this.start);

  final Sound sound;
  final Duration start;
}

/// How many sounds a ring hands to the player: the pick and its backups.
const soundCandidates = 4;

/// The sounds for one ring: a group picked at random, then a sound from it,
/// repeated for the backups the player tries when a sound fails. Songs start
/// at a random point in their first half. No sound is picked twice; fewer
/// come back when the phone has fewer sounds.
List<SoundChoice> pickSounds(List<Sound> inventory, Random random) {
  final groups = <SoundGroup, List<Sound>>{};
  for (final s in inventory) {
    (groups[s.group] ??= []).add(s);
  }
  final choices = <SoundChoice>[];
  while (choices.length < soundCandidates && groups.isNotEmpty) {
    final names = groups.keys.toList();
    final group = names[random.nextInt(names.length)];
    final sounds = groups[group]!;
    final sound = sounds.removeAt(random.nextInt(sounds.length));
    if (sounds.isEmpty) groups.remove(group);
    choices.add(SoundChoice(sound, _start(sound, random)));
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

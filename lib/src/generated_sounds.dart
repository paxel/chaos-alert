import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:chaos_core/chaos_core.dart';

/// Makes the generated sounds: [generatedClipCount] clip files that every
/// scheduling makes new. Tests use a fake.
abstract interface class ClipMaker {
  /// The clips there are now.
  List<Sound> get sounds;

  /// Makes new clips in the background; done once they are written.
  Future<void> renew(int seed);
}

/// [ClipMaker] writing WAV files into [dir], off the UI isolate.
class FileClipMaker implements ClipMaker {
  FileClipMaker(this.dir);

  final Directory dir;
  int? _pending;
  Future<void>? _running;

  File _clip(int i) => File('${dir.path}/clip-$i.wav');

  @override
  List<Sound> get sounds => [
    for (var i = 0; i < generatedClipCount; i++)
      if (_clip(i).existsSync())
        Sound(uri: _clip(i).uri.toString(), group: SoundGroup.generated),
  ];

  /// One run at a time; requests during a run collapse into one more run
  /// with the latest seed.
  @override
  Future<void> renew(int seed) {
    _pending = seed;
    return _running ??= _run();
  }

  Future<void> _run() async {
    try {
      while (_pending != null) {
        final seed = _pending!;
        _pending = null;
        final path = dir.path;
        await Isolate.run(() => _write(path, seed));
      }
    } finally {
      _running = null;
    }
  }

  // Written beside and renamed over, so a ring playing a clip keeps its
  // old file to the end.
  static void _write(String path, int seed) {
    Directory(path).createSync(recursive: true);
    for (var i = 0; i < generatedClipCount; i++) {
      File('$path/clip-$i.wav.tmp')
        ..writeAsBytesSync(generatedClip(seed + i))
        ..renameSync('$path/clip-$i.wav');
    }
  }
}

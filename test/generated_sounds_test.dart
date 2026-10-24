import 'dart:io';

import 'package:chaos_alert/src/generated_sounds.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clips are written to files, made new by every renew', () async {
    final dir = Directory.systemTemp.createTempSync('chaos_clips');
    addTearDown(() => dir.deleteSync(recursive: true));
    final maker = FileClipMaker(Directory('${dir.path}/generated'));
    expect(maker.sounds, isEmpty);
    // A second request during a run waits for one more run, with its seed.
    final first = maker.renew(1);
    final second = maker.renew(2);
    await Future.wait([first, second]);
    final sounds = maker.sounds;
    expect(sounds, hasLength(generatedClipCount));
    expect(sounds.every((s) => s.group == SoundGroup.generated), isTrue);
    final file = File.fromUri(Uri.parse(sounds.first.uri));
    expect(file.readAsBytesSync(), generatedClip(2));
    expect(
      dir.listSync(recursive: true).where((e) => e.path.endsWith('.tmp')),
      isEmpty,
    );
  });
}

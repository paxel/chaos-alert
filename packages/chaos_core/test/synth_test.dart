import 'dart:math';
import 'dart:typed_data';

import 'package:chaos_core/chaos_core.dart';
import 'package:test/test.dart';

void main() {
  Int16List samples(Uint8List wav) =>
      wav.buffer.asInt16List(wav.offsetInBytes + 44, (wav.length - 44) ~/ 2);

  test('a clip is a 60 s mono 16 bit WAV file', () {
    final wav = generatedClip(1);
    final header = ByteData.sublistView(wav, 0, 44);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 16)), 'WAVEfmt ');
    expect(header.getUint16(22, Endian.little), 1);
    final rate = header.getUint32(24, Endian.little);
    expect(header.getUint16(34, Endian.little), 16);
    final bytes = header.getUint32(40, Endian.little);
    expect(wav.length, 44 + bytes);
    expect(bytes ~/ 2 / rate, generatedClipLength.inSeconds);
  });

  test('the same seed gives the same clip, another seed another', () {
    expect(generatedClip(5), generatedClip(5));
    expect(generatedClip(5), isNot(generatedClip(6)));
  });

  test('every clip is about as loud and fades in and out', () {
    for (var seed = 0; seed < 6; seed++) {
      final s = samples(generatedClip(seed));
      var sum = 0.0;
      for (final v in s) {
        sum += (v / 32767) * (v / 32767);
      }
      expect(
        sqrt(sum / s.length),
        inInclusiveRange(0.15, 0.4),
        reason: '$seed',
      );
      expect(s.first, 0);
      expect(s.last.abs(), lessThan(200));
    }
  });
}

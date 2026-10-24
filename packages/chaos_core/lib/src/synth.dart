import 'dart:math';
import 'dart:typed_data';

/// How many generated clips there are at a time.
const generatedClipCount = 4;

/// How long one generated clip runs; the ring loops it.
const generatedClipLength = Duration(seconds: 60);

const _rate = 22050;
const _seconds = 60;
const _n = _rate * _seconds;

typedef _Style = Float64List Function(Random r);

const _styles = <_Style>[
  _melody,
  _chords,
  _noiseBursts,
  _rhythm,
  _chirps,
  _sweeps,
  _bells,
  _chiptune,
];

/// One generated clip as a WAV file: two random styles out of eight laid
/// over each other, the same for the same [seed]. Mono, 16 bit, 22.05 kHz,
/// at one loudness for every mix, with short fades so the loop does not
/// click.
Uint8List generatedClip(int seed) {
  final r = Random(seed);
  final picked = [..._styles]..shuffle(r);
  final a = picked[0](r);
  final b = picked[1](r);
  final mix = Float64List(_n);
  for (var j = 0; j < _n; j++) {
    mix[j] = a[j] + 0.7 * b[j];
  }
  return _wav(mix);
}

double _midi(num note) => 440 * pow(2, (note - 69) / 12).toDouble();

double _wave(String type, double phase) {
  final p = phase - phase.floorToDouble();
  return switch (type) {
    'square' => p < 0.5 ? 0.6 : -0.6,
    'pulse' => p < 0.125 ? 0.6 : -0.6,
    'saw' => (2 * p - 1) * 0.6,
    'tri' => 4 * (p < 0.5 ? p : 1 - p) - 1,
    _ => sin(2 * pi * p),
  };
}

/// Adds one tone at [start] seconds into [buf].
void _tone(
  Float64List buf,
  double start,
  double length,
  double freq, {
  String type = 'sine',
  double gain = 0.3,
  double attack = 0.005,
  double decay = 4,
  double glideTo = 0,
}) {
  final s0 = (start * _rate).round();
  final len = (length * _rate).round();
  var phase = 0.0;
  for (var j = 0; j < len && s0 + j < _n; j++) {
    final t = j / _rate;
    final f = glideTo == 0 ? freq : freq + (glideTo - freq) * (j / len);
    phase += f / _rate;
    final env = min(1.0, t / attack) * exp(-decay * t);
    buf[s0 + j] += gain * env * _wave(type, phase);
  }
}

/// FM bell: a carrier with a decaying modulator at a non-integer ratio.
void _bell(Float64List buf, double start, double freq, double gain, Random r) {
  final ratio = [1.4, 2.76, 3.5][r.nextInt(3)];
  final s0 = (start * _rate).round();
  final len = (3.5 * _rate).round();
  for (var j = 0; j < len && s0 + j < _n; j++) {
    final t = j / _rate;
    final index = 4 * exp(-3 * t);
    final m = sin(2 * pi * freq * ratio * t) * index;
    buf[s0 + j] += gain * exp(-1.6 * t) * sin(2 * pi * freq * t + m);
  }
}

void _noise(
  Float64List buf,
  double start,
  double length,
  Random r, {
  double gain = 0.3,
  double cutoff = 0.2,
  double decay = 20,
  bool high = false,
}) {
  final s0 = (start * _rate).round();
  final len = (length * _rate).round();
  var low = 0.0;
  for (var j = 0; j < len && s0 + j < _n; j++) {
    final white = r.nextDouble() * 2 - 1;
    low += cutoff * (white - low);
    final v = high ? white - low : low;
    buf[s0 + j] += gain * exp(-decay * j / _rate) * v;
  }
}

void _echo(Float64List buf, double delay, double feedback) {
  final d = (delay * _rate).round();
  for (var j = d; j < _n; j++) {
    buf[j] += feedback * buf[j - d];
  }
}

List<int> _scale(Random r) {
  final root = 57 + r.nextInt(12);
  final steps = r.nextBool() ? [0, 2, 4, 7, 9] : [0, 3, 5, 7, 10];
  return [
    for (var o = 0; o < 3; o++)
      for (final s in steps) root + 12 * o + s,
  ];
}

Float64List _melody(Random r) {
  final buf = Float64List(_n);
  final notes = _scale(r);
  final beat = 60 / (100 + r.nextInt(70)) / 2;
  final type = ['tri', 'square', 'sine'][r.nextInt(3)];
  var i = 5;
  for (var t = 0.0; t < _seconds; t += beat) {
    if (r.nextDouble() < 0.15) continue;
    i = (i + r.nextInt(5) - 2).clamp(0, notes.length - 1);
    _tone(buf, t, beat * 1.8, _midi(notes[i]), type: type, decay: 5);
  }
  _echo(buf, beat * 1.5, 0.35);
  return buf;
}

Float64List _chords(Random r) {
  final buf = Float64List(_n);
  final notes = _scale(r);
  final bar = 60 / (80 + r.nextInt(50)) * 2;
  for (var t = 0.0; t < _seconds; t += bar) {
    final base = r.nextInt(5);
    final chord = [notes[base], notes[base + 2], notes[base + 4]];
    for (final c in chord) {
      _tone(buf, t, bar, _midi(c - 12), type: 'saw', gain: 0.12, decay: 0.8);
    }
    for (var k = 0; k < 8; k++) {
      final c = chord[k % 3] + (k >= 3 ? 12 : 0);
      _tone(buf, t + k * bar / 8, bar / 4, _midi(c), gain: 0.18, decay: 9);
    }
  }
  return buf;
}

Float64List _noiseBursts(Random r) {
  final buf = Float64List(_n);
  var t = 0.0;
  while (t < _seconds) {
    final len = 0.05 + r.nextDouble() * 0.6;
    _noise(
      buf,
      t,
      len,
      r,
      gain: 0.5,
      cutoff: 0.05 + r.nextDouble() * 0.6,
      decay: 2 + r.nextDouble() * 15,
    );
    if (r.nextDouble() < 0.3) {
      _tone(buf, t, 0.4, 60, gain: 0.5, decay: 8, glideTo: 35);
    }
    t += len + r.nextDouble() * 0.5;
  }
  return buf;
}

Float64List _rhythm(Random r) {
  final buf = Float64List(_n);
  final step = 60 / (90 + r.nextInt(60)) / 4;
  final kick = [
    for (var i = 0; i < 16; i++) i % 4 == 0 || r.nextDouble() < .15,
  ];
  final snare = [
    for (var i = 0; i < 16; i++) i % 8 == 4 || r.nextDouble() < .1,
  ];
  final hat = [for (var i = 0; i < 16; i++) r.nextDouble() < 0.6];
  final bass = _scale(r).take(5).map((m) => _midi(m - 24)).toList();
  var i = 0;
  for (var t = 0.0; t < _seconds; t += step, i++) {
    final s = i % 16;
    if (kick[s]) {
      _tone(buf, t, 0.3, 150, gain: 0.7, decay: 12, glideTo: 45);
      _tone(buf, t, step * 2, bass[r.nextInt(5)], type: 'saw', gain: 0.15);
    }
    if (snare[s]) {
      _noise(buf, t, 0.2, r, gain: 0.45, cutoff: 0.5, decay: 18);
      _tone(buf, t, 0.1, 190, gain: 0.25, decay: 25);
    }
    if (hat[s]) _noise(buf, t, 0.05, r, gain: 0.2, decay: 60, high: true);
  }
  return buf;
}

Float64List _chirps(Random r) {
  final buf = Float64List(_n);
  var t = 0.0;
  while (t < _seconds) {
    final f = 1500 + r.nextDouble() * 2500;
    final up = r.nextBool();
    final count = 1 + r.nextInt(5);
    for (var k = 0; k < count; k++) {
      _tone(
        buf,
        t + k * 0.09,
        0.08,
        up ? f : f * 1.6,
        gain: 0.3,
        decay: 10,
        glideTo: up ? f * 1.6 : f,
      );
    }
    t += count * 0.09 + r.nextDouble() * 0.8;
  }
  return buf;
}

Float64List _sweeps(Random r) {
  final buf = Float64List(_n);
  var t = 0.0;
  var f = 300 + r.nextDouble() * 600;
  while (t < _seconds) {
    final len = 0.4 + r.nextDouble() * 1.6;
    final to = 250 + r.nextDouble() * 1200;
    for (final detune in [1.0, 1.007]) {
      _tone(
        buf,
        t,
        len,
        f * detune,
        type: 'square',
        gain: 0.15,
        decay: 0.2,
        attack: 0.03,
        glideTo: to * detune,
      );
    }
    f = to;
    t += len;
  }
  return buf;
}

Float64List _bells(Random r) {
  final buf = Float64List(_n);
  final notes = _scale(r);
  var t = 0.0;
  while (t < _seconds) {
    _bell(buf, t, _midi(notes[r.nextInt(notes.length)]), 0.3, r);
    t += [0.25, 0.5, 0.75][r.nextInt(3)];
  }
  return buf;
}

Float64List _chiptune(Random r) {
  final buf = Float64List(_n);
  final notes = _scale(r);
  final step = 60 / (130 + r.nextInt(50)) / 4;
  var i = 0;
  var base = r.nextInt(5);
  for (var t = 0.0; t < _seconds; t += step, i++) {
    if (i % 16 == 0) base = r.nextInt(5);
    final arp = [0, 2, 4, 7][i % 4];
    final note = notes[(base + arp).clamp(0, notes.length - 1)];
    _tone(buf, t, step, _midi(note), type: 'pulse', gain: 0.25, decay: 3);
    if (i % 4 == 0) _noise(buf, t, 0.08, r, gain: 0.3, cutoff: 0.8, decay: 40);
  }
  return buf;
}

Uint8List _wav(Float64List buf) {
  // The same loudness for every mix: scale to one RMS, then soft-clip.
  var sum = 1e-12;
  for (final v in buf) {
    sum += v * v;
  }
  final gain = 0.3 / sqrt(sum / _n);
  final data = ByteData(44 + _n * 2);
  void ascii(int at, String s) {
    for (var k = 0; k < s.length; k++) {
      data.setUint8(at + k, s.codeUnitAt(k));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + _n * 2, Endian.little);
  ascii(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, _rate, Endian.little);
  data.setUint32(28, _rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, _n * 2, Endian.little);
  for (var j = 0; j < _n; j++) {
    final t = j / _rate;
    final fade = min(1.0, min(t, _seconds - t) / 0.3);
    final v = _tanh(buf[j] * gain) * 0.95 * fade;
    data.setInt16(44 + j * 2, (v * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

double _tanh(double x) {
  final e = exp(2 * x.clamp(-20, 20));
  return (e - 1) / (e + 1);
}

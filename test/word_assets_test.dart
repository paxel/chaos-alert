import 'dart:math';

import 'package:chaos_alert/src/word_assets.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled list holds about 1,450 distinct words of 5 to 10 '
      'letters', () async {
    final words = await loadWords(rootBundle);
    expect(words.length, greaterThan(1400));
    expect(words.toSet(), hasLength(words.length));
    for (final w in words) {
      expect(w, matches(RegExp(r'^[a-z]{5,10}$')));
    }
  });

  test('every word gets four quiz options', () async {
    final words = await loadWords(rootBundle);
    final random = Random(1);
    for (final w in words) {
      expect(quizOptions(w, words, random).toSet(), hasLength(4));
    }
  });

  test('the bundled nag lines are 300 distinct lines of at most 200 '
      'characters, notes left out', () async {
    final lines = await loadNagLines(rootBundle);
    expect(lines, hasLength(300));
    expect(lines.toSet(), hasLength(300));
    for (final l in lines) {
      expect(l.startsWith('#'), isFalse);
      expect(l.length, lessThanOrEqualTo(200));
    }
  });

  test('the licences page carries the word list notice', () async {
    registerWordLicence(rootBundle);
    final entries = await LicenseRegistry.licenses.toList();
    final words = entries.firstWhere(
      (e) => e.packages.contains('Word list (SCOWL, 12dicts)'),
    );
    final text = words.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('Kevin Atkinson'));
    expect(text, contains('Public'));
  });
}

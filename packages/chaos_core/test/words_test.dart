import 'dart:math';

import 'package:chaos_core/chaos_core.dart';
import 'package:test/test.dart';

void main() {
  group('deck', () {
    test('hands out every word once before any repeats', () {
      final words = ['alpha', 'beta', 'gamma', 'delta', 'epsilon'];
      final deck = WordDeck();
      final random = Random(1);
      final firstRound = [for (var i = 0; i < 5; i++) deck.next(words, random)];
      expect(firstRound.toSet(), words.toSet());
      final secondRound = [
        for (var i = 0; i < 5; i++) deck.next(words, random),
      ];
      expect(secondRound.toSet(), words.toSet());
    });

    test('reshuffles when the word list changed', () {
      final deck = WordDeck(order: [0, 1, 2, 3, 4, 5], cursor: 2);
      final word = deck.next(['one', 'two', 'three'], Random(1));
      expect(['one', 'two', 'three'], contains(word));
      expect(deck.order.length, 3);
      expect(deck.cursor, 1);
    });
  });

  group('quiz options', () {
    test('are four distinct words containing the right one', () {
      final words = [
        'verdict',
        'venture',
        'harbour',
        'lantern',
        'quarrel',
        'nimbus',
      ];
      for (var seed = 0; seed < 50; seed++) {
        final options = quizOptions('verdict', words, Random(seed));
        expect(options, hasLength(4));
        expect(options.toSet(), hasLength(4));
        expect(options, contains('verdict'));
      }
    });

    test('include a word with the same first letter and a close length', () {
      final words = [
        'verdict',
        'venture',
        'vat',
        'harbour',
        'lantern',
        'quarrel',
      ];
      for (var seed = 0; seed < 50; seed++) {
        final options = quizOptions('verdict', words, Random(seed));
        expect(options, contains('venture'));
      }
    });

    test('fall back to the same first letter when no length is close', () {
      final words = ['verdict', 'vat', 'harbour', 'lantern', 'quarrel'];
      for (var seed = 0; seed < 50; seed++) {
        expect(quizOptions('verdict', words, Random(seed)), contains('vat'));
      }
    });

    test('fall back to random words when no first letter matches', () {
      final words = ['xylem', 'harbour', 'lantern', 'quarrel'];
      final options = quizOptions('xylem', words, Random(3));
      expect(options.toSet(), words.toSet());
    });
  });
}

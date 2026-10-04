import 'dart:math';

/// Where the night's word comes from: the list worked through in a shuffled
/// order, so no word repeats before every word was used once. The nag lines
/// are handed out the same way.
class WordDeck {
  WordDeck({List<int>? order, this.cursor = 0}) : order = order ?? [];

  /// Indices into the word list, in the order they are handed out.
  final List<int> order;

  /// How many of [order] were handed out.
  int cursor;

  /// The next word, reshuffling when the order is used up or no longer fits
  /// [words] (a new list shipped with an update).
  String next(List<String> words, Random random) {
    if (words.isEmpty) throw StateError('the word list is empty');
    final fits =
        order.length == words.length && order.every((i) => i < words.length);
    if (!fits || cursor >= order.length) {
      order
        ..clear()
        ..addAll(List.generate(words.length, (i) => i)..shuffle(random));
      cursor = 0;
    }
    return words[order[cursor++]];
  }
}

/// The four quiz options for [word], shuffled: the word itself, one that
/// looks similar and two random ones.
///
/// Similar means the same first letter and a length within two letters,
/// else the same first letter only, else any word.
List<String> quizOptions(String word, List<String> words, Random random) {
  final others = words.toSet()..remove(word);
  if (others.length < 3) {
    throw StateError('the word list needs at least four words');
  }
  String pick(Iterable<String> from) {
    final list = from.toList();
    return list[random.nextInt(list.length)];
  }

  final initial = word[0].toLowerCase();
  final sameInitial = others.where((w) => w[0].toLowerCase() == initial);
  final close = sameInitial.where((w) => (w.length - word.length).abs() <= 2);
  final similar = close.isNotEmpty
      ? pick(close)
      : sameInitial.isNotEmpty
      ? pick(sameInitial)
      : pick(others);
  others.remove(similar);
  final first = pick(others);
  others.remove(first);
  final second = pick(others);
  return [word, similar, first, second]..shuffle(random);
}

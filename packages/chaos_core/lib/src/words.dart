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

/// How many rounds the letter quiz has; each adds one letter.
const letterQuizRounds = 3;

/// The letter quiz for [word]: [letterQuizRounds] rounds of four shuffled
/// options. Round k offers the word's first k letters and three
/// distractors that share its first k - 1 letters and differ in the last.
///
/// Distractors are the beginnings of other words in [words]; when fewer
/// than three of those exist, random letters fill in.
List<List<String>> letterRounds(
  String word,
  List<String> words,
  Random random,
) => [
  for (var k = 1; k <= letterQuizRounds; k++)
    _letterRound(word.substring(0, k), words, random),
];

List<String> _letterRound(String right, List<String> words, Random random) {
  final found = right.substring(0, right.length - 1);
  final candidates = {
    for (final w in words)
      if (w.length >= right.length && w.startsWith(found))
        w.substring(0, right.length),
  }..remove(right);
  final distractors = (candidates.toList()..shuffle(random)).take(3).toList();
  const letters = 'abcdefghijklmnopqrstuvwxyz';
  final spare = [
    for (final l in letters.split(''))
      if (!distractors.contains('$found$l') && '$found$l' != right) '$found$l',
  ]..shuffle(random);
  distractors.addAll(spare.take(3 - distractors.length));
  return [right, ...distractors]..shuffle(random);
}

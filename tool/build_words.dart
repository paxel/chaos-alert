// Builds assets/words.txt and assets/simple_words.txt from SCOWL and
// 12dicts.
//
//   curl -L -o scowl.tar.gz https://downloads.sourceforge.net/wordlist/scowl-2020.12.07.tar.gz
//   curl -L -o wl.tar.gz https://github.com/en-wl/wordlist/archive/refs/tags/rel-2020.12.07.tar.gz
//   tar xzf scowl.tar.gz && tar xzf wl.tar.gz
//   dart tool/build_words.dart scowl-2020.12.07/final \
//       wordlist-rel-2020.12.07/alt12dicts/2of12id.txt
//
// A word makes the less common list when it is in SCOWL size 40 but not in
// a smaller size (less common, but not obscure), and the simple list when
// it is in size 35 but not in 10 or 20 (common, but not basic). Either way
// it is a headword of the 12dicts 2of12id list (a real dictionary entry,
// not an inflection), is 5 to 10 lowercase letters long and is not an
// adverb ending in -ly.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'usage: dart tool/build_words.dart <scowl final dir> <2of12id.txt>',
    );
    exit(64);
  }
  Set<String> level(int size) =>
      File('${args[0]}/english-words.$size')
          .readAsStringSync(encoding: latin1)
          .split(RegExp(r'\s+'))
          .toSet();

  final basic = {...level(10), ...level(20)};
  final headwords = {
    for (final line in File(args[1]).readAsLinesSync(encoding: latin1))
      if (line.split(RegExp(r'\s+')) case [final w, ...]
          when w.isNotEmpty && !w.startsWith('-') && !w.startsWith('+'))
        w,
  };
  final shape = RegExp(r'^[a-z]{5,10}$');
  void write(String path, Set<String> level, Set<String> smaller) {
    final words =
        level
            .difference(smaller)
            .where(
              (w) =>
                  headwords.contains(w) &&
                  shape.hasMatch(w) &&
                  !w.endsWith('ly'),
            )
            .toList()
          ..sort();
    File(path).writeAsStringSync('${words.join('\n')}\n');
    stdout.writeln('${words.length} words written to $path');
  }

  final simple = level(35);
  write('assets/words.txt', level(40), {...basic, ...simple});
  write('assets/simple_words.txt', simple, basic);
}

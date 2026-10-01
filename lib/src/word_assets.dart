import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled word list, one word per line.
Future<List<String>> loadWords(AssetBundle bundle) async =>
    (await bundle.loadString('assets/words.txt'))
        .split('\n')
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();

/// Puts the word list's copyright notice on the licences page; SCOWL's
/// licence asks for it in every copy.
void registerWordLicence(AssetBundle bundle) =>
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        'Word list (SCOWL, 12dicts)',
      ], await bundle.loadString('assets/WORDS-LICENSE.txt'));
    });

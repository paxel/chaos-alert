import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app.dart';
import 'src/controller.dart';
import 'src/platform.dart';
import 'src/word_assets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  registerWordLicence(rootBundle);
  final words = await loadWords(rootBundle);
  final nagLines = await loadNagLines(rootBundle);
  final controller = Controller(
    store: SqliteStore.open('${dir.path}/chaos-alert.db'),
    platform: ChannelAlarmPlatform(),
    words: words,
    nagLines: nagLines,
  );
  runApp(ChaosAlertApp(controller: controller));
}

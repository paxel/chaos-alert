import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app.dart';
import 'src/controller.dart';
import 'src/platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  final words = (await rootBundle.loadString('assets/words.txt'))
      .split('\n')
      .map((w) => w.trim())
      .where((w) => w.isNotEmpty)
      .toList();
  final controller = Controller(
    store: SqliteStore.open('${dir.path}/chaos-alert.db'),
    platform: ChannelAlarmPlatform(),
    words: words,
  );
  runApp(ChaosAlertApp(controller: controller));
}

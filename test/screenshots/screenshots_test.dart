// Store screenshots, rendered from the real screens over demo data.
//
//   flutter test test/screenshots --run-skipped --concurrency=1
//
// Writes fastlane/metadata/android/en-US/images/phoneScreenshots/NN-name.png
// at 1080 × 1920. Skipped in the normal suite.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:chaos_alert/l10n/app_localizations.dart';
import 'package:chaos_alert/src/alarm_screens.dart';
import 'package:chaos_alert/src/app.dart';
import 'package:chaos_alert/src/controller.dart';
import 'package:chaos_alert/src/home_screen.dart';
import 'package:chaos_alert/src/night_screens.dart';
import 'package:chaos_alert/src/platform.dart';
import 'package:chaos_alert/src/timeline_screen.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_platform.dart';

const _out = 'fastlane/metadata/android/en-US/images/phoneScreenshots';

Future<void> _loadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT']!;
  final fonts = '$root/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('$fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// Thursday 29 October 2026, late in the month so the month view is full.
final _now = DateTime(2026, 10, 29, 21, 0);

/// A month of nights ending this morning: mostly right, a few wrong, a
/// missed alarm and a night without a word.
List<NightRecord> _nights() {
  final random = Random(7);
  final records = <NightRecord>[];
  for (var i = 30; i >= 1; i--) {
    final morning = DateTime(2026, 10, 29 - i + 1);
    // Free weekends: no nag, no bar.
    if (morning.weekday >= DateTime.saturday) continue;
    final planned = DateTime(
      morning.year,
      morning.month,
      morning.day - 1,
      22,
      30,
    );
    final late = random.nextInt(80) - 15;
    final result = switch (i) {
      4 || 11 || 19 || 25 => NightResult.failure,
      15 => NightResult.missed,
      22 => NightResult.noWord,
      _ => NightResult.success,
    };
    records.add(
      NightRecord(
        plannedBedtime: planned,
        bedtime: planned.add(Duration(minutes: late)),
        bedtimeAssumed: result == NightResult.noWord,
        end: DateTime(
          morning.year,
          morning.month,
          morning.day,
          6,
          30,
        ).add(Duration(minutes: random.nextInt(25))),
        result: result,
        word: 'touchstone',
        wrongPicks: result == NightResult.failure ? 1 + i % 3 : 0,
      ),
    );
  }
  return records;
}

void main() {
  late List<String> words;

  setUpAll(() async {
    await _loadRealFonts();
    words = (await rootBundle.loadString('assets/words.txt'))
        .split('\n')
        .where((w) => w.isNotEmpty)
        .toList();
    Directory(_out).createSync(recursive: true);
  });

  Future<Controller> demo({DateTime? now}) async {
    final store = MemoryStore();
    store
      ..saveAlarm(
        const Alarm(id: 0, time: ClockTime(6, 30), weekdays: {1, 2, 3, 4, 5}),
      )
      ..saveAlarm(
        Alarm(
          id: 0,
          time: const ClockTime(5, 15),
          date: DateTime(2026, 11, 14),
        ),
      )
      ..saveAlarm(
        const Alarm(
          id: 0,
          time: ClockTime(7, 45),
          weekdays: {6, 7},
          enabled: false,
        ),
      )
      ..saveAlarm(
        const Alarm(
          id: 0,
          time: ClockTime(13, 0),
          weekdays: {3},
          wakeUp: false,
        ),
      )
      ..saveState(store.loadState()..setupDone = true);
    for (final r in _nights()) {
      store.addRecord(r);
    }
    final c = Controller(
      store: store,
      platform: FakePlatform(),
      words: words,
      clock: () => now ?? _now,
      random: Random(3),
    );
    await c.refresh();
    return c;
  }

  /// Renders [screen] and writes it as [name]; [prepare] runs on the
  /// shown screen first, e.g. to switch a view.
  Future<void> shoot(
    WidgetTester tester,
    Widget screen,
    String name, {
    Future<void> Function()? prepare,
  }) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: chaosTheme(),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (prepare != null) {
      await prepare();
      await tester.pumpAndSettle();
    }
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  testWidgets('generate', (tester) async {
    // Evening, inside the window: the home offers "I'm in bed".
    var c = await demo();
    await shoot(tester, HomeScreen(controller: c), '01-home');

    c = await demo(now: DateTime(2026, 10, 29, 22, 30));
    await shoot(tester, NagScreen(controller: c), '02-nag');
    await shoot(tester, const WordScreen(word: 'lantern'), '03-word');

    // The morning after: the quiz on the 06:30 alarm.
    c = await demo(now: DateTime(2026, 10, 29, 22, 30));
    final word = await c.inBed();
    final alarm = c.alarms.firstWhere((a) => a.time == const ClockTime(6, 30));
    (c.platform as FakePlatform).events.add(
      RingStarted(alarm.id, DateTime(2026, 10, 30, 6, 30)),
    );
    await c.refresh();
    await shoot(
      tester,
      AlarmScreen(controller: c, alarmId: alarm.id),
      '04-quiz',
    );

    // Two wrong picks, then the right word: the page after a failed night.
    for (var i = 0; i < 2; i++) {
      c.engine.answer(
        alarm.id,
        c.screenFor(alarm.id).options.firstWhere((o) => o != word),
      );
    }
    final outcome = c.engine.answer(alarm.id, word)!;
    await shoot(tester, SummaryScreen(outcome: outcome), '05-failure');

    c = await demo();
    await shoot(tester, AlarmsScreen(controller: c), '06-alarms');
    await shoot(tester, TimelineScreen(controller: c), '07-week');

    await shoot(
      tester,
      TimelineScreen(controller: c),
      '08-month',
      prepare: () => tester.tap(find.text('Month')),
    );
  }, skip: true);
}

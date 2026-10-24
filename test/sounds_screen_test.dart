import 'dart:math';

import 'package:chaos_alert/l10n/app_localizations.dart';
import 'package:chaos_alert/src/controller.dart';
import 'package:chaos_alert/src/platform.dart';
import 'package:chaos_alert/src/sounds_screen.dart';
import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_platform.dart';

void main() {
  late MemoryStore store;
  late FakePlatform platform;
  late Controller controller;

  setUp(() {
    store = MemoryStore();
    platform = FakePlatform();
    controller = Controller(
      store: store,
      platform: platform,
      words: const ['verdict', 'venture', 'harbour', 'lantern'],
      clock: () => DateTime(2026, 10, 5, 12),
      random: Random(1),
    );
  });

  Widget app() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: SoundsScreen(controller: controller),
  );

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  const allOff =
      "Every source is off. Only the phone's default alarm sound will ring.";

  testWidgets('every source has a switch; all off warns', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text(allOff), findsNothing);
    await tapText(tester, 'Alarm sounds');
    await tapText(tester, 'Notification sounds');
    await tapText(tester, 'Songs');
    expect(find.text(allOff), findsNothing);
    await tapText(tester, 'Generated sounds');
    final s = store.loadSettings();
    expect(
      [s.alarmSounds, s.notificationSounds, s.songs, s.generated],
      [false, false, false, false],
    );
    expect(find.text(allOff), findsOneWidget);
  });

  testWidgets('folders are added, switched, shown and removed', (tester) async {
    platform.folders['tree/rock'] = [
      for (var i = 0; i < 3; i++)
        Sound(uri: 'rock/$i', group: SoundGroup.folder, folder: 'tree/rock'),
    ];
    platform.nextFolder = const SoundFolder(uri: 'tree/rock', name: 'Rock');
    await tester.pumpWidget(app());
    await tapText(tester, 'Add folder');
    expect(find.text('Rock'), findsOneWidget);
    expect(find.text('3 sounds'), findsOneWidget);
    expect(find.text('Pick again'), findsNothing);
    final row = find.byKey(const ValueKey('folder-tree/rock'));
    await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(store.loadSettings().folders.single.on, isFalse);
    await tester.tap(find.byTooltip('Remove folder'));
    await tester.pumpAndSettle();
    expect(find.text('Rock'), findsNothing);
    expect(platform.released, ['tree/rock']);
  });

  testWidgets('an empty or lost folder says so and can be picked again', (
    tester,
  ) async {
    store.saveSettings(
      const Settings(
        folders: [
          SoundFolder(uri: 'tree/empty', name: 'Empty'),
          SoundFolder(uri: 'tree/gone', name: 'Gone'),
        ],
      ),
    );
    platform.folders['tree/empty'] = const [];
    await controller.refresh();
    await controller.foldersRead;
    await tester.pumpWidget(app());
    expect(find.text('No sounds found'), findsOneWidget);
    expect(find.text('Access lost'), findsOneWidget);
    platform.folders['tree/back'] = const [
      Sound(uri: 'back/1', group: SoundGroup.folder, folder: 'tree/back'),
    ];
    platform.nextFolder = const SoundFolder(uri: 'tree/back', name: 'Back');
    final gone = find.byKey(const ValueKey('folder-tree/gone'));
    await tester.tap(
      find.descendant(of: gone, matching: find.text('Pick again')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gone'), findsNothing);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('1 sound'), findsOneWidget);
    expect(
      [for (final f in store.loadSettings().folders) f.name],
      ['Empty', 'Back'],
    );
  });

  testWidgets('without music access a hint offers to allow it', (tester) async {
    platform.granted[Permission.music] = false;
    await controller.refresh();
    await tester.pumpWidget(app());
    expect(find.text('Songs are left out'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(platform.requested, [Permission.music]);
    expect(find.text('Songs are left out'), findsNothing);
  });
}

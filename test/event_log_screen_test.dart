import 'package:chaos_alert/l10n/app_localizations.dart';
import 'package:chaos_alert/src/about_screen.dart';
import 'package:chaos_alert/src/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  Widget app(List<LogEntry> log) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AboutScreen(
      version: Future.value(
        PackageInfo(
          appName: 'chaos-alert',
          packageName: 'io.github.paxel.chaos_alert',
          version: '0.4.0',
          buildNumber: '4',
        ),
      ),
      readLog: () async => log,
    ),
  );

  Future<void> openLog(WidgetTester tester, List<LogEntry> log) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(log));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Event log'));
    await tester.pumpAndSettle();
  }

  testWidgets('About leads to the event log, which copies every line', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await openLog(tester, [
      LogEntry(DateTime(2026, 10, 6, 6, 30), 'android: ring started alarm 1'),
      LogEntry(DateTime(2026, 10, 6, 6, 31, 5), 'app: alarm 1 snoozed'),
    ]);
    expect(
      find.text('2026-10-06 06:30:00 android: ring started alarm 1'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Copy'));
    await tester.pumpAndSettle();
    expect(
      copied,
      '2026-10-06 06:30:00 android: ring started alarm 1\n'
      '2026-10-06 06:31:05 app: alarm 1 snoozed',
    );
    expect(find.text('Event log copied'), findsOneWidget);
  });

  testWidgets('an empty log says so', (tester) async {
    await openLog(tester, const []);
    expect(find.text('Nothing logged yet'), findsOneWidget);
  });
}

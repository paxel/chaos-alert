import 'package:chaos_alert/l10n/app_localizations.dart';
import 'package:chaos_alert/src/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  Widget app() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AboutScreen(
      version: Future.value(
        PackageInfo(
          appName: 'chaos-alert',
          packageName: 'io.github.paxel.chaos_alert',
          version: '0.1.0',
          buildNumber: '1',
        ),
      ),
    ),
  );

  /// A screen tall enough for the whole page.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
  }

  testWidgets('shows the version and the same entries as catlog', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Version 0.1.0 (1)'), findsOneWidget);
    for (final entry in [
      'Source code',
      'Report a problem or idea',
      'Write the developer',
      'Buy the developer a coffee',
      'Open-source licenses',
    ]) {
      expect(find.text(entry), findsOneWidget, reason: entry);
    }
    expect(
      find.text('https://github.com/paxel/chaos-alert — Apache-2.0 / MIT'),
      findsOneWidget,
    );
  });

  testWidgets('the red button thanks you', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text("DON'T PRESS.\nDANGER"));
    await tester.pumpAndSettle();
    expect(find.text('Thank you for using chaos-alert!'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Thank you for using chaos-alert!'), findsNothing);
  });

  testWidgets('the licences entry opens the licences page', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Open-source licenses'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LicensePage), findsOneWidget);
  });
}

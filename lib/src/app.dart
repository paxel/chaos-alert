import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'controller.dart';
import 'home_screen.dart';
import 'night_screens.dart';
import 'platform.dart';
import 'setup_screen.dart';

/// The app's one theme: always dark.
ThemeData chaosTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  ),
);

/// The app: always dark, the setup at first start, and the nag or the
/// alarm on top whenever Android opens the app for one.
class ChaosAlertApp extends StatefulWidget {
  const ChaosAlertApp({super.key, required this.controller});

  final Controller controller;

  @override
  State<ChaosAlertApp> createState() => _ChaosAlertAppState();
}

class _ChaosAlertAppState extends State<ChaosAlertApp>
    with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  StreamSubscription<Launch>? _launches;

  Controller get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _launches = _c.platform.launches.listen(_open);
    _start();
  }

  // Coming back to the app is when Android's queue gets read.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_c.refresh());
  }

  Future<void> _start() async {
    await _c.refresh();
    final launch = await _c.platform.initialLaunch();
    if (!mounted) return;
    if (launch != null) {
      await _open(launch);
    } else if (!_c.setupDone) {
      unawaited(
        _navigator.currentState?.push(
          MaterialPageRoute<void>(builder: (_) => SetupScreen(controller: _c)),
        ),
      );
    }
  }

  Future<void> _open(Launch launch) async {
    await _c.refresh();
    if (!mounted) return;
    final screen = switch (launch) {
      NagLaunch() => NagScreen(controller: _c),
      RingLaunch(:final alarmId) => AlarmScreen(
        controller: _c,
        alarmId: alarmId,
      ),
    };
    unawaited(
      _navigator.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _launches?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigator,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: chaosTheme(),
    home: HomeScreen(controller: _c),
  );
}

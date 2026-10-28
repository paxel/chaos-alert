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
  StreamSubscription<void>? _events;

  /// The nag on screen; there is never more than one.
  Route<void>? _nag;

  Controller get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _launches = _c.platform.launches.listen(_open);
    _events = _c.platform.eventsArrived.listen((_) => _c.refresh());
    _c.addListener(_closeStaleNag);
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
    _c.log('opened for $launch');
    // A nag that fired outside bedtime was dropped; it shows nothing.
    if (launch is NagLaunch && !_c.canSayInBed && !_c.canFetchWord) return;
    // A new nag takes the place of the one still open.
    if (launch is NagLaunch) _removeNag();
    final screen = switch (launch) {
      NagLaunch() => NagScreen(controller: _c),
      AwakeLaunch() => AwakeScreen(controller: _c),
      RingLaunch(:final alarmId) => AlarmScreen(
        controller: _c,
        alarmId: alarmId,
      ),
    };
    final route = MaterialPageRoute<void>(builder: (_) => screen);
    if (launch is NagLaunch) _nag = route;
    unawaited(_navigator.currentState?.push(route));
  }

  /// A nag still open when its night is over closes, wherever it sits,
  /// e.g. under the morning's alarm.
  void _closeStaleNag() {
    if (!_c.isBedtime) _removeNag();
  }

  void _removeNag() {
    final nag = _nag;
    _nag = null;
    // Answered nags are gone already.
    if (nag != null && nag.isActive) _navigator.currentState?.removeRoute(nag);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.removeListener(_closeStaleNag);
    _launches?.cancel();
    _events?.cancel();
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

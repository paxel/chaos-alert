import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'about_screen.dart';
import 'alarm_screens.dart';
import 'controller.dart';
import 'night_screens.dart';
import 'setup_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';
import 'vacation_screen.dart';

/// The main screen: what comes next, "I'm in bed" when it is time, and the
/// way to everything else.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final Controller controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Timer _ticker;

  Controller get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _c.tick());
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _open(Widget Function() screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen()));

  Future<void> _inBed() async {
    final word = await _c.inBed();
    if (!mounted) return;
    _open(() => WordScreen(word: word));
  }

  String _moment(BuildContext context, DateTime t) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(t));
    return '${DateFormat.E(locale).format(t)} $time';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final plan = _c.plan;
        final nag = plan.nextNag;
        final rings = plan.rings;
        final missing =
            _c.hasPermissionInfo && _c.missingPermissions.isNotEmpty;
        return Scaffold(
          appBar: AppBar(title: Text(t.appTitle)),
          body: ListView(
            children: [
              if (missing)
                MaterialBanner(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  content: Text(t.homeBanner),
                  actions: [
                    TextButton(
                      onPressed: () => _open(() => SetupScreen(controller: _c)),
                      child: Text(t.homeBannerFix),
                    ),
                  ],
                ),
              if (_c.pendingHint)
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(t.failureHint),
                        TextButton(
                          onPressed: _c.dismissHint,
                          child: Text(t.hintDismiss),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (nag != null)
                Center(child: Text(t.homeBedtime(_moment(context, nag)))),
              Center(
                child: Text(
                  rings.isEmpty
                      ? t.homeNoAlarm
                      : t.homeNextAlarm(_moment(context, rings.first.at)),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 24),
              if (_c.canSayAwake)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: FilledButton.icon(
                    onPressed: () => _open(() => AwakeScreen(controller: _c)),
                    icon: const Icon(Icons.wb_sunny),
                    label: Text(t.homeAwake),
                  ),
                ),
              if (_c.canSayInBed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: FilledButton.icon(
                    onPressed: _inBed,
                    icon: const Icon(Icons.bedtime),
                    label: Text(t.homeInBed),
                  ),
                ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(t.alarmsTitle),
                onTap: () => _open(() => AlarmsScreen(controller: _c)),
              ),
              ListTile(
                leading: const Icon(Icons.beach_access),
                title: Text(t.vacationsTitle),
                onTap: () => _open(() => VacationScreen(controller: _c)),
              ),
              ListTile(
                leading: const Icon(Icons.timeline),
                title: Text(t.timelineTitle),
                onTap: () => _open(() => TimelineScreen(controller: _c)),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(t.settingsTitle),
                onTap: () => _open(() => SettingsScreen(controller: _c)),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(t.aboutAndFeedback),
                onTap: () => _open(() => const AboutScreen()),
              ),
            ],
          ),
        );
      },
    );
  }
}

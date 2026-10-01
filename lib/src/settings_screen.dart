import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'controller.dart';
import 'platform.dart';

String durationText(AppLocalizations t, Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h == 0 ? t.durationM(m) : t.durationHm(h, m);
}

/// Every setting that is not an alarm or a vacation.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final Controller controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final s = controller.settings;
          void save(Settings next) => controller.saveSettings(next);
          Widget duration(
            String key,
            String title,
            Duration value,
            Duration step,
            Duration min,
            Duration max,
            Settings Function(Duration) apply,
          ) => _Stepper(
            keyName: key,
            title: title,
            value: durationText(t, value),
            onLess: value - step >= min
                ? () => save(apply(value - step))
                : null,
            onMore: value + step <= max
                ? () => save(apply(value + step))
                : null,
          );
          Widget volume(
            String key,
            String title,
            double value,
            double min,
            double max,
            Settings Function(double) apply,
          ) {
            final percent = (value * 100).round();
            return _Stepper(
              keyName: key,
              title: title,
              value: t.percent(percent),
              onLess: percent - 5 >= (min * 100).round()
                  ? () => save(apply((percent - 5) / 100))
                  : null,
              onMore: percent + 5 <= (max * 100).round()
                  ? () => save(apply((percent + 5) / 100))
                  : null,
            );
          }

          return ListView(
            children: [
              if (controller.missingPermissions.contains(Permission.music))
                ListTile(
                  leading: const Icon(Icons.music_off),
                  title: Text(t.settingsMusic),
                  subtitle: Text(t.settingsMusicHint),
                  trailing: TextButton(
                    onPressed: () => controller.request(Permission.music),
                    child: Text(t.settingsMusicGrant),
                  ),
                ),
              duration(
                'sleep',
                t.settingsSleepLength,
                s.sleepLength,
                const Duration(minutes: 15),
                const Duration(hours: 4),
                const Duration(hours: 12),
                (d) => s.copyWith(sleepLength: d),
              ),
              duration(
                'nagSnooze',
                t.settingsNagSnooze,
                s.nagSnooze,
                const Duration(minutes: 5),
                const Duration(minutes: 5),
                const Duration(minutes: 60),
                (d) => s.copyWith(nagSnooze: d),
              ),
              duration(
                'alarmSnooze',
                t.settingsAlarmSnooze,
                s.alarmSnooze,
                const Duration(minutes: 1),
                const Duration(minutes: 1),
                const Duration(minutes: 30),
                (d) => s.copyWith(alarmSnooze: d),
              ),
              duration(
                'timeout',
                t.settingsAlarmTimeout,
                s.alarmTimeout,
                const Duration(minutes: 1),
                const Duration(minutes: 1),
                const Duration(minutes: 60),
                (d) => s.copyWith(alarmTimeout: d),
              ),
              volume(
                'low',
                t.settingsLowVolume,
                s.lowVolume,
                0.05,
                s.mediumVolume,
                (v) => s.copyWith(lowVolume: v),
              ),
              volume(
                'medium',
                t.settingsMediumVolume,
                s.mediumVolume,
                s.lowVolume,
                1,
                (v) => s.copyWith(mediumVolume: v),
              ),
              SwitchListTile(
                title: Text(t.settingsChime),
                subtitle: Text(t.settingsChimeHint),
                value: s.chime,
                onChanged: (on) => save(s.copyWith(chime: on)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A setting changed in steps with − and +.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.keyName,
    required this.title,
    required this.value,
    required this.onLess,
    required this.onMore,
  });

  final String keyName;
  final String title;
  final String value;
  final VoidCallback? onLess;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListTile(
      title: Text(title),
      subtitle: Text(value, key: ValueKey('$keyName-value')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('$keyName-less'),
            tooltip: t.less,
            icon: const Icon(Icons.remove),
            onPressed: onLess,
          ),
          IconButton(
            key: ValueKey('$keyName-more'),
            tooltip: t.more,
            icon: const Icon(Icons.add),
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'controller.dart';
import 'platform.dart';

(String, String) permissionText(AppLocalizations t, Permission p) =>
    switch (p) {
      Permission.exactAlarms => (t.permExactAlarms, t.permExactAlarmsWhy),
      Permission.notifications => (t.permNotifications, t.permNotificationsWhy),
      Permission.fullScreen => (t.permFullScreen, t.permFullScreenWhy),
      Permission.battery => (t.permBattery, t.permBatteryWhy),
      Permission.music => (t.permMusic, t.permMusicWhy),
    };

/// Asks for each permission in turn: at first start, and from the banner
/// whenever one goes missing.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.controller});

  final Controller controller;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  var _step = 0;

  Controller get _c => widget.controller;

  void _next() {
    if (_step < Permission.values.length - 1) {
      setState(() => _step++);
      return;
    }
    _c.finishSetup();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final permission = Permission.values[_step];
    final (title, why) = permissionText(t, permission);
    final last = _step == Permission.values.length - 1;
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final granted = !_c.missingPermissions.contains(permission);
        return Scaffold(
          appBar: AppBar(title: Text(t.setupTitle)),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.setupStep(_step + 1, Permission.values.length)),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(why),
                const SizedBox(height: 24),
                if (granted)
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(t.setupGranted),
                    ],
                  )
                else
                  FilledButton(
                    onPressed: () => _c.request(permission),
                    child: Text(t.setupAllow),
                  ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _next,
                  child: Text(last ? t.setupDone : t.setupNext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

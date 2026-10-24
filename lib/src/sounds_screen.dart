import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'controller.dart';
import 'platform.dart';

/// Where the alarm sounds come from: a switch for every source, and the
/// picked folders.
class SoundsScreen extends StatelessWidget {
  const SoundsScreen({super.key, required this.controller});

  final Controller controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsSounds)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final s = controller.settings;
          final counts = controller.folderCounts;
          void save(Settings settings) => controller.saveSettings(settings);
          return ListView(
            children: [
              if (s.allSoundsOff)
                ListTile(
                  leading: const Icon(Icons.warning_amber),
                  title: Text(t.soundsAllOff),
                ),
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
              SwitchListTile(
                title: Text(t.soundsAlarms),
                value: s.alarmSounds,
                onChanged: (on) => save(s.copyWith(alarmSounds: on)),
              ),
              SwitchListTile(
                title: Text(t.soundsNotifications),
                value: s.notificationSounds,
                onChanged: (on) => save(s.copyWith(notificationSounds: on)),
              ),
              SwitchListTile(
                title: Text(t.soundsSongs),
                subtitle: Text(t.soundsSongsHint),
                value: s.songs,
                onChanged: (on) => save(s.copyWith(songs: on)),
              ),
              SwitchListTile(
                title: Text(t.soundsGenerated),
                subtitle: Text(t.soundsGeneratedHint),
                value: s.generated,
                onChanged: (on) => save(s.copyWith(generated: on)),
              ),
              ListTile(title: Text(t.soundsFolders)),
              for (final f in s.folders)
                ListTile(
                  key: ValueKey('folder-${f.uri}'),
                  title: Text(f.name),
                  subtitle: switch (counts[f.uri]) {
                    null when counts.containsKey(f.uri) => Text(
                      t.soundsFolderLost,
                    ),
                    0 => Text(t.soundsFolderEmpty),
                    final int n => Text(t.soundsFolderCount(n)),
                    null => null,
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (counts.containsKey(f.uri) &&
                          (counts[f.uri] ?? 0) == 0)
                        TextButton(
                          onPressed: () => controller.repickFolder(f.uri),
                          child: Text(t.soundsFolderRepick),
                        ),
                      Switch(
                        value: f.on,
                        onChanged: (on) => save(
                          s.copyWith(
                            folders: [
                              for (final other in s.folders)
                                other.uri == f.uri
                                    ? other.copyWith(on: on)
                                    : other,
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: t.soundsFolderRemove,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => controller.removeFolder(f.uri),
                      ),
                    ],
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: Text(t.soundsAddFolder),
                onTap: controller.addFolder,
              ),
            ],
          );
        },
      ),
    );
  }
}

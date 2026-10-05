import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'platform.dart';

/// What the app and Android did in the last seven days, to copy into a bug
/// report when an alarm or a nag behaved oddly.
class EventLogScreen extends StatefulWidget {
  const EventLogScreen({super.key, required this.readLog});

  final Future<List<LogEntry>> Function() readLog;

  @override
  State<EventLogScreen> createState() => _EventLogScreenState();
}

class _EventLogScreenState extends State<EventLogScreen> {
  late final Future<List<String>> _lines = widget.readLog().then(
    (log) => [for (final e in log) _line(e)],
  );

  static String _line(LogEntry e) =>
      '${DateFormat('yyyy-MM-dd HH:mm:ss').format(e.at)} ${e.text}';

  Future<void> _copy(List<String> lines) async {
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).eventLogCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<List<String>>(
      future: _lines,
      builder: (context, snapshot) {
        final lines = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(t.eventLog),
            actions: [
              IconButton(
                tooltip: t.eventLogCopy,
                icon: const Icon(Icons.copy),
                onPressed: lines == null || lines.isEmpty
                    ? null
                    : () => _copy(lines),
              ),
            ],
          ),
          body: switch (lines) {
            null => const Center(child: CircularProgressIndicator()),
            [] => Center(child: Text(t.eventLogEmpty)),
            _ => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lines.length,
              itemBuilder: (_, i) => Text(
                lines[i],
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          },
        );
      },
    );
  }
}

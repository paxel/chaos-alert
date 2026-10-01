import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'controller.dart';

/// The short name of [weekday] (1 = Monday) in the app's locale.
String weekdayName(BuildContext context, int weekday) {
  // 2024-01-01 was a Monday.
  final day = DateTime(2024, 1, weekday);
  return DateFormat.E(Localizations.localeOf(context).toLanguageTag())
      .format(day);
}

String clockText(BuildContext context, ClockTime t) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: t.hour, minute: t.minute));

String _when(BuildContext context, Alarm a) {
  final date = a.date;
  if (date != null) {
    return DateFormat.yMMMEd(Localizations.localeOf(context).toLanguageTag())
        .format(date);
  }
  final days = a.weekdays.toList()..sort();
  return days.map((d) => weekdayName(context, d)).join(' ');
}

/// Every alarm, with a switch each and a button to add one.
class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key, required this.controller});

  final Controller controller;

  Future<void> _edit(BuildContext context, Alarm? alarm) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AlarmEditor(controller: controller, alarm: alarm),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.alarmsTitle)),
      floatingActionButton: FloatingActionButton(
        tooltip: t.alarmAdd,
        onPressed: () => _edit(context, null),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final alarms = controller.alarms
            ..sort(
              (a, b) => a.time.minutesOfDay.compareTo(b.time.minutesOfDay),
            );
          if (alarms.isEmpty) return Center(child: Text(t.alarmsEmpty));
          return ListView(
            children: [
              for (final a in alarms)
                ListTile(
                  key: ValueKey('alarm-${a.id}'),
                  title: Text(
                    clockText(context, a.time),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  subtitle: Text(
                    [
                      _when(context, a),
                      if (!a.wakeUp) t.alarmReminder,
                    ].join(' · '),
                  ),
                  trailing: Switch(
                    value: a.enabled,
                    onChanged: (on) =>
                        controller.saveAlarm(a.copyWith(enabled: on)),
                  ),
                  onTap: () => _edit(context, a),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Creates or edits one alarm.
class AlarmEditor extends StatefulWidget {
  const AlarmEditor({super.key, required this.controller, this.alarm});

  final Controller controller;

  /// Null for a new alarm.
  final Alarm? alarm;

  @override
  State<AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<AlarmEditor> {
  late ClockTime _time;
  late bool _once;
  late Set<int> _weekdays;
  late DateTime _date;
  late bool _wakeUp;

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    final now = widget.controller.clock();
    _time = a?.time ?? const ClockTime(6, 30);
    _once = a?.oneTime ?? false;
    _weekdays = Set.of(a?.weekdays ?? const {1, 2, 3, 4, 5});
    _date = a?.date ?? DateTime(now.year, now.month, now.day + 1);
    _wakeUp = a?.wakeUp ?? true;
  }

  bool get _valid => _once || _weekdays.isNotEmpty;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _time.hour, minute: _time.minute),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = ClockTime(picked.hour, picked.minute));
  }

  Future<void> _pickDate() async {
    final now = widget.controller.clock();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _save() async {
    final alarm = Alarm(
      id: widget.alarm?.id ?? 0,
      time: _time,
      weekdays: _once ? const {} : _weekdays,
      date: _once ? _date : null,
      enabled: true,
      wakeUp: _wakeUp,
    );
    await widget.controller.saveAlarm(alarm);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await widget.controller.deleteAlarm(widget.alarm!.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(
        title: Text(t.alarmEditTitle),
        actions: [
          if (widget.alarm != null)
            IconButton(
              tooltip: t.alarmDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: TextButton(
              key: const ValueKey('alarm-time'),
              onPressed: _pickTime,
              child: Text(
                clockText(context, _time),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(t.alarmRepeating)),
              ButtonSegment(value: true, label: Text(t.alarmOnce)),
            ],
            selected: {_once},
            onSelectionChanged: (s) => setState(() => _once = s.single),
          ),
          const SizedBox(height: 16),
          if (_once)
            ListTile(
              title: Text(t.alarmDate),
              subtitle: Text(DateFormat.yMMMEd(locale).format(_date)),
              onTap: _pickDate,
            )
          else ...[
            Wrap(
              spacing: 6,
              children: [
                for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                  FilterChip(
                    label: Text(weekdayName(context, d)),
                    selected: _weekdays.contains(d),
                    onSelected: (on) => setState(
                      () => on ? _weekdays.add(d) : _weekdays.remove(d),
                    ),
                  ),
              ],
            ),
            if (_weekdays.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t.alarmNoDays,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(t.alarmWakeUp),
            subtitle: Text(t.alarmWakeUpHint),
            value: _wakeUp,
            onChanged: (on) => setState(() => _wakeUp = on),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _valid ? _save : null,
            child: Text(t.alarmSave),
          ),
        ],
      ),
    );
  }
}

import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'alarm_screens.dart';
import 'controller.dart';
import 'results.dart';
import 'settings_screen.dart';

/// The axis of every bar: from 20:00 in the evening to 12:00 next day.
const axisStartHour = 20;
const axisHours = 16;

/// Where [t] sits on the axis of the night ending on [morning], 0 to 1.
double axisPosition(DateTime morning, DateTime t) {
  final start = DateTime(
    morning.year,
    morning.month,
    morning.day - 1,
    axisStartHour,
  );
  final minutes = t.difference(start).inMinutes / (axisHours * 60);
  return minutes.clamp(0.0, 1.0);
}

/// The mornings of the week or month around [anchor].
List<DateTime> periodMornings(DateTime anchor, {required bool month}) {
  if (month) {
    final days = DateTime(anchor.year, anchor.month + 1, 0).day;
    return [
      for (var d = 1; d <= days; d++) DateTime(anchor.year, anchor.month, d),
    ];
  }
  final monday = DateTime(
    anchor.year,
    anchor.month,
    anchor.day - (anchor.weekday - DateTime.monday),
  );
  return [
    for (var i = 0; i < 7; i++)
      DateTime(monday.year, monday.month, monday.day + i),
  ];
}

/// One bar per night across a time axis, for a week or a month.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key, required this.controller});

  final Controller controller;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  var _month = false;
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    _anchor = dateOf(widget.controller.clock());
  }

  void _move(int direction) => setState(() {
    _anchor = _month
        ? DateTime(_anchor.year, _anchor.month + direction, 1)
        : DateTime(_anchor.year, _anchor.month, _anchor.day + 7 * direction);
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final mornings = periodMornings(_anchor, month: _month);
    final byMorning = {for (final r in widget.controller.nights) r.morning: r};
    final shown = [for (final m in mornings) ?byMorning[m]];
    final summary = TimelineSummary.of(shown);
    final title = _month
        ? DateFormat.yMMMM(locale).format(_anchor)
        : '${DateFormat.MMMd(locale).format(mornings.first)} – '
              '${DateFormat.yMMMd(locale).format(mornings.last)}';
    final rowHeight = _month ? 12.0 : 28.0;

    return Scaffold(
      appBar: AppBar(title: Text(t.timelineTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(t.timelineWeek)),
              ButtonSegment(value: true, label: Text(t.timelineMonth)),
            ],
            selected: {_month},
            onSelectionChanged: (s) => setState(() => _month = s.single),
          ),
          Row(
            children: [
              IconButton(
                tooltip: t.timelinePrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _move(-1),
              ),
              Expanded(child: Text(title, textAlign: TextAlign.center)),
              IconButton(
                tooltip: t.timelineNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _move(1),
              ),
            ],
          ),
          if (shown.isEmpty)
            Text(t.timelineEmpty)
          else ...[
            Text(
              t.timelineAverageInBed(durationText(t, summary.averageInBed!)),
            ),
            Text(
              t.timelineAverageBedtime(
                clockText(context, summary.averageBedtime!),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const _AxisLabels(),
          for (final m in mornings)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      _month ? '${m.day}' : weekdayName(context, m.weekday),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: rowHeight,
                      child: NightBar(
                        key: ValueKey('night-${m.year}-${m.month}-${m.day}'),
                        morning: m,
                        record: byMorning[m],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AxisLabels extends StatelessWidget {
  const _AxisLabels();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final h in [20, 0, 4, 8, 12])
            Text(clockText(context, ClockTime(h % 24, 0)), style: style),
        ],
      ),
    );
  }
}

/// The bar of one night: coloured by its result, hatched at the start when
/// the bedtime was assumed, with a tick at the planned bedtime.
class NightBar extends StatelessWidget {
  const NightBar({super.key, required this.morning, required this.record});

  final DateTime morning;
  final NightRecord? record;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _NightPainter(
      morning: morning,
      record: record,
      track: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
  );
}

class _NightPainter extends CustomPainter {
  _NightPainter({
    required this.morning,
    required this.record,
    required this.track,
  });

  final DateTime morning;
  final NightRecord? record;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = track);
    final r = record;
    if (r == null) return;
    final left = axisPosition(morning, r.bedtime) * size.width;
    final right = axisPosition(morning, r.end) * size.width;
    final bar = Rect.fromLTRB(left, 0, right, size.height);
    canvas.drawRect(bar, Paint()..color = resultColor(r.result));
    if (r.bedtimeAssumed) {
      final hatch = Rect.fromLTRB(
        left,
        0,
        (left + size.height * 2).clamp(left, right),
        size.height,
      );
      canvas.save();
      canvas.clipRect(hatch);
      final stroke = Paint()
        ..color = Colors.black54
        ..strokeWidth = 2;
      for (var x = hatch.left - size.height; x < hatch.right; x += 5) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height, 0),
          stroke,
        );
      }
      canvas.restore();
    }
    final planned = axisPosition(morning, r.plannedBedtime) * size.width;
    canvas.drawLine(
      Offset(planned, 0),
      Offset(planned, size.height),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_NightPainter old) =>
      old.record != record || old.morning != morning || old.track != track;
}

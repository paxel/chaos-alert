import 'dart:math';

import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'alarm_screens.dart';
import 'controller.dart';
import 'results.dart';
import 'settings_screen.dart';

/// The time window a period's bars are drawn across: exactly from the
/// earliest bedtime, real or planned, to the latest end of a night in the
/// period, at most a day, so day and afternoon sleepers fit as well as night
/// owls. Two reference lines mark the latest real bedtime and the earliest
/// end, for the other nights to be held against.
class TimeAxis {
  const TimeAxis(this.startMinute, this.minutes, {this.references = const []});

  /// The window of a period without nights: 20:00 to noon.
  static const fallback = TimeAxis(-240, 16 * 60);

  factory TimeAxis.fit(Iterable<NightRecord> records) {
    final list = records.toList();
    if (list.isEmpty) return fallback;
    int offset(NightRecord r, DateTime t) => t.difference(r.morning).inMinutes;
    final earliest = list
        .map((r) => min(offset(r, r.bedtime), offset(r, r.plannedBedtime)))
        .reduce(min);
    final latest = list.map((r) => offset(r, r.end)).reduce(max);
    return TimeAxis(
      earliest,
      (latest - earliest).clamp(1, 24 * 60),
      references: [
        list.map((r) => offset(r, r.bedtime)).reduce(max),
        list.map((r) => offset(r, r.end)).reduce(min),
      ],
    );
  }

  /// Minutes from midnight of the morning a night ends in; negative is the
  /// evening before.
  final int startMinute;
  final int minutes;

  /// Where the reference lines sit, in the same minutes as [startMinute].
  final List<int> references;

  /// Where [t] sits on the axis of the night ending on [morning], 0 to 1.
  double position(DateTime morning, DateTime t) =>
      at(t.difference(morning).inMinutes);

  /// Where [minute], counted like [startMinute], sits on the axis, 0 to 1.
  double at(int minute) => ((minute - startMinute) / minutes).clamp(0.0, 1.0);

  /// The clock times at the start and the end of the axis.
  List<ClockTime> get labels => [
    for (final m in [startMinute, startMinute + minutes])
      ClockTime(m % (24 * 60) ~/ 60, m % 60),
  ];

  @override
  bool operator ==(Object other) =>
      other is TimeAxis &&
      other.startMinute == startMinute &&
      other.minutes == minutes &&
      listEquals(other.references, references);

  @override
  int get hashCode =>
      Object.hash(startMinute, minutes, Object.hashAll(references));
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
    final axis = TimeAxis.fit(shown);
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
          _AxisLabels(axis: axis),
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
                        axis: axis,
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
  const _AxisLabels({required this.axis});

  final TimeAxis axis;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final time in axis.labels)
            Text(clockText(context, time), style: style),
        ],
      ),
    );
  }
}

/// The bar of one night on a black row: coloured by its result, hatched at
/// the start when the bedtime was assumed, with a tick at the planned
/// bedtime and the period's reference lines across it.
class NightBar extends StatelessWidget {
  const NightBar({
    super.key,
    required this.morning,
    required this.record,
    this.axis = TimeAxis.fallback,
  });

  final DateTime morning;
  final NightRecord? record;
  final TimeAxis axis;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _NightPainter(morning: morning, record: record, axis: axis),
  );
}

class _NightPainter extends CustomPainter {
  _NightPainter({
    required this.morning,
    required this.record,
    required this.axis,
  });

  final DateTime morning;
  final NightRecord? record;
  final TimeAxis axis;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    final r = record;
    if (r == null) return;
    final left = axis.position(morning, r.bedtime) * size.width;
    final right = axis.position(morning, r.end) * size.width;
    final bar = Rect.fromLTRB(left, 0, right, size.height);
    canvas.drawRect(bar, Paint()..color = nightColor(r));
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
    final planned = axis.position(morning, r.plannedBedtime) * size.width;
    canvas.drawLine(
      Offset(planned, 0),
      Offset(planned, size.height),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
    // Black on the black track: a reference line shows only across a bar.
    for (final minute in axis.references) {
      final x = axis.at(minute) * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_NightPainter old) =>
      old.record != record || old.morning != morning || old.axis != axis;
}

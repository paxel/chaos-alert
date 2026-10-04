import 'dart:async';

import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'controller.dart';
import 'results.dart';

/// The dim frame of every screen that shows up at night.
class NightFrame extends StatelessWidget {
  const NightFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white70),
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  );
}

/// The bedtime nag: Yes, or Snooze for the default or a longer time.
class NagScreen extends StatefulWidget {
  const NagScreen({super.key, required this.controller});

  final Controller controller;

  @override
  State<NagScreen> createState() => _NagScreenState();
}

class _NagScreenState extends State<NagScreen> {
  Future<void> _yes() async {
    final word = await widget.controller.inBed();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => WordScreen(word: word)),
    );
  }

  Future<void> _snooze(Duration length) async {
    await widget.controller.snoozeNag(length);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final standard = widget.controller.settings.nagSnooze;
    final line = widget.controller.nagLine;
    return NightFrame(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (line != null) ...[
            Text(
              line,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 32),
          ],
          Text(
            t.nagQuestion,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 48),
          FilledButton(onPressed: _yes, child: Text(t.nagYes)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _snooze(standard),
            child: Text(t.nagSnooze(standard.inMinutes)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (label, length) in [
                (t.nagSnooze30, const Duration(minutes: 30)),
                (t.nagSnooze60, const Duration(hours: 1)),
                (t.nagSnooze120, const Duration(hours: 2)),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextButton(
                      onPressed: () => _snooze(length),
                      child: Text(label),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The night's word, shown once.
class WordScreen extends StatelessWidget {
  const WordScreen({super.key, required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return NightFrame(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.wordIntro, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text(
            word,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(t.wordHint, textAlign: TextAlign.center),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.wordClose),
          ),
        ],
      ),
    );
  }
}

/// A ringing alarm: the quiz, or a plain dismiss button, plus Snooze.
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({
    super.key,
    required this.controller,
    required this.alarmId,
  });

  final Controller controller;
  final int alarmId;

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  RingScreen? _screen;
  Timer? _timeout;

  /// After a wrong pick: the snooze shown for a moment before closing.
  Duration? _wrong;

  Controller get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _start();
  }

  // Android reported the ring itself; the app only shows it.
  void _start() {
    _screen = _c.screenFor(widget.alarmId);
    _timeout = Timer(_c.settings.alarmTimeout, _timedOut);
  }

  Future<void> _timedOut() async {
    await _c.timeout(widget.alarmId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    _timeout?.cancel();
    await _c.snoozeAlarm(widget.alarmId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _dismiss() async {
    _timeout?.cancel();
    await _c.dismiss(widget.alarmId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _answer(String picked) async {
    _timeout?.cancel();
    final outcome = await _c.answer(widget.alarmId, picked);
    if (!mounted) return;
    if (outcome != null && !outcome.correct) {
      // Wrong: the alarm is snoozed; say so for a moment, then close.
      setState(() => _wrong = outcome.snooze);
      _timeout = Timer(wrongNoticeTime, () {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    if (outcome != null && outcome.failed) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SummaryScreen(outcome: outcome),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final screen = _screen;
    if (screen == null) return const NightFrame(child: SizedBox.shrink());
    final wrong = _wrong;
    if (wrong != null) return WrongNotice(snooze: wrong);
    return QuizPanel(
      screen: screen,
      topLabel: t.ringSnooze,
      onTop: _snooze,
      onConfirm: _answer,
      onDismiss: _dismiss,
    );
  }
}

/// The two-step quiz for half-asleep fingers: tall buttons with room
/// between them, a tap only marks a word, and OK sits far below, away from
/// the button on top (Snooze or Back). Without a word: a plain turn-off.
class QuizPanel extends StatefulWidget {
  const QuizPanel({
    super.key,
    required this.screen,
    required this.topLabel,
    required this.onTop,
    required this.onConfirm,
    required this.onDismiss,
  });

  final RingScreen screen;
  final String topLabel;
  final VoidCallback onTop;
  final ValueChanged<String> onConfirm;
  final VoidCallback onDismiss;

  @override
  State<QuizPanel> createState() => _QuizPanelState();
}

class _QuizPanelState extends State<QuizPanel> {
  /// The word marked so far; nothing counts until OK.
  String? _picked;

  @override
  void didUpdateWidget(QuizPanel old) {
    super.didUpdateWidget(old);
    if (!widget.screen.options.contains(_picked)) _picked = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final screen = widget.screen;
    const tall = Size.fromHeight(64);
    final picked = _picked;
    return NightFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: tall),
            onPressed: widget.onTop,
            child: Text(widget.topLabel),
          ),
          const Spacer(),
          if (screen.quiz) ...[
            Text(
              t.ringQuiz,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            for (final option in screen.options)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: option == picked
                    ? FilledButton.icon(
                        key: ValueKey('picked-$option'),
                        style: FilledButton.styleFrom(minimumSize: tall),
                        onPressed: () => setState(() => _picked = option),
                        icon: const Icon(Icons.check),
                        label: Text(option),
                      )
                    : FilledButton.tonal(
                        style: FilledButton.styleFrom(minimumSize: tall),
                        onPressed: () => setState(() => _picked = option),
                        child: Text(option),
                      ),
              ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: tall),
              onPressed: picked == null ? null : () => widget.onConfirm(picked),
              child: Text(t.ringConfirm),
            ),
          ] else ...[
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: tall),
              onPressed: widget.onDismiss,
              child: Text(t.ringDismiss),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }
}

/// "I'm awake": the night's quiz before the alarm, with Back instead of
/// Snooze. A wrong word says so and the quiz goes on without it; the right
/// one, or the plain turn-off, cancels the morning's wake-up alarms.
class AwakeScreen extends StatefulWidget {
  const AwakeScreen({super.key, required this.controller});

  final Controller controller;

  @override
  State<AwakeScreen> createState() => _AwakeScreenState();
}

class _AwakeScreenState extends State<AwakeScreen> {
  late RingScreen _screen = widget.controller.awakeScreen();
  var _wrong = false;
  Timer? _notice;

  Controller get _c => widget.controller;

  Future<void> _answer(String picked) async {
    final outcome = await _c.awakeAnswer(picked);
    if (!mounted) return;
    if (outcome != null && !outcome.correct) {
      setState(() {
        _wrong = true;
        _screen = _c.awakeScreen();
      });
      _notice = Timer(wrongNoticeTime, () {
        if (mounted) setState(() => _wrong = false);
      });
      return;
    }
    if (outcome != null && outcome.failed) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SummaryScreen(outcome: outcome),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _dismiss() async {
    await _c.awakeDismiss();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _notice?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_wrong) return const WrongNotice();
    return QuizPanel(
      screen: _screen,
      topLabel: AppLocalizations.of(context).awakeBack,
      onTop: () => Navigator.of(context).pop(),
      onConfirm: _answer,
      onDismiss: _dismiss,
    );
  }
}

/// How long "Not this one" stays before it closes by itself.
const wrongNoticeTime = Duration(seconds: 3);

/// "Not this one": the word stays hidden, the alarm comes back.
class WrongNotice extends StatelessWidget {
  const WrongNotice({super.key, this.snooze});

  /// When the alarm rings again; null when nothing rings ("I'm awake").
  final Duration? snooze;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final snooze = this.snooze;
    return NightFrame(
      child: Center(
        child: Text(
          snooze == null ? t.notThisOne : t.ringWrong(snooze.inMinutes),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: Colors.white70),
        ),
      ),
    );
  }
}

/// The page after the right word on a night with wrong picks.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.outcome});

  final QuizOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final stats = outcome.stats!;
    final text = Theme.of(context).textTheme;
    return NightFrame(
      child: ListView(
        children: [
          const SizedBox(height: 24),
          Text(
            t.summaryTitle(outcome.wrongPicks + 1),
            style: text.headlineMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Text(t.failureWord),
          Text(
            outcome.word!,
            style: text.displaySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(t.failureStreak(stats.streak)),
          Text(t.failureTotals(stats.successes, stats.failures)),
          const SizedBox(height: 24),
          Text(t.failureStrip),
          const SizedBox(height: 8),
          ResultStrip(nights: stats.strip),
          if (stats.showHint) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(t.failureHint),
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.failureClose),
          ),
        ],
      ),
    );
  }
}

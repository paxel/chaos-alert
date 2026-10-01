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
    return NightFrame(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
    if (outcome == null || outcome.correct) {
      Navigator.of(context).pop();
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => FailureScreen(outcome: outcome)),
    );
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
    return NightFrame(
      child: screen == null
          ? const SizedBox.shrink()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (screen.quiz) ...[
                  Text(
                    t.ringQuiz,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  for (final option in screen.options)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: FilledButton.tonal(
                        onPressed: () => _answer(option),
                        child: Text(option),
                      ),
                    ),
                ] else
                  FilledButton(onPressed: _dismiss, child: Text(t.ringDismiss)),
                const SizedBox(height: 32),
                OutlinedButton(onPressed: _snooze, child: Text(t.ringSnooze)),
              ],
            ),
    );
  }
}

/// The page after a wrong pick.
class FailureScreen extends StatelessWidget {
  const FailureScreen({super.key, required this.outcome});

  final QuizOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final stats = outcome.stats;
    final text = Theme.of(context).textTheme;
    return NightFrame(
      child: ListView(
        children: [
          const SizedBox(height: 24),
          Text(
            t.failureTitle,
            style: text.headlineMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Text(t.failureWord),
          Text(
            outcome.word,
            style: text.displaySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(t.failureStreak(stats.streak)),
          Text(t.failureTotals(stats.successes, stats.failures)),
          const SizedBox(height: 24),
          Text(t.failureStrip),
          const SizedBox(height: 8),
          ResultStrip(results: stats.strip),
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

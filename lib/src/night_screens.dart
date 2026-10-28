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

/// The bedtime nag: Yes, or Snooze for the default or a longer time. Once
/// in bed, it asks for the word instead.
class NagScreen extends StatefulWidget {
  const NagScreen({super.key, required this.controller});

  final Controller controller;

  @override
  State<NagScreen> createState() => _NagScreenState();
}

class _NagScreenState extends State<NagScreen> {
  Future<void> _yes() async {
    final word = await widget.controller.wordNow();
    if (!mounted) return;
    // Outside bedtime nothing was recorded; the nag just closes.
    if (word == null) return Navigator.of(context).pop();
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
    final inBed = widget.controller.canFetchWord;
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
            inBed ? t.nagWordQuestion : t.nagQuestion,
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

  /// Set once a button was pressed here; until then a snooze can only
  /// come from the ring's notification.
  var _acted = false;

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
    _c.addListener(_snoozedElsewhere);
  }

  /// Snoozed from the notification: the screen closes, and its timeout
  /// must not undo the snooze.
  void _snoozedElsewhere() {
    if (_acted || !_c.alarmSnoozes.containsKey(widget.alarmId)) return;
    _acted = true;
    _timeout?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _timedOut() async {
    // An answer is under way; the ring's own timeout keeps running natively.
    if (_acted) return;
    await _c.timeout(widget.alarmId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    _acted = true;
    _timeout?.cancel();
    await _c.snoozeAlarm(widget.alarmId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _dismiss() async {
    _acted = true;
    _timeout?.cancel();
    await _c.dismiss(widget.alarmId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _answer(String picked) async {
    _acted = true;
    final hidden = _screen?.hidesWord ?? false;
    final outcome = await _c.answer(widget.alarmId, picked);
    if (!mounted) return;
    if (outcome != null && outcome.next) {
      // The next letter quiz round; the alarm and its timeout go on.
      _acted = false;
      setState(() => _screen = _c.screenFor(widget.alarmId));
      return;
    }
    _timeout?.cancel();
    if (outcome != null && !outcome.correct) {
      // Wrong: the alarm is snoozed; say so for a moment, then close.
      setState(() => _wrong = outcome.snooze);
      _timeout = Timer(wrongNoticeTime, () {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    if (await showOutcome(context, outcome, wordHidden: hidden)) return;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _c.removeListener(_snoozedElsewhere);
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
/// the button on top (Snooze or Back). First letters come as big tiles two
/// by two that answer on the tap itself; broken teeth words as a row of
/// letter tiles each. Without a word: a plain turn-off.
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
    String label(String option) =>
        screen.letters ? t.quizLetters(option) : option;
    Widget content(String option) => switch (screen.shown) {
      final shown? => BrokenTeeth(word: option, shown: shown),
      null => Text(label(option)),
    };
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
              screen.letters ? t.ringLetters : t.ringQuiz,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (screen.letters)
              // A few letters each: big tiles two by two, safe enough to
              // answer with the tap itself.
              for (var i = 0; i < screen.options.length; i += 2)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      for (final option in screen.options.skip(i).take(2))
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _letterTile(option, label(option)),
                          ),
                        ),
                    ],
                  ),
                )
            else
              for (final option in screen.options)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: option == picked
                      ? FilledButton.icon(
                          key: ValueKey('picked-$option'),
                          style: FilledButton.styleFrom(minimumSize: tall),
                          onPressed: () => setState(() => _picked = option),
                          icon: const Icon(Icons.check),
                          label: content(option),
                        )
                      : FilledButton.tonal(
                          style: FilledButton.styleFrom(minimumSize: tall),
                          onPressed: () => setState(() => _picked = option),
                          child: content(option),
                        ),
                ),
            const Spacer(),
            if (!screen.letters)
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: tall),
                onPressed: picked == null
                    ? null
                    : () => widget.onConfirm(picked),
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

  Widget _letterTile(String option, String text) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(120),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: const TextStyle(fontSize: 56),
    );
    // Shrinks only when the letters would not fit a narrow tile.
    return FilledButton.tonal(
      style: style,
      onPressed: () => widget.onConfirm(option),
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(text)),
    );
  }
}

/// One broken teeth quiz option: a tile per letter, the [shown] ones with
/// their letter, the others empty, so the gaps line up across the options.
class BrokenTeeth extends StatelessWidget {
  const BrokenTeeth({super.key, required this.word, required this.shown});

  final String word;
  final List<int> shown;

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color ?? Colors.white;
    // Shrinks only when a long word would not fit the button.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < word.length; i++)
            Container(
              width: 28,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: shown.contains(i) ? color.withValues(alpha: 0.15) : null,
                border: Border.all(color: color.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: shown.contains(i)
                  ? Text(word[i], style: const TextStyle(fontSize: 22))
                  : null,
            ),
        ],
      ),
    );
  }
}

/// "I'm awake": the night's quiz before the alarm, with Back instead of
/// Snooze. A wrong word says so and the quiz goes on without it; the right
/// one marks awake, and the alarm then rings with a plain dismiss. The
/// plain turn-off without a word cancels the morning's wake-up alarms.
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
    final hidden = _screen.hidesWord;
    final outcome = await _c.awakeAnswer(picked);
    if (!mounted) return;
    if (outcome != null && outcome.next) {
      setState(() => _screen = _c.awakeScreen());
      return;
    }
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
    if (await showOutcome(context, outcome, wordHidden: hidden)) return;
    if (!mounted) return;
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

/// After the right answer: the summary on a night with wrong picks, else
/// on the letter quiz and the broken teeth quiz the word, which was never
/// shown whole. Returns whether a page replaced the quiz.
Future<bool> showOutcome(
  BuildContext context,
  QuizOutcome? outcome, {
  required bool wordHidden,
}) async {
  if (outcome == null || !outcome.correct) return false;
  final Widget page;
  if (outcome.failed) {
    page = SummaryScreen(outcome: outcome);
  } else if (wordHidden) {
    page = RevealScreen(word: outcome.word!);
  } else {
    return false;
  }
  await Navigator.of(context)
      .pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  return true;
}

/// The page after a quiz that hid the word, without wrong picks: the whole
/// word.
class RevealScreen extends StatelessWidget {
  const RevealScreen({super.key, required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return NightFrame(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.failureWord, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text(
            word,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.failureClose),
          ),
        ],
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

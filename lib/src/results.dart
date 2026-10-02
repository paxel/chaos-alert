import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The colour of a night, shared by the strip and the timeline: green,
/// three shades of red for one, two and three wrong picks, grey without a
/// word, amber when missed.
Color nightColor(NightRecord night) => switch (night.result) {
  NightResult.success => const Color(0xFF4CAF50),
  // Failures from 0.1.0 carry no count; they were one wrong pick.
  NightResult.failure => switch (night.wrongPicks) {
    <= 1 => const Color(0xFFEF9A9A),
    2 => const Color(0xFFE53935),
    _ => const Color(0xFFB71C1C),
  },
  NightResult.noWord => const Color(0xFF78909C),
  NightResult.missed => const Color(0xFFFFB74D),
};

String nightLabel(AppLocalizations t, NightRecord night) =>
    switch (night.result) {
      NightResult.success => t.resultSuccess,
      NightResult.failure => t.resultWrongPicks(
        night.wrongPicks < 1 ? 1 : night.wrongPicks,
      ),
      NightResult.noWord => t.resultNoWord,
      NightResult.missed => t.resultMissed,
    };

/// One small square per night, oldest first.
class ResultStrip extends StatelessWidget {
  const ResultStrip({super.key, required this.nights});

  final List<NightRecord> nights;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (final n in nights)
          Tooltip(
            message: nightLabel(t, n),
            child: Container(
              key: ValueKey('strip-${n.result.name}-${n.wrongPicks}'),
              width: 9,
              height: 18,
              color: nightColor(n),
            ),
          ),
      ],
    );
  }
}

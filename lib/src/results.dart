import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The colour of a night's result, shared by the strip and the timeline.
Color resultColor(NightResult result) => switch (result) {
  NightResult.success => const Color(0xFF4CAF50),
  NightResult.failure => const Color(0xFFE57373),
  NightResult.noWord => const Color(0xFF78909C),
  NightResult.missed => const Color(0xFFFFB74D),
};

String resultLabel(AppLocalizations t, NightResult result) => switch (result) {
  NightResult.success => t.resultSuccess,
  NightResult.failure => t.resultFailure,
  NightResult.noWord => t.resultNoWord,
  NightResult.missed => t.resultMissed,
};

/// One small square per night, oldest first.
class ResultStrip extends StatelessWidget {
  const ResultStrip({super.key, required this.results});

  final List<NightResult> results;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (final r in results)
          Tooltip(
            message: resultLabel(t, r),
            child: Container(
              key: ValueKey('strip-${r.name}'),
              width: 9,
              height: 18,
              color: resultColor(r),
            ),
          ),
      ],
    );
  }
}

import 'package:chaos_core/chaos_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'controller.dart';

/// The planned vacations, each a range of mornings.
class VacationScreen extends StatelessWidget {
  const VacationScreen({super.key, required this.controller});

  final Controller controller;

  Future<void> _add(BuildContext context) async {
    final now = controller.clock();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(today.year + 2, today.month, today.day),
    );
    if (range == null) return;
    await controller.saveVacation(
      Vacation(id: 0, from: range.start, to: range.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final format = DateFormat.yMMMEd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.vacationsTitle)),
      floatingActionButton: FloatingActionButton(
        tooltip: t.vacationAdd,
        onPressed: () => _add(context),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final vacations = controller.vacations;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(t.vacationsHint),
              ),
              if (vacations.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t.vacationsEmpty),
                ),
              for (final v in vacations)
                ListTile(
                  leading: const Icon(Icons.beach_access),
                  title: Text(
                    '${format.format(v.from)} – ${format.format(v.to)}',
                  ),
                  trailing: IconButton(
                    tooltip: t.vacationDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => controller.deleteVacation(v.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

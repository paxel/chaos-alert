// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'chaos-alert';

  @override
  String get nagQuestion => 'Are you in bed?';

  @override
  String get nagYes => 'Yes';

  @override
  String nagSnooze(int minutes) {
    return 'Snooze $minutes min';
  }

  @override
  String get nagSnooze30 => '30 min';

  @override
  String get nagSnooze60 => '1 h';

  @override
  String get nagSnooze120 => '2 h';

  @override
  String get wordIntro => 'Remember this word:';

  @override
  String get wordHint =>
      'It is shown only once. Tomorrow\'s alarm asks for it.';

  @override
  String get wordClose => 'Good night';

  @override
  String get ringQuiz => 'Which word did you see last night?';

  @override
  String get ringDismiss => 'Turn off';

  @override
  String get ringSnooze => 'Snooze';

  @override
  String get failureTitle => 'Not this time';

  @override
  String get failureWord => 'The word was';

  @override
  String failureStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count misses in a row',
      one: '1 miss in a row',
    );
    return '$_temp0';
  }

  @override
  String failureTotals(int successes, int failures) {
    return '$successes right, $failures wrong in total';
  }

  @override
  String get failureStrip => 'Last 30 nights';

  @override
  String get failureHint =>
      'You\'ve missed the word 5 times in a row. Occasional forgetting is normal, and poor sleep alone can cause this. If it worries you, consider talking to a doctor.';

  @override
  String get failureClose => 'Close';

  @override
  String get resultSuccess => 'Right';

  @override
  String get resultFailure => 'Wrong';

  @override
  String get resultNoWord => 'No word';

  @override
  String get resultMissed => 'Missed';

  @override
  String get alarmsTitle => 'Alarms';

  @override
  String get alarmsEmpty => 'No alarms yet.';

  @override
  String get alarmAdd => 'Add alarm';

  @override
  String get alarmEditTitle => 'Alarm';

  @override
  String get alarmRepeating => 'Repeating';

  @override
  String get alarmOnce => 'Once';

  @override
  String get alarmDate => 'Date';

  @override
  String get alarmWakeUp => 'Wake-up alarm';

  @override
  String get alarmWakeUpHint => 'Sets the bedtime and asks for the word';

  @override
  String get alarmSave => 'Save';

  @override
  String get alarmDelete => 'Delete';

  @override
  String get alarmNoDays => 'Pick at least one day';

  @override
  String get alarmNever => 'Never';

  @override
  String get alarmReminder => 'Reminder';

  @override
  String get vacationsTitle => 'Vacations';

  @override
  String get vacationsEmpty => 'No vacations planned.';

  @override
  String get vacationsHint =>
      'Repeating alarms and the bedtime nag are off on these mornings. One-time alarms still ring.';

  @override
  String get vacationAdd => 'Add vacation';

  @override
  String get vacationDelete => 'Delete vacation';
}

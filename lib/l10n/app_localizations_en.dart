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
  String get nagWordQuestion => 'Want the word now?';

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
  String get ringLetters => 'How does last night\'s word begin?';

  @override
  String quizLetters(String letters) {
    return '$letters…';
  }

  @override
  String get ringDismiss => 'Turn off';

  @override
  String get ringSnooze => 'Snooze';

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

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSleepLength => 'Sleep length';

  @override
  String get settingsNagSnooze => 'Bedtime snooze';

  @override
  String get settingsAlarmSnooze => 'Alarm snooze';

  @override
  String get settingsAlarmTimeout => 'Alarm stops after';

  @override
  String get settingsLowVolume => 'Start volume';

  @override
  String get settingsMediumVolume => 'Volume after 10 s';

  @override
  String get settingsChime => 'Chime at bedtime';

  @override
  String get settingsChimeHint => 'One soft sound with the bedtime popup';

  @override
  String get settingsQuiz => 'Quiz';

  @override
  String get settingsQuizWord => 'Whole word';

  @override
  String get settingsQuizWordHint => 'Pick the word from four. The easiest.';

  @override
  String get settingsQuizLetters => 'First letters';

  @override
  String get settingsQuizLettersHint =>
      'Pick how the word begins, one letter more each round.';

  @override
  String get settingsQuizBrokenTeeth => 'Broken teeth';

  @override
  String get settingsQuizBrokenTeethHint =>
      'Four words with the same letters missing. The hardest.';

  @override
  String get settingsMusic => 'Songs are left out';

  @override
  String get settingsMusicHint =>
      'Allow access to music so alarms can play songs too.';

  @override
  String get settingsMusicGrant => 'Allow';

  @override
  String get settingsSounds => 'Sounds';

  @override
  String get settingsSoundsHint => 'Where the alarm sounds come from';

  @override
  String get soundsAllOff =>
      'Every source is off. Only the phone\'s default alarm sound will ring.';

  @override
  String get soundsAlarms => 'Alarm sounds';

  @override
  String get soundsNotifications => 'Notification sounds';

  @override
  String get soundsSongs => 'Songs';

  @override
  String get soundsSongsHint =>
      'Music on the phone, without audiobooks, podcasts and anything over 20 minutes';

  @override
  String get soundsGenerated => 'Generated sounds';

  @override
  String get soundsGeneratedHint =>
      'Random mixes of instruments, new for every alarm';

  @override
  String get soundsFolders => 'Folders';

  @override
  String get soundsAddFolder => 'Add folder';

  @override
  String soundsFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sounds',
      one: '1 sound',
    );
    return '$_temp0';
  }

  @override
  String get soundsFolderEmpty => 'No sounds found';

  @override
  String get soundsFolderLost => 'Access lost';

  @override
  String get soundsFolderRepick => 'Pick again';

  @override
  String get soundsFolderRemove => 'Remove folder';

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String durationHm(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationM(int minutes) {
    return '$minutes min';
  }

  @override
  String percent(int value) {
    return '$value %';
  }

  @override
  String get timelineTitle => 'Time in bed';

  @override
  String get timelineWeek => 'Week';

  @override
  String get timelineMonth => 'Month';

  @override
  String get timelinePrevious => 'Earlier';

  @override
  String get timelineNext => 'Later';

  @override
  String timelineAverageInBed(String value) {
    return 'Average in bed: $value';
  }

  @override
  String timelineAverageAsleep(String value) {
    return 'Average asleep: $value';
  }

  @override
  String timelineAverageBedtime(String value) {
    return 'Average bedtime: $value';
  }

  @override
  String get timelineEmpty => 'No nights in this period.';

  @override
  String get homeInBed => 'I\'m in bed';

  @override
  String get homeWordNow => 'Show the word';

  @override
  String homeBedtime(String time) {
    return 'Bedtime $time';
  }

  @override
  String homeNextAlarm(String time) {
    return 'Next alarm $time';
  }

  @override
  String get homeNoAlarm => 'No alarm set';

  @override
  String get homeBanner => 'Alarms may not ring: a permission is missing.';

  @override
  String get homeBannerFix => 'Fix';

  @override
  String get setupTitle => 'Setup';

  @override
  String setupStep(int step, int count) {
    return 'Step $step of $count';
  }

  @override
  String get setupAllow => 'Allow';

  @override
  String get setupNext => 'Next';

  @override
  String get setupDone => 'Done';

  @override
  String get setupGranted => 'Allowed';

  @override
  String get permExactAlarms => 'Exact alarms';

  @override
  String get permExactAlarmsWhy =>
      'Lets the alarm and the bedtime popup come at the exact minute.';

  @override
  String get permNotifications => 'Notifications';

  @override
  String get permNotificationsWhy =>
      'Android shows a ringing alarm and the bedtime popup as a notification.';

  @override
  String get permFullScreen => 'Full-screen popups';

  @override
  String get permFullScreenWhy =>
      'Lets the alarm and the bedtime popup cover the lock screen.';

  @override
  String get permBattery => 'No battery optimisation';

  @override
  String get permBatteryWhy =>
      'Keeps Android from delaying alarms to save battery.';

  @override
  String get permMusic => 'Music';

  @override
  String get permMusicWhy =>
      'Lets alarms play songs from your music library. Without it, only the phone\'s own sounds play.';

  @override
  String get aboutAndFeedback => 'About & feedback';

  @override
  String get about => 'About';

  @override
  String get eventLog => 'Event log';

  @override
  String get eventLogSubtitle =>
      'What the app did in the last 7 days, to copy into a bug report';

  @override
  String get eventLogCopy => 'Copy';

  @override
  String get eventLogCopied => 'Event log copied';

  @override
  String get eventLogEmpty => 'Nothing logged yet';

  @override
  String get aboutTagline =>
      'Nags you to bed, gives you a word to remember and wakes you with a sound you never know. Your data stays on your phone — no server, no account.';

  @override
  String get sourceCode => 'Source code';

  @override
  String get reportProblemOrIdea => 'Report a problem or idea';

  @override
  String get githubIssues => 'GitHub issues';

  @override
  String get writeTheDeveloper => 'Write the developer';

  @override
  String get buyCoffee => 'Buy the developer a coffee';

  @override
  String get coffeeSubtitle =>
      'The app stays free. Even if I don\'t get a coffee :)';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String versionLabel(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get dangerButton => 'DON\'T PRESS.\nDANGER';

  @override
  String get dangerThanks => 'Thank you for using chaos-alert!';

  @override
  String get doneLabel => 'Done';

  @override
  String get ringConfirm => 'OK';

  @override
  String ringWrong(int minutes) {
    return 'Not this one.\nThe alarm rings again in $minutes min.';
  }

  @override
  String summaryTitle(int tries) {
    return 'Found on try $tries';
  }

  @override
  String resultWrongPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong $count times',
      one: 'Wrong once',
    );
    return '$_temp0';
  }

  @override
  String get hintDismiss => 'OK';

  @override
  String get notThisOne => 'Not this one.';

  @override
  String get awakeBack => 'Back';

  @override
  String get homeAwake => 'I\'m awake';

  @override
  String get homeUp => 'I\'m up';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'chaos-alert'**
  String get appTitle;

  /// No description provided for @nagQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you in bed?'**
  String get nagQuestion;

  /// No description provided for @nagYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get nagYes;

  /// No description provided for @nagSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze {minutes} min'**
  String nagSnooze(int minutes);

  /// No description provided for @nagSnooze30.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get nagSnooze30;

  /// No description provided for @nagSnooze60.
  ///
  /// In en, this message translates to:
  /// **'1 h'**
  String get nagSnooze60;

  /// No description provided for @nagSnooze120.
  ///
  /// In en, this message translates to:
  /// **'2 h'**
  String get nagSnooze120;

  /// No description provided for @wordIntro.
  ///
  /// In en, this message translates to:
  /// **'Remember this word:'**
  String get wordIntro;

  /// No description provided for @wordHint.
  ///
  /// In en, this message translates to:
  /// **'It is shown only once. Tomorrow\'s alarm asks for it.'**
  String get wordHint;

  /// No description provided for @wordClose.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get wordClose;

  /// No description provided for @ringQuiz.
  ///
  /// In en, this message translates to:
  /// **'Which word did you see last night?'**
  String get ringQuiz;

  /// No description provided for @ringDismiss.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get ringDismiss;

  /// No description provided for @ringSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get ringSnooze;

  /// No description provided for @failureTitle.
  ///
  /// In en, this message translates to:
  /// **'Not this time'**
  String get failureTitle;

  /// No description provided for @failureWord.
  ///
  /// In en, this message translates to:
  /// **'The word was'**
  String get failureWord;

  /// No description provided for @failureStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 miss in a row} other{{count} misses in a row}}'**
  String failureStreak(int count);

  /// No description provided for @failureTotals.
  ///
  /// In en, this message translates to:
  /// **'{successes} right, {failures} wrong in total'**
  String failureTotals(int successes, int failures);

  /// No description provided for @failureStrip.
  ///
  /// In en, this message translates to:
  /// **'Last 30 nights'**
  String get failureStrip;

  /// No description provided for @failureHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ve missed the word 5 times in a row. Occasional forgetting is normal, and poor sleep alone can cause this. If it worries you, consider talking to a doctor.'**
  String get failureHint;

  /// No description provided for @failureClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get failureClose;

  /// No description provided for @resultSuccess.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get resultSuccess;

  /// No description provided for @resultFailure.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get resultFailure;

  /// No description provided for @resultNoWord.
  ///
  /// In en, this message translates to:
  /// **'No word'**
  String get resultNoWord;

  /// No description provided for @resultMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get resultMissed;

  /// No description provided for @alarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarmsTitle;

  /// No description provided for @alarmsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alarms yet.'**
  String get alarmsEmpty;

  /// No description provided for @alarmAdd.
  ///
  /// In en, this message translates to:
  /// **'Add alarm'**
  String get alarmAdd;

  /// No description provided for @alarmEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarmEditTitle;

  /// No description provided for @alarmRepeating.
  ///
  /// In en, this message translates to:
  /// **'Repeating'**
  String get alarmRepeating;

  /// No description provided for @alarmOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get alarmOnce;

  /// No description provided for @alarmDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get alarmDate;

  /// No description provided for @alarmWakeUp.
  ///
  /// In en, this message translates to:
  /// **'Wake-up alarm'**
  String get alarmWakeUp;

  /// No description provided for @alarmWakeUpHint.
  ///
  /// In en, this message translates to:
  /// **'Sets the bedtime and asks for the word'**
  String get alarmWakeUpHint;

  /// No description provided for @alarmSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get alarmSave;

  /// No description provided for @alarmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get alarmDelete;

  /// No description provided for @alarmNoDays.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day'**
  String get alarmNoDays;

  /// No description provided for @alarmNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get alarmNever;

  /// No description provided for @alarmReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get alarmReminder;

  /// No description provided for @vacationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vacations'**
  String get vacationsTitle;

  /// No description provided for @vacationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vacations planned.'**
  String get vacationsEmpty;

  /// No description provided for @vacationsHint.
  ///
  /// In en, this message translates to:
  /// **'Repeating alarms and the bedtime nag are off on these mornings. One-time alarms still ring.'**
  String get vacationsHint;

  /// No description provided for @vacationAdd.
  ///
  /// In en, this message translates to:
  /// **'Add vacation'**
  String get vacationAdd;

  /// No description provided for @vacationDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete vacation'**
  String get vacationDelete;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSleepLength.
  ///
  /// In en, this message translates to:
  /// **'Sleep length'**
  String get settingsSleepLength;

  /// No description provided for @settingsNagSnooze.
  ///
  /// In en, this message translates to:
  /// **'Bedtime snooze'**
  String get settingsNagSnooze;

  /// No description provided for @settingsAlarmSnooze.
  ///
  /// In en, this message translates to:
  /// **'Alarm snooze'**
  String get settingsAlarmSnooze;

  /// No description provided for @settingsAlarmTimeout.
  ///
  /// In en, this message translates to:
  /// **'Alarm stops after'**
  String get settingsAlarmTimeout;

  /// No description provided for @settingsLowVolume.
  ///
  /// In en, this message translates to:
  /// **'Start volume'**
  String get settingsLowVolume;

  /// No description provided for @settingsMediumVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume after 10 s'**
  String get settingsMediumVolume;

  /// No description provided for @settingsChime.
  ///
  /// In en, this message translates to:
  /// **'Chime at bedtime'**
  String get settingsChime;

  /// No description provided for @settingsChimeHint.
  ///
  /// In en, this message translates to:
  /// **'One soft sound with the bedtime popup'**
  String get settingsChimeHint;

  /// No description provided for @settingsMusic.
  ///
  /// In en, this message translates to:
  /// **'Songs are left out'**
  String get settingsMusic;

  /// No description provided for @settingsMusicHint.
  ///
  /// In en, this message translates to:
  /// **'Allow access to music so alarms can play songs too.'**
  String get settingsMusicHint;

  /// No description provided for @settingsMusicGrant.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get settingsMusicGrant;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @durationHm.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHm(int hours, int minutes);

  /// No description provided for @durationM.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationM(int minutes);

  /// No description provided for @percent.
  ///
  /// In en, this message translates to:
  /// **'{value} %'**
  String percent(int value);

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Time in bed'**
  String get timelineTitle;

  /// No description provided for @timelineWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get timelineWeek;

  /// No description provided for @timelineMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get timelineMonth;

  /// No description provided for @timelinePrevious.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get timelinePrevious;

  /// No description provided for @timelineNext.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get timelineNext;

  /// No description provided for @timelineAverageInBed.
  ///
  /// In en, this message translates to:
  /// **'Average in bed: {value}'**
  String timelineAverageInBed(String value);

  /// No description provided for @timelineAverageBedtime.
  ///
  /// In en, this message translates to:
  /// **'Average bedtime: {value}'**
  String timelineAverageBedtime(String value);

  /// No description provided for @timelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No nights in this period.'**
  String get timelineEmpty;

  /// No description provided for @homeInBed.
  ///
  /// In en, this message translates to:
  /// **'I\'m in bed'**
  String get homeInBed;

  /// No description provided for @homeBedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime {time}'**
  String homeBedtime(String time);

  /// No description provided for @homeNextAlarm.
  ///
  /// In en, this message translates to:
  /// **'Next alarm {time}'**
  String homeNextAlarm(String time);

  /// No description provided for @homeNoAlarm.
  ///
  /// In en, this message translates to:
  /// **'No alarm set'**
  String get homeNoAlarm;

  /// No description provided for @homeBanner.
  ///
  /// In en, this message translates to:
  /// **'Alarms may not ring: a permission is missing.'**
  String get homeBanner;

  /// No description provided for @homeBannerFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get homeBannerFix;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setupTitle;

  /// No description provided for @setupStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {count}'**
  String setupStep(int step, int count);

  /// No description provided for @setupAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get setupAllow;

  /// No description provided for @setupNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get setupNext;

  /// No description provided for @setupDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get setupDone;

  /// No description provided for @setupGranted.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get setupGranted;

  /// No description provided for @permExactAlarms.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms'**
  String get permExactAlarms;

  /// No description provided for @permExactAlarmsWhy.
  ///
  /// In en, this message translates to:
  /// **'Lets the alarm and the bedtime popup come at the exact minute.'**
  String get permExactAlarmsWhy;

  /// No description provided for @permNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permNotifications;

  /// No description provided for @permNotificationsWhy.
  ///
  /// In en, this message translates to:
  /// **'Android shows a ringing alarm and the bedtime popup as a notification.'**
  String get permNotificationsWhy;

  /// No description provided for @permFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full-screen popups'**
  String get permFullScreen;

  /// No description provided for @permFullScreenWhy.
  ///
  /// In en, this message translates to:
  /// **'Lets the alarm and the bedtime popup cover the lock screen.'**
  String get permFullScreenWhy;

  /// No description provided for @permBattery.
  ///
  /// In en, this message translates to:
  /// **'No battery optimisation'**
  String get permBattery;

  /// No description provided for @permBatteryWhy.
  ///
  /// In en, this message translates to:
  /// **'Keeps Android from delaying alarms to save battery.'**
  String get permBatteryWhy;

  /// No description provided for @permMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get permMusic;

  /// No description provided for @permMusicWhy.
  ///
  /// In en, this message translates to:
  /// **'Lets alarms play songs from your music library. Without it, only the phone\'s own sounds play.'**
  String get permMusicWhy;

  /// No description provided for @aboutAndFeedback.
  ///
  /// In en, this message translates to:
  /// **'About & feedback'**
  String get aboutAndFeedback;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Nags you to bed, gives you a word to remember and wakes you with a sound you never know. Your data stays on your phone — no server, no account.'**
  String get aboutTagline;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @reportProblemOrIdea.
  ///
  /// In en, this message translates to:
  /// **'Report a problem or idea'**
  String get reportProblemOrIdea;

  /// No description provided for @githubIssues.
  ///
  /// In en, this message translates to:
  /// **'GitHub issues'**
  String get githubIssues;

  /// No description provided for @writeTheDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Write the developer'**
  String get writeTheDeveloper;

  /// No description provided for @buyCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy the developer a coffee'**
  String get buyCoffee;

  /// No description provided for @coffeeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The app stays free. Even if I don\'t get a coffee :)'**
  String get coffeeSubtitle;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String versionLabel(String version, String build);

  /// No description provided for @dangerButton.
  ///
  /// In en, this message translates to:
  /// **'DON\'T PRESS.\nDANGER'**
  String get dangerButton;

  /// No description provided for @dangerThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using chaos-alert!'**
  String get dangerThanks;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

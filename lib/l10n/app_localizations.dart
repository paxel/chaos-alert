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

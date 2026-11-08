# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.8.0]

### Added
- "Show the word" on the main screen once you are in bed, so the word comes when you are ready to sleep.
- "I'm up" on the main screen after the early quiz: it ends the night and turns off the rest of that morning's wake-up alarms.
- The timeline tells time in bed apart from supposed sleep: the time lying awake at either end is drawn in a dimmer colour, and a new line shows the average asleep.
- A "Type it" quiz, the new hardest: type the word in; up to two typos pass, with no second try.
- A "Words" setting: Simple words that are easier to picture, or the less common ones as before.
- With "Display over other apps" allowed, a ringing alarm opens its quiz by itself while you use the phone. Setup asks for it, on a phone set up before once after the update; without it the alarm still rings as a notification.

### Changed
- "I'm in bed" shows up six hours before bedtime and no longer shows the word; the bedtime nag still comes and asks "Want the word now?".
- "I'm awake" shows up six hours before the alarm. The right word no longer turns the alarm off: it still rings, with a plain turn-off that marks when you got up.
- "I'm awake" stays on the main screen while the alarm is snoozed; the right word there ends the alarm at once.
- A wrong pick on the ringing alarm no longer snoozes it: the quiz goes on without that option while the alarm keeps ringing.

### Fixed
- Opening the app while an alarm rings, from its notification or its icon, shows the alarm's quiz at once instead of the main page.

---

Historical changes have been moved to [OLDER_CHANGES.md](OLDER_CHANGES.md).

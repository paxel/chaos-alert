# Older changes

Versions before the current one.

## [0.4.0] - 2026-10-05

### Added
- The ringing alarm's notification has a Snooze button, so the alarm can be silenced without the app screen.
- An event log under About lists what the app and Android did in the last 7 days, with a Copy button for bug reports.

### Fixed
- Snooze stops the alarm sound first, before anything else happens.
- "I'm in bed", a nag's Yes or a late nag after the night's morning started no longer start the next night early and hand out its word.

## [0.3.0] - 2026-10-04

### Added
- The bedtime nag now argues before it asks: each popup brings one of 300 lines about sleep, dreams, puffy eyes, the Matrix and fairy tales, none repeating until all were shown.
- F-Droid keeps the three versions before the current one in its archive, so you can go back after a bad update.

### Changed
- F-Droid now ships the 64-bit build only; the 32-bit APK stays available on the GitHub release page.

### Fixed
- The app's icon and feature graphic no longer go missing in F-Droid after a cat(a)log release.

## [0.2.0] - 2026-10-02

### Added
- "I'm awake" button on the main screen and a silent notification in the hour before the first wake-up alarm; the right word turns off that morning's wake-up alarms.

### Changed
- A wrong word now snoozes the alarm and drops out of the next try; only the right word turns the alarm off.
- Nights with wrong picks show in three shades of red, and the page after the right word shows how many tries it took; if the fifth miss in a row ends without an answer, the hint appears on the main screen.
- The quiz marks a word with a tap and answers with a separate OK button; the buttons are taller and further apart.
- The time-in-bed view fits its hours to the nights shown, so daytime sleep fits too.

## [0.1.0] - 2026-10-01

### Added
- Bedtime nag: a full-screen popup at the earliest wake-up alarm minus your sleep length, with Yes, a default snooze and 30 min, 1 h or 2 h, plus an optional soft chime.
- "I'm in bed" button on the main screen during the three hours before bedtime.
- A less common English word to remember, shown once when you go to bed.
- Alarms that play a random alarm sound, notification sound or song, low at first and louder after 10 seconds, with a new sound after every snooze.
- Turning the alarm off by picking last night's word from four; a wrong pick shows the right word, your streak, totals, the last 30 nights and, after five misses in a row, a hint.
- Repeating and one-time alarms with a wake-up switch; alarms can be switched off, edited and deleted.
- Vacations as date ranges that silence repeating alarms and the bedtime nag.
- Week and month timeline of time in bed with average time in bed and average bedtime.
- Settings for sleep length, snooze lengths, alarm timeout, both volume levels and the chime.
- A first-start setup that asks for each permission, and a banner when one goes missing.
- App icon: a black chaos star with a red alarm clock.
- About page with the version, source code, feedback links and open-source licenses.

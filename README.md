<p align="center">
  <img src="assets/icon/icon.png" width="128" alt="chaos-alert icon"/>
</p>

<h1 align="center">chaos-alert</h1>

<p align="center">
  <a href="https://github.com/paxel/chaos-alert/actions/workflows/ci.yml"><img src="https://github.com/paxel/chaos-alert/actions/workflows/ci.yml/badge.svg?branch=summer" alt="CI"/></a>
  <a href="https://github.com/paxel/chaos-alert/releases/latest"><img src="https://img.shields.io/github/v/release/paxel/chaos-alert" alt="Release"/></a>
  <a href="#get-it"><img src="https://img.shields.io/badge/F--Droid-paxel.github.io-1976D2?logo=f-droid" alt="F-Droid repository"/></a>
  <a href="android/app/build.gradle.kts"><img src="https://img.shields.io/badge/Android-7.0%2B-3DDC84?logo=android" alt="Android 7.0+"/></a>
  <a href="LICENSE-MIT"><img src="https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue" alt="License"/></a>
</p>

<p align="center">
  <b>Goes to bed with you. Wakes you with chaos.</b><br/>
  Android only. Everything stays on your phone — no account, no internet, no tracking. Free.
</p>

---

Your alarm always sounds the same, so you sleep right through it. And
"just ten more minutes" on the sofa turns into midnight again.

chaos-alert nags you to bed when it's time, gives you one word to remember,
and wakes you with a sound you have never heard coming. To turn the alarm
off, you recall last night's word. A wrong pick only snoozes it, and the
app keeps count of how well you remembered.

## What it does

- **Bedtime nag** — at your bedtime a quiet full-screen popup asks: *Are
  you in bed?* Bedtime is worked out from tomorrow's first alarm and how
  much sleep you want. Not yet? Snooze it — 10 minutes, or 30 min, 1 h,
  2 h when you're out. Fell asleep without answering? The app takes the
  popup's time as your bedtime and doesn't wake you. Each popup also
  makes its case first: one of 300 lines about sleep, dreams, puffy eyes,
  the Matrix and fairy tales.
- **I'm in bed early** — the main screen has a button for that in the
  six hours before bedtime. Lying awake for a while? The word waits: the
  nag still comes and asks *Want the word now?*, or tap *Show the word*
  when you're ready to sleep.
- **A word for the night** — say *Yes* and you get one less common English
  word. It's shown once. Remember it.
- **The chaos alarm** — every ring picks something random: an alarm sound,
  a notification sound, a song from your music starting somewhere in its
  first half, a sound from a folder you picked, or a mix of instruments the
  app makes itself. Switch each source on or off on the Sounds page. Quiet
  at first, louder after 10 seconds. A new surprise after every snooze.
- **The quiz** — three kinds, chosen in Settings:
  - *First letters* (the default): three rounds of four big tiles, each
    round one letter more of the word's beginning; a tap answers. The
    whole word shows at the end.
  - *Whole word*: last night's word among four; tap one to mark it, then
    OK.
  - *Broken teeth*: four words of the same length with the same letters
    missing; tap one to mark it, then OK.

  The right answer stops the alarm; a wrong one snoozes it and drops out
  of the next try. A night with wrong picks counts as failed, shaded by how
  many it took, and shows your streak and your last 30 nights. Five
  failures in a row bring a gentle hint.
- **I'm awake** — awake before the alarm? In the six hours before it, a
  button on the main screen takes you to the quiz, and in the last hour a
  silent notification too. The alarm still rings, with a plain turn-off
  that marks when you got up; or tap *I'm up* to end the night and turn
  off that morning's alarms.
- **Alarms** — repeating on weekdays or once on a date; switch them on and
  off, edit, delete. Reminder alarms that shouldn't move your bedtime get
  their wake-up switch turned off.
- **Vacations** — enter the dates once; repeating alarms and the nag stay
  quiet, one-time alarms still ring.
- **Time in bed** — a week or month of bars, coloured by how the quiz went
  and dimmed where you lay awake in bed, with your average time in bed,
  average time asleep and average bedtime.

## Get it

**F-Droid** (automatic updates): add the repository to the F-Droid app —
*Settings → Repositories → +* — and scan this code:

<p align="center">
  <img src="docs/fdroid-repo-qr.png" width="240" alt="QR code for the F-Droid repository"/>
</p>

or enter the address by hand:

```
https://paxel.github.io/fdroid/repo?fingerprint=2BC56445C8941E060DDD47E3B6D94BDB961D5C0B3854F754520FD181A4F858E8
```

Already have cat(a)log from there? Then it's the same repository — just
refresh F-Droid and search for *chaos-alert*.

**Without F-Droid**: download the file ending in `arm64-v8a.apk` from the
[download page](https://github.com/paxel/chaos-alert/releases), open it and
allow the installation when the phone asks.

On first start the app asks for a few permissions, one by one — exact
alarms, notifications, full-screen popups, no battery optimisation, music.
Without them an alarm might not ring, so the app shows a red banner as long
as one is missing.

## Questions, problems, ideas

Write us: [github.com/paxel/chaos-alert/issues](https://github.com/paxel/chaos-alert/issues).

---

*For developers:* `packages/chaos_core` holds every rule of the night in
pure Dart (`dart test`); the app is Flutter with a small Kotlin layer for
alarms and playback (`flutter analyze && flutter test`). The full
specification is [issue #1](https://github.com/paxel/chaos-alert/issues/1).

*License:* Apache-2.0 or MIT, at your option ([LICENSE-APACHE](LICENSE-APACHE),
[LICENSE-MIT](LICENSE-MIT)). The word list comes from SCOWL and 12dicts; see
[assets/WORDS-LICENSE.txt](assets/WORDS-LICENSE.txt).

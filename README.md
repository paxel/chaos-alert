<p align="center">
  <img src="assets/icon/icon.png" width="128" alt="chaos-alert icon"/>
</p>

<h1 align="center">chaos-alert</h1>

<p align="center">
  <b>Goes to bed with you. Wakes you with chaos.</b><br/>
  Android only. Everything stays on your phone — no account, no internet, no tracking. Free.
</p>

---

Your alarm always sounds the same, so you sleep right through it. And
"just ten more minutes" on the sofa turns into midnight again.

chaos-alert nags you to bed when it's time, gives you one word to remember,
and wakes you with a sound you have never heard coming. To turn the alarm
off, you pick last night's word from four. A wrong pick only snoozes it,
and the app keeps count of how well you remembered.

## What it does

- **Bedtime nag** — at your bedtime a quiet full-screen popup asks: *Are
  you in bed?* Bedtime is worked out from tomorrow's first alarm and how
  much sleep you want. Not yet? Snooze it — 10 minutes, or 30 min, 1 h,
  2 h when you're out. Fell asleep without answering? The app takes the
  popup's time as your bedtime and doesn't wake you. Each popup also
  makes its case first: one of 300 lines about sleep, dreams, puffy eyes,
  the Matrix and fairy tales.
- **I'm in bed early** — the main screen has a button for that in the
  three hours before bedtime.
- **A word for the night** — say *Yes* and you get one less common English
  word. It's shown once. Remember it.
- **The chaos alarm** — every ring picks something random: an alarm sound,
  a notification sound or a song from your music, starting somewhere in its
  first half. Quiet at first, louder after 10 seconds. A new surprise after
  every snooze.
- **The quiz** — four words, one of them last night's. Tap one to mark
  it, then OK. The right word stops the alarm; a wrong one snoozes it and
  drops out of the next try. A night with wrong picks counts as failed,
  shaded by how many it took, and shows your streak and your last 30
  nights. Five failures in a row bring a gentle hint.
- **I'm awake** — up before the alarm? In the hour before it, a button on
  the main screen and a silent notification take you to the quiz; the
  right word turns off that morning's alarms.
- **Alarms** — repeating on weekdays or once on a date; switch them on and
  off, edit, delete. Reminder alarms that shouldn't move your bedtime get
  their wake-up switch turned off.
- **Vacations** — enter the dates once; repeating alarms and the nag stay
  quiet, one-time alarms still ring.
- **Time in bed** — a week or month of bars, coloured by how the quiz went,
  with your average time in bed and average bedtime.

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

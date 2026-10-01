# chaos-alert

An Android app for going to bed and waking up.

- At bedtime a quiet full-screen nag asks whether you are in bed. Yes shows a
  word to remember; Snooze asks again later.
- The alarm plays a random sound — an alarm sound, a notification sound or a
  song — low at first, louder after 10 seconds.
- To turn it off, pick last night's word from four.
- A timeline shows your time in bed per week and month.

Everything stays on the phone. The full specification is
[issue #1](https://github.com/paxel/chaos-alert/issues/1).

## Development

- `packages/chaos_core` — pure Dart, every rule of the night: `dart test`.
- The app — Flutter UI and a small Kotlin layer for alarms and playback:
  `flutter analyze && flutter test`.

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or
[MIT license](LICENSE-MIT) at your option. The word list comes from SCOWL
and 12dicts; see [assets/WORDS-LICENSE.txt](assets/WORDS-LICENSE.txt).

# chaos-alert

An Android app that nags its user to bed, gives them a word to remember for the night, and wakes them with a random sound they can only turn off by recalling that word.

## Language

### Nights

**Night**:
The time from bedtime (in bed) to up; it belongs to exactly one morning.

**Time in bed**:
The part of a night from bedtime to up.
_Avoid_: night length

**Supposed sleep**:
The part of a night from asleep to awake; the time in bed minus the time lying awake at either end.
_Avoid_: sleep time, actual sleep
_Avoid_: sleep, session

**Morning**:
The calendar day a night ends in, whatever the clock time of its wake-up alarm.
_Avoid_: wake day, day

**Bedtime**:
The moment a night started, the user in bed, either confirmed or assumed.
_Avoid_: actual bedtime, time to bed, in bed time

**Asleep**:
The moment the word was shown, the start of the supposed sleep; assumed from the last unanswered nag, never before the bedtime, when the word was never fetched.
_Avoid_: sleep start, word time

**Awake**:
The moment the quiz was answered, the end of the supposed sleep.
_Avoid_: wake time

**Up**:
The moment a night ended: the wake-up alarm turned off, "I'm up", or after an early quiz the first ring of an alarm that timed out.
_Avoid_: end of night, getting up time

**Planned bedtime**:
The morning's earliest wake-up alarm minus the sleep length; when the nag first appears.
_Avoid_: bedtime (for the plan), target bedtime

**Nag**:
One full-screen popup asking whether the user is in bed, or once in bed whether they want the word now, answered with Yes or a snooze; every snooze leads to a new nag.
_Avoid_: popup, bedtime reminder, nag (for the whole evening)

**Nag line**:
One message on a nag that argues, threatens or jokes the user into going to bed.
_Avoid_: nag (for the message), quote, tip

**Confirmed bedtime**:
A bedtime the user gave by tapping "I'm in bed" or answering Yes to the nag.

**Assumed bedtime**:
A bedtime taken from the last nag nobody answered.
_Avoid_: estimated bedtime, guessed bedtime

**I'm in bed**:
Confirming the bedtime early, in the 6 hours before the planned bedtime, without the word; the nag still comes and asks for the word, which the main screen also offers.
_Avoid_: early bedtime, going to bed early

**I'm awake**:
Taking the quiz early, in the 6 hours before the morning's first wake-up alarm; the right word marks awake, and the wake-up alarm then rings with a plain dismiss that marks up.
_Avoid_: early wake-up, awake quiz

**I'm awake notice**:
The silent notification that offers I'm awake, in the hour before the morning's first wake-up alarm.
_Avoid_: awake notification, awake reminder

**I'm up**:
Ending the night after the I'm awake quiz; it marks up and turns off the rest of that morning's wake-up alarms.
_Avoid_: getting up, out of bed

### Alarms

**Alarm**:
A configured entry that rings at a time, either repeating on weekdays or once on a date.
_Avoid_: ring (for the entry)

**Ring**:
One sounding of an alarm with its own random sound, from start until answered, snoozed or timed out; every snooze leads to a new ring.
_Avoid_: alarm (for one sounding)

**Sound source**:
Where a ring's sound comes from, each switchable: the alarm sounds, the notification sounds, the songs, every picked folder on its own, and the generated sounds. Every switched-on source with a sound in it is as likely as any other.
_Avoid_: sound group (for a source)

**Generated sound**:
A one-minute clip the app makes itself from two random instrument styles laid over each other, made new at every scheduling.
_Avoid_: synth, ringtone

**Wake-up alarm**:
An alarm with the wake-up switch on; it sets the planned bedtime, carries the quiz and can end the night.
_Avoid_: main alarm, real alarm

**Reminder alarm**:
An alarm with the wake-up switch off; it rings with a plain dismiss and never touches the night.
_Avoid_: plain alarm, daytime alarm, non-wake-up alarm

**Plain dismiss**:
Turning off a ring with one button and no quiz, whenever no quiz is due: reminder alarms, vacation mornings, nights without a word, mornings whose quiz was taken with I'm awake, and later alarms of an already answered morning.
_Avoid_: simple stop

**Vacation**:
A range of mornings on which repeating alarms and their nags stay silent.
_Avoid_: holiday, pause

**Sleep length**:
The one global amount of sleep subtracted from the earliest wake-up alarm to get the planned bedtime.
_Avoid_: sleep goal, sleep duration

### Word and quiz

**Word**:
The less common English word shown once at bedtime, to be recalled at the morning's quiz.
_Avoid_: night word, secret word

**Quiz**:
Recalling the night's word to turn off a wake-up alarm, as a letter quiz, a word quiz or a broken teeth quiz, chosen in the "Quiz" setting.
_Avoid_: test, challenge

**Letter quiz**:
The default quiz: three rounds of four options, each adding one letter to the word's beginning found so far; the whole word shows after the last round.
_Avoid_: hard quiz, prefix quiz

**Word quiz**:
The easiest quiz: the night's word among four whole words.
_Avoid_: easy quiz, simple quiz

**Broken teeth quiz**:
The hardest quiz: the night's word among four words of its length, each shown as a row of letter tiles with the same random half of the letters (rounded up) missing; the gaps stay for the whole morning, and the whole word shows after the right pick.
_Avoid_: gap quiz, masked quiz, hard quiz

**Distractor**:
A wrong option in the quiz. In the word quiz, one looks like the word and the other two are random; in the letter quiz, each is the beginning of another word that shares the letters found so far, or random letters when too few such words exist; in the broken teeth quiz, all three are random words of the same length that differ from the word in at least one shown letter.
_Avoid_: decoy, wrong answer

### Quiz results

**Wrong pick**:
One wrong option chosen in the quiz, a word or letters.
_Avoid_: miss, mistake

**Failure**:
A night whose quiz had at least one wrong pick.
_Avoid_: miss, failed night

**Missed**:
A night on which every wake-up alarm of the morning timed out unanswered, without the quiz taken with I'm awake before.
_Avoid_: failure, no answer

**Success**:
A night whose quiz was answered with the right word and no wrong pick.

**No word**:
A night on which no word was shown, so there is no quiz.

**Failure streak**:
Failures in a row; no-word and missed nights neither extend nor reset it.
_Avoid_: miss streak

**Hint**:
The one-time, neutral note at a failure streak of 5 that suggests talking to a doctor if it worries the user.
_Avoid_: warning, alert

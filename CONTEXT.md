# chaos-alert

An Android app that nags its user to bed, gives them a word to remember for the night, and wakes them with a random sound they can only turn off by recalling that word.

## Language

### Nights

**Night**:
The time from bedtime to the end of the night; it belongs to exactly one morning.
_Avoid_: sleep, session

**Morning**:
The calendar day a night ends in, whatever the clock time of its wake-up alarm.
_Avoid_: wake day, day

**Bedtime**:
The moment a night started, either confirmed or assumed.
_Avoid_: actual bedtime, time to bed

**Planned bedtime**:
The morning's earliest wake-up alarm minus the sleep length; when the nag first appears.
_Avoid_: bedtime (for the plan), target bedtime

**Nag**:
One full-screen popup asking whether the user is in bed, answered with Yes or a snooze; every snooze leads to a new nag.
_Avoid_: popup, bedtime reminder, nag (for the whole evening)

**Nag line**:
One message on a nag that argues, threatens or jokes the user into going to bed.
_Avoid_: nag (for the message), quote, tip

**Confirmed bedtime**:
A bedtime the user gave by answering Yes to the nag or tapping "I'm in bed".

**Assumed bedtime**:
A bedtime taken from the last nag nobody answered.
_Avoid_: estimated bedtime, guessed bedtime

**I'm in bed**:
Confirming the bedtime early, in the 3 hours before the planned bedtime; it cancels that evening's nags.
_Avoid_: early bedtime, going to bed early

**I'm awake**:
Taking the quiz early, in the hour before the morning's first wake-up alarm; the right word turns off that morning's wake-up alarms.
_Avoid_: early wake-up, awake quiz

**I'm awake notice**:
The silent notification that offers I'm awake.
_Avoid_: awake notification, awake reminder

### Alarms

**Alarm**:
A configured entry that rings at a time, either repeating on weekdays or once on a date.
_Avoid_: ring (for the entry)

**Ring**:
One sounding of an alarm with its own random sound, from start until answered, snoozed or timed out; every snooze leads to a new ring.
_Avoid_: alarm (for one sounding)

**Wake-up alarm**:
An alarm with the wake-up switch on; it sets the planned bedtime, carries the quiz and can end the night.
_Avoid_: main alarm, real alarm

**Reminder alarm**:
An alarm with the wake-up switch off; it rings with a plain dismiss and never touches the night.
_Avoid_: plain alarm, daytime alarm, non-wake-up alarm

**Plain dismiss**:
Turning off a ring with one button and no quiz, whenever no quiz is due: reminder alarms, vacation mornings, nights without a word, and later alarms of an already answered morning.
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
Picking the night's word from four options to turn off a wake-up alarm.
_Avoid_: test, challenge

**Distractor**:
A wrong option in the quiz; one looks like the word, the other two are random.
_Avoid_: decoy, wrong answer

### Quiz results

**Wrong pick**:
One wrong word chosen in the quiz.
_Avoid_: miss, mistake

**Failure**:
A night whose quiz had at least one wrong pick.
_Avoid_: miss, failed night

**Missed**:
A night on which every wake-up alarm of the morning timed out unanswered.
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

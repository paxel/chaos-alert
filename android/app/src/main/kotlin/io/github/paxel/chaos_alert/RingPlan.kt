package io.github.paxel.chaos_alert

/** How long a ring stays at the low volume before it jumps to medium. */
const val LOW_PHASE_MS = 10_000L

/** How many picked sounds are tried before the phone's default alarm sound. */
const val SOUND_ATTEMPTS = 3

/** One sound to try: its uri and where in it to start. */
data class SoundCandidate(val uri: String, val startMs: Int)

/**
 * The pure part of a ring, free of Android: which sound comes next after a
 * failure, and which alarm-stream volume index a share of the maximum is.
 */
class RingPlan(private val candidates: List<SoundCandidate>) {
    private var failures = 0

    /** The sound to play now; null means the phone's default alarm sound. */
    fun current(): SoundCandidate? =
        if (failures < SOUND_ATTEMPTS) candidates.getOrNull(failures) else null

    /** The current sound failed; returns the next one, null for the default. */
    fun failed(): SoundCandidate? {
        failures++
        return current()
    }

    companion object {
        /** The stream volume index for [share] (0 to 1) of [max], at least 1. */
        fun volumeIndex(share: Double, max: Int): Int =
            Math.round(share * max).toInt().coerceIn(1, max)
    }
}

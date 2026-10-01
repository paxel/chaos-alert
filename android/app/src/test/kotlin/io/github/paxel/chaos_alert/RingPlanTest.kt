package io.github.paxel.chaos_alert

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class RingPlanTest {
    private val sounds = listOf(
        SoundCandidate("a", 0),
        SoundCandidate("b", 1000),
        SoundCandidate("c", 0),
        SoundCandidate("d", 0),
    )

    @Test
    fun startsWithThePick() {
        assertEquals("a", RingPlan(sounds).current()?.uri)
    }

    @Test
    fun aFailureMovesToTheNextPick() {
        val plan = RingPlan(sounds)
        assertEquals("b", plan.failed()?.uri)
        assertEquals(1000, plan.current()?.startMs)
    }

    @Test
    fun afterThreeFailuresTheDefaultSoundPlays() {
        val plan = RingPlan(sounds)
        plan.failed()
        plan.failed()
        assertNull(plan.failed())
        assertNull(plan.current())
    }

    @Test
    fun withoutPicksTheDefaultSoundPlays() {
        assertNull(RingPlan(emptyList()).current())
        val one = RingPlan(listOf(SoundCandidate("a", 0)))
        assertNull(one.failed())
    }

    @Test
    fun volumeSharesBecomeStreamIndices() {
        assertEquals(1, RingPlan.volumeIndex(0.2, 7))
        assertEquals(4, RingPlan.volumeIndex(0.5, 7))
        assertEquals(7, RingPlan.volumeIndex(1.0, 7))
        assertEquals(1, RingPlan.volumeIndex(0.0, 7))
    }
}

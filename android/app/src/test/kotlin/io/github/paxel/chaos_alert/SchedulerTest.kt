package io.github.paxel.chaos_alert

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar

class SchedulerTest {
    @Test
    fun localFieldsAreTheWallClockOfTheMoment() {
        val at = Calendar.getInstance().apply {
            clear()
            set(2026, Calendar.OCTOBER, 6, 6, 40, 5)
        }.timeInMillis
        assertEquals(listOf(2026, 10, 6, 6, 40, 5), Scheduler.localFields(at))
    }

    @Test
    fun aFiredNagIsDroppedAndTheOthersAreKept() {
        assertEquals(listOf(1, 2), Scheduler.keptNags(listOf(100L, 200L, 300L), 100L))
    }

    @Test
    fun anUnknownNagKeepsAll() {
        assertEquals(listOf(0, 1), Scheduler.keptNags(listOf(100L, 200L), 150L))
    }
}

package io.github.paxel.chaos_alert

import org.junit.Assert.assertEquals
import org.junit.Test

class EventLogTest {
    private val day = 24L * 60 * 60 * 1000

    @Test
    fun keepsTheLastSevenDays() {
        val now = 100 * day
        val lines = listOf(
            LogLine(now - 8 * day, "too old"),
            LogLine(now - 7 * day, "just kept"),
            LogLine(now - 1, "recent"),
        )
        assertEquals(listOf("just kept", "recent"), EventLog.prune(lines, now).map { it.text })
    }
}

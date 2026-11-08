package io.github.paxel.chaos_alert

import android.content.ContextWrapper
import android.content.Intent
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RearmActionsTest {
    @Test
    fun rearmsForTheSystemBroadcasts() {
        for (action in listOf(
            "android.intent.action.BOOT_COMPLETED",
            "android.intent.action.MY_PACKAGE_REPLACED",
            "android.intent.action.TIME_SET",
            "android.intent.action.TIMEZONE_CHANGED",
        )) {
            assertTrue(action, RearmActions.rearms(action))
        }
    }

    @Test
    fun ignoresAnyOtherAction() {
        assertFalse(RearmActions.rearms(null))
        assertFalse(RearmActions.rearms(""))
        assertFalse(RearmActions.rearms("com.example.WAKE_UP"))
        assertFalse(RearmActions.rearms("android.intent.action.MAIN"))
    }

    @Test
    fun theReceiverIgnoresAnIntentWithoutAnAction() {
        // Logging or arming would ask the context for its preferences; in
        // the unit tests that returns null and the next call on it throws,
        // so the receiver returning quietly shows it did neither.
        RearmReceiver().onReceive(ContextWrapper(null), Intent())
    }
}

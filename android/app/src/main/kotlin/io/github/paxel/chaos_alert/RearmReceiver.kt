package io.github.paxel.chaos_alert

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * After a reboot, an update, a clock change or a new time zone, arms the
 * stored schedule again at the same local times.
 */
class RearmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Exported for the system's broadcasts: another app can still name
        // this receiver in an explicit intent, which is ignored.
        if (!RearmActions.rearms(intent.action)) return
        EventLog.add(context, "android: re-arm after ${intent.action}")
        Scheduler.arm(context)
    }
}

/**
 * The broadcasts that arm the schedule again, the same as the receiver's
 * filter in the manifest. Only the system may send them.
 */
object RearmActions {
    val all = setOf(
        "android.intent.action.BOOT_COMPLETED",
        "android.intent.action.MY_PACKAGE_REPLACED",
        "android.intent.action.TIME_SET",
        "android.intent.action.TIMEZONE_CHANGED",
    )

    fun rearms(action: String?): Boolean = action in all
}

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
        EventLog.add(context, "android: re-arm after ${intent.action}")
        Scheduler.arm(context)
    }
}

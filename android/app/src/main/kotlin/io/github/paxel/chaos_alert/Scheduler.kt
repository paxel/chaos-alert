package io.github.paxel.chaos_alert

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Hands nags and rings to AlarmManager. The schedule is kept as wall-clock
 * times, so a reboot, a clock change or a new time zone re-arms it at the
 * same local time without the app running.
 */
object Scheduler {
    private const val PREFS = "chaos_schedule"
    private const val KEY = "schedule"
    private const val KEY_ARMED = "armed"
    private const val NAG_CODE = 1000
    private const val RING_CODE = 2000
    private const val AWAKE_CODE = 3000

    const val EXTRA_KIND = "chaos.kind"
    const val EXTRA_ALARM_ID = "chaos.alarmId"
    const val EXTRA_PAYLOAD = "chaos.payload"

    /** Changes the stored schedule with [change] and arms it again. */
    private fun update(context: Context, change: (JSONObject) -> Unit) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val schedule = stored(context).also(change)
        prefs.edit().putString(KEY, schedule.toString()).commit()
        arm(context)
    }

    /** Replaces only the nags, keeping the rest. */
    fun replaceNags(context: Context, nags: JSONArray, chime: Boolean) =
        update(context) { it.put("nags", nags).put("chime", chime) }

    /** Replaces only the rings, keeping the rest. */
    fun replaceRings(context: Context, rings: JSONArray) =
        update(context) { it.put("rings", rings) }

    /** Adds one ring, e.g. a snooze from the notification, keeping the rest. */
    fun addRing(context: Context, ring: JSONObject) =
        update(context) { it.put("rings", (it.optJSONArray("rings") ?: JSONArray()).put(ring)) }

    /** Replaces only the "I'm awake" notices, keeping the rest. */
    fun replaceAwake(context: Context, awake: JSONArray) =
        update(context) { it.put("awake", awake) }

    /**
     * Drops the nag planned for [planned] from the stored schedule once it
     * fired, so re-arming after a reboot or a snooze does not show it again.
     * The other nags stay armed as they are.
     */
    fun nagFired(context: Context, planned: Long) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val schedule = stored(context)
        val nags = schedule.optJSONArray("nags") ?: return
        val kept = JSONArray()
        for (i in keptNags(List(nags.length()) { localMillis(nags.getJSONArray(it)) }, planned)) {
            kept.put(nags.getJSONArray(i))
        }
        prefs.edit().putString(KEY, schedule.put("nags", kept).toString()).commit()
    }

    /** The indices of the nags in [planned] other than the one that [fired]. */
    fun keptNags(planned: List<Long>, fired: Long): List<Int> =
        planned.indices.filter { planned[it] != fired }

    private fun stored(context: Context): JSONObject {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return JSONObject(prefs.getString(KEY, "{}"))
    }

    /** Cancels what was armed before and arms the stored schedule. */
    fun arm(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val manager = context.getSystemService(AlarmManager::class.java)
        val armed = JSONObject(prefs.getString(KEY_ARMED, "{}"))
        repeat(armed.optInt("nags")) { i -> manager.cancel(pending(context, NAG_CODE + i, null)) }
        repeat(armed.optInt("rings")) { i -> manager.cancel(pending(context, RING_CODE + i, null)) }
        repeat(armed.optInt("awake")) { i -> manager.cancel(pending(context, AWAKE_CODE + i, null)) }

        val schedule = stored(context)
        val now = System.currentTimeMillis()
        val nags = schedule.optJSONArray("nags") ?: JSONArray()
        val chime = schedule.optBoolean("chime", true)
        for (i in 0 until nags.length()) {
            val planned = localMillis(nags.getJSONArray(i))
            // A bedtime already passed means now.
            val at = maxOf(planned, now + 1000)
            val intent = Intent(context, AlarmReceiver::class.java)
                .putExtra(EXTRA_KIND, "nag")
                .putExtra(EXTRA_PAYLOAD, JSONObject().put("chime", chime).put("planned", planned).toString())
            exact(context, manager, at, pending(context, NAG_CODE + i, intent), alarmClock = false)
        }
        val rings = schedule.optJSONArray("rings") ?: JSONArray()
        for (i in 0 until rings.length()) {
            val ring = rings.getJSONObject(i)
            val at = localMillis(ring.getJSONArray("local"))
            if (at <= now) continue
            val intent = Intent(context, AlarmReceiver::class.java)
                .putExtra(EXTRA_KIND, "ring")
                .putExtra(EXTRA_ALARM_ID, ring.getInt("alarmId"))
                .putExtra(EXTRA_PAYLOAD, ring.toString())
            exact(context, manager, at, pending(context, RING_CODE + i, intent), alarmClock = true)
        }
        val awake = schedule.optJSONArray("awake") ?: JSONArray()
        for (i in 0 until awake.length()) {
            val notice = awake.getJSONObject(i)
            val until = localMillis(notice.getJSONArray("until"))
            if (until <= now) continue
            // Inside the window already: show it now.
            val at = maxOf(localMillis(notice.getJSONArray("local")), now + 1000)
            val intent = Intent(context, AlarmReceiver::class.java)
                .putExtra(EXTRA_KIND, "awake")
                .putExtra(EXTRA_PAYLOAD, JSONObject().put("until", until).toString())
            exact(context, manager, at, pending(context, AWAKE_CODE + i, intent), alarmClock = false)
        }
        EventLog.add(
            context,
            "android: armed ${nags.length()} nags, ${rings.length()} rings, ${awake.length()} awake notices",
        )
        prefs.edit()
            .putString(
                KEY_ARMED,
                JSONObject()
                    .put("nags", nags.length())
                    .put("rings", rings.length())
                    .put("awake", awake.length())
                    .toString(),
            )
            .commit()
    }

    private fun exact(
        context: Context,
        manager: AlarmManager,
        at: Long,
        operation: PendingIntent,
        alarmClock: Boolean,
    ) {
        val allowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms()
        when {
            alarmClock && allowed -> {
                val show = PendingIntent.getActivity(
                    context, 0,
                    Intent(context, MainActivity::class.java),
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
                manager.setAlarmClock(AlarmManager.AlarmClockInfo(at, show), operation)
            }
            allowed -> manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, operation)
            else -> manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, operation)
        }
    }

    private fun pending(context: Context, code: Int, intent: Intent?): PendingIntent =
        PendingIntent.getBroadcast(
            context, code,
            intent ?: Intent(context, AlarmReceiver::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    /** [year, month, day, hour, minute, second] of [millis] in the phone's time zone. */
    fun localFields(millis: Long): List<Int> = Calendar.getInstance().apply { timeInMillis = millis }.let {
        listOf(
            it.get(Calendar.YEAR), it.get(Calendar.MONTH) + 1, it.get(Calendar.DAY_OF_MONTH),
            it.get(Calendar.HOUR_OF_DAY), it.get(Calendar.MINUTE), it.get(Calendar.SECOND),
        )
    }

    /** [year, month, day, hour, minute, second] in the phone's time zone now. */
    private fun localMillis(local: JSONArray): Long = Calendar.getInstance().apply {
        clear()
        set(
            local.getInt(0), local.getInt(1) - 1, local.getInt(2),
            local.getInt(3), local.getInt(4), local.optInt(5),
        )
    }.timeInMillis
}

package io.github.paxel.chaos_alert

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * What Android did on its own (a nag shown, a ring started, a ring timed
 * out), kept until the Dart side reads it. Survives the process dying.
 */
object EventQueue {
    private const val PREFS = "chaos_events"
    private const val KEY = "events"

    @Synchronized
    fun add(context: Context, kind: String, alarmId: Int? = null, at: Long = System.currentTimeMillis()) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val events = JSONArray(prefs.getString(KEY, "[]"))
        val event = JSONObject().put("kind", kind).put("at", at)
        if (alarmId != null) event.put("alarmId", alarmId)
        events.put(event)
        prefs.edit().putString(KEY, events.toString()).commit()
    }

    /** Every queued event, oldest first; the queue is empty afterwards. */
    @Synchronized
    fun drain(context: Context): List<Map<String, Any>> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val events = JSONArray(prefs.getString(KEY, "[]"))
        prefs.edit().remove(KEY).commit()
        return (0 until events.length()).map { i ->
            val e = events.getJSONObject(i)
            buildMap {
                put("kind", e.getString("kind"))
                put("at", e.getLong("at"))
                if (e.has("alarmId")) put("alarmId", e.getInt("alarmId"))
            }
        }
    }
}

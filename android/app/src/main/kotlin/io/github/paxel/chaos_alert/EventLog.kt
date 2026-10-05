package io.github.paxel.chaos_alert

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** One line of the event log: when, and what happened. */
data class LogLine(val at: Long, val text: String)

/**
 * What the app and Android did in the last seven days, for the event log
 * page. Survives the process dying, like [EventQueue].
 */
object EventLog {
    private const val PREFS = "chaos_log"
    private const val KEY = "log"
    const val KEEP_MS = 7L * 24 * 60 * 60 * 1000

    /** [lines] without the ones older than [KEEP_MS] before [now]. */
    fun prune(lines: List<LogLine>, now: Long): List<LogLine> =
        lines.filter { now - it.at <= KEEP_MS }

    @Synchronized
    fun add(context: Context, text: String, at: Long = System.currentTimeMillis()) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val lines = prune(read(context), at) + LogLine(at, text)
        val json = JSONArray()
        for (l in lines) json.put(JSONObject().put("at", l.at).put("text", l.text))
        prefs.edit().putString(KEY, json.toString()).commit()
    }

    /** Every line kept, oldest first. */
    @Synchronized
    fun read(context: Context): List<LogLine> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val json = JSONArray(prefs.getString(KEY, "[]"))
        return (0 until json.length()).map { i ->
            val e = json.getJSONObject(i)
            LogLine(e.getLong("at"), e.getString("text"))
        }
    }
}

package io.github.paxel.chaos_alert

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialLaunch: Map<String, Any>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        initialLaunch = launchOf(intent)
        showOverLockScreen(initialLaunch != null)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val launch = launchOf(intent) ?: return
        showOverLockScreen(true)
        channel?.invokeMethod("launch", launch)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        active = this
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleNags" -> {
                        val args = call.arguments as Map<*, *>
                        Scheduler.replaceNags(
                            this@MainActivity,
                            json(args["local"]) as JSONArray,
                            args["chime"] as Boolean,
                        )
                        result.success(null)
                    }
                    "scheduleRings" -> {
                        Scheduler.replaceRings(this@MainActivity, json(call.arguments) as JSONArray)
                        result.success(null)
                    }
                    "scheduleAwake" -> {
                        Scheduler.replaceAwake(this@MainActivity, json(call.arguments) as JSONArray)
                        result.success(null)
                    }
                    "clearAwakeNotice" -> {
                        AlarmReceiver.clearAwake(this@MainActivity)
                        result.success(null)
                    }
                    "drainEvents" -> result.success(EventQueue.drain(this@MainActivity))
                    "stopRinging" -> {
                        RingService.stop(this@MainActivity)
                        result.success(null)
                    }
                    "log" -> {
                        EventLog.add(this@MainActivity, call.arguments as String)
                        result.success(null)
                    }
                    "readLog" -> result.success(
                        EventLog.read(this@MainActivity).map { mapOf("at" to it.at, "text" to it.text) },
                    )
                    "sounds" -> Thread {
                        val sounds = runCatching { Device.sounds(this@MainActivity) }.getOrDefault(emptyList())
                        runOnUiThread { result.success(sounds) }
                    }.start()
                    "permissions" -> result.success(Device.permissions(this@MainActivity))
                    "request" -> {
                        Device.request(this@MainActivity, call.arguments as String)
                        result.success(null)
                    }
                    "initialLaunch" -> {
                        result.success(initialLaunch)
                        initialLaunch = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        if (active === this) active = null
        super.onDestroy()
    }

    /** The nag and the alarm show over the lock screen and wake it. */
    private fun showOverLockScreen(on: Boolean) {
        if (!on) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
    }

    private fun launchOf(intent: Intent?): Map<String, Any>? =
        when (intent?.getStringExtra(Scheduler.EXTRA_KIND)) {
            "nag" -> mapOf("kind" to "nag")
            "awake" -> mapOf("kind" to "awake")
            "ring" -> mapOf("kind" to "ring", "alarmId" to (intent?.getIntExtra(Scheduler.EXTRA_ALARM_ID, -1) ?: -1))
            else -> null
        }

    /** Channel arguments (maps, lists, numbers) as org.json values. */
    private fun json(value: Any?): Any? = when (value) {
        is Map<*, *> -> JSONObject().apply {
            for ((k, v) in value) put(k.toString(), json(v))
        }
        is List<*> -> JSONArray().apply { for (v in value) put(json(v)) }
        else -> value
    }

    companion object {
        private const val CHANNEL = "io.github.paxel.chaos_alert/alarm"
        private var active: MainActivity? = null

        /** Tells a running app that Android queued an event, so it reads the queue now. */
        fun eventsArrived() {
            val activity = active ?: return
            activity.runOnUiThread { activity.channel?.invokeMethod("events", null) }
        }
    }
}

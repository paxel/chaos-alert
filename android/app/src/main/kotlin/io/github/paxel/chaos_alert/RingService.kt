package io.github.paxel.chaos_alert

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * Plays one ring: the picked sound looping, low for 10 seconds, then
 * medium, until it is stopped or runs into its timeout.
 */
class RingService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var plan: RingPlan? = null
    private var alarmId = -1

    /** The ring playing now, to schedule its snooze from the notification. */
    private var ring: JSONObject? = null
    private var originalVolume: Int? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> start(JSONObject(intent.getStringExtra(Scheduler.EXTRA_PAYLOAD) ?: "{}"))
            ACTION_SNOOZE -> snooze()
            else -> {
                EventLog.add(this, "android: stop requested for alarm $alarmId")
                stopRinging()
            }
        }
        return START_NOT_STICKY
    }

    private fun start(ring: JSONObject) {
        // A second alarm at the same minute takes over from the first.
        stopPlayback()
        this.ring = ring
        alarmId = ring.optInt("alarmId", -1)
        EventLog.add(this, "android: ring of alarm $alarmId started")
        ServiceCompat.startForeground(
            this, NOTIFICATION, notification(),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK else 0,
        )
        wakeLock = getSystemService(PowerManager::class.java)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "chaos-alert:ring")
            .apply { acquire(ring.optLong("timeoutMs", 600_000) + 60_000) }

        val audio = getSystemService(AudioManager::class.java)
        val max = audio.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        originalVolume = audio.getStreamVolume(AudioManager.STREAM_ALARM)
        audio.setStreamVolume(AudioManager.STREAM_ALARM, RingPlan.volumeIndex(ring.optDouble("low", 0.2), max), 0)
        handler.postDelayed({
            audio.setStreamVolume(AudioManager.STREAM_ALARM, RingPlan.volumeIndex(ring.optDouble("medium", 0.5), max), 0)
        }, LOW_PHASE_MS)
        handler.postDelayed({
            EventLog.add(this, "android: ring of alarm $alarmId timed out")
            EventQueue.add(this, "timeout", alarmId)
            stopRinging()
        }, ring.optLong("timeoutMs", 600_000))

        val sounds = ring.optJSONArray("sounds")
        val candidates = (0 until (sounds?.length() ?: 0)).map { i ->
            val s = sounds!!.getJSONObject(i)
            SoundCandidate(s.getString("uri"), s.optInt("startMs"))
        }
        plan = RingPlan(candidates).also { play(it.current()) }
    }

    /**
     * The Snooze action on the notification: stops the sound first, then
     * queues the snooze for the app and schedules the ring again after the
     * alarm snooze, so it rings again even when the app never runs.
     */
    private fun snooze() {
        val current = ring
        stopRinging()
        if (current == null) return
        val id = current.optInt("alarmId", -1)
        EventLog.add(this, "android: ring of alarm $id snoozed from the notification")
        EventQueue.add(this, "snooze", id)
        val at = System.currentTimeMillis() + current.optLong("snoozeMs", 540_000)
        val again = JSONObject(current.toString()).put("local", JSONArray(Scheduler.localFields(at)))
        Scheduler.addRing(this, again)
        MainActivity.eventsArrived()
    }

    /** Plays [sound], or the phone's default alarm sound for null. */
    private fun play(sound: SoundCandidate?) {
        EventLog.add(this, "android: playing ${sound?.uri ?: "the default alarm sound"}")
        player?.release()
        val uri = sound?.let { Uri.parse(it.uri) }
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        val p = MediaPlayer()
        player = p
        try {
            p.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            p.setDataSource(this, uri)
            p.isLooping = true
            p.setOnPreparedListener {
                if ((sound?.startMs ?: 0) > 0) it.seekTo(sound!!.startMs)
                it.start()
            }
            p.setOnErrorListener { _, what, extra ->
                EventLog.add(this, "android: sound failed ($what, $extra)")
                if (sound != null) play(plan?.failed())
                true
            }
            p.prepareAsync()
        } catch (e: Exception) {
            EventLog.add(this, "android: sound failed (${e.javaClass.simpleName})")
            if (sound != null) play(plan?.failed())
        }
    }

    private fun stopPlayback() {
        handler.removeCallbacksAndMessages(null)
        if (player != null) EventLog.add(this, "android: sound stopped")
        player?.release()
        player = null
        originalVolume?.let {
            getSystemService(AudioManager::class.java).setStreamVolume(AudioManager.STREAM_ALARM, it, 0)
        }
        originalVolume = null
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    private fun stopRinging() {
        stopPlayback()
        ring = null
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        stopPlayback()
        super.onDestroy()
    }

    private fun notification(): android.app.Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL, getString(R.string.ring_channel), NotificationManager.IMPORTANCE_HIGH).apply {
                    setSound(null, null)
                    enableVibration(false)
                },
            )
        }
        val open = PendingIntent.getActivity(
            this, NOTIFICATION,
            Intent(this, MainActivity::class.java)
                .putExtra(Scheduler.EXTRA_KIND, "ring")
                .putExtra(Scheduler.EXTRA_ALARM_ID, alarmId)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.ring_title))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOngoing(true)
            .setContentIntent(open)
            .setFullScreenIntent(open, true)
            .addAction(
                0,
                getString(R.string.ring_snooze),
                PendingIntent.getService(
                    this, NOTIFICATION,
                    Intent(this, RingService::class.java).setAction(ACTION_SNOOZE),
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
            .build()
    }

    companion object {
        const val ACTION_START = "io.github.paxel.chaos_alert.RING"
        const val ACTION_STOP = "io.github.paxel.chaos_alert.STOP"
        const val ACTION_SNOOZE = "io.github.paxel.chaos_alert.SNOOZE"
        private const val NOTIFICATION = 2
        private const val CHANNEL = "ring"

        fun stop(context: Context) {
            context.startService(Intent(context, RingService::class.java).setAction(ACTION_STOP))
        }
    }
}

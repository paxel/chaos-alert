package io.github.paxel.chaos_alert

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject

/** Fires when a nag or a ring is due. */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val payload = JSONObject(intent.getStringExtra(Scheduler.EXTRA_PAYLOAD) ?: "{}")
        when (intent.getStringExtra(Scheduler.EXTRA_KIND)) {
            "nag" -> {
                EventQueue.add(context, "nag")
                showNag(context, payload.optBoolean("chime", true))
            }
            "awake" -> showAwake(context, payload.optLong("until"))
            "ring" -> {
                val alarmId = intent.getIntExtra(Scheduler.EXTRA_ALARM_ID, -1)
                EventQueue.add(context, "ring", alarmId)
                // Too late for "I'm awake": the alarm is ringing.
                clearAwake(context)
                ContextCompat.startForegroundService(
                    context,
                    Intent(context, RingService::class.java)
                        .setAction(RingService.ACTION_START)
                        .putExtra(Scheduler.EXTRA_PAYLOAD, payload.toString()),
                )
            }
        }
    }

    companion object {
        private const val NAG_NOTIFICATION = 1
        private const val AWAKE_NOTIFICATION = 3
        private const val CHANNEL_AWAKE = "awake"
        private const val CHANNEL_CHIME = "nag_chime"
        private const val CHANNEL_SILENT = "nag_silent"

        /**
         * The silent "I'm awake" notice in the hour before the alarm; it
         * goes away by itself when the alarm rings at [until].
         */
        fun showAwake(context: Context, until: Long) {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                manager.createNotificationChannel(
                    NotificationChannel(CHANNEL_AWAKE, context.getString(R.string.awake_channel), NotificationManager.IMPORTANCE_LOW).apply {
                        setSound(null, null)
                        enableVibration(false)
                    },
                )
            }
            val open = PendingIntent.getActivity(
                context, AWAKE_NOTIFICATION,
                Intent(context, MainActivity::class.java)
                    .putExtra(Scheduler.EXTRA_KIND, "awake")
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val notification = NotificationCompat.Builder(context, CHANNEL_AWAKE)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(context.getString(R.string.awake_title))
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setSilent(true)
                .setAutoCancel(true)
                .setContentIntent(open)
                .setTimeoutAfter(maxOf(until - System.currentTimeMillis(), 1000))
                .build()
            manager.notify(AWAKE_NOTIFICATION, notification)
        }

        /** Removes the "I'm awake" notice. */
        fun clearAwake(context: Context) =
            context.getSystemService(NotificationManager::class.java).cancel(AWAKE_NOTIFICATION)

        /** The bedtime popup: full screen over the lock screen. */
        fun showNag(context: Context, chime: Boolean) {
            val manager = context.getSystemService(NotificationManager::class.java)
            val channel = if (chime) CHANNEL_CHIME else CHANNEL_SILENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // The chime goes through the notification stream, so a phone
                // on silent or do-not-disturb stays quiet.
                manager.createNotificationChannel(
                    NotificationChannel(channel, context.getString(R.string.nag_channel), NotificationManager.IMPORTANCE_HIGH).apply {
                        if (chime) {
                            setSound(
                                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                                AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                                    .build(),
                            )
                        } else {
                            setSound(null, null)
                        }
                        enableVibration(false)
                    },
                )
            }
            val open = PendingIntent.getActivity(
                context, NAG_NOTIFICATION,
                Intent(context, MainActivity::class.java)
                    .putExtra(Scheduler.EXTRA_KIND, "nag")
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val notification = NotificationCompat.Builder(context, channel)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(context.getString(R.string.nag_title))
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setSilent(!chime)
                .setAutoCancel(true)
                .setContentIntent(open)
                .setFullScreenIntent(open, true)
                .build()
            manager.notify(NAG_NOTIFICATION, notification)
        }
    }
}

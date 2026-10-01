package io.github.paxel.chaos_alert

import android.Manifest
import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/** The phone's sounds and the permissions the alarm needs. */
object Device {
    private val musicPermission =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }

    /** Every alarm and notification sound, and the songs when allowed. */
    fun sounds(context: Context): List<Map<String, Any>> {
        val sounds = mutableListOf<Map<String, Any>>()
        for ((type, group) in listOf(
            RingtoneManager.TYPE_ALARM to "alarm",
            RingtoneManager.TYPE_NOTIFICATION to "notification",
        )) {
            val manager = RingtoneManager(context).apply { setType(type) }
            manager.cursor.use { cursor ->
                while (cursor.moveToNext()) {
                    manager.getRingtoneUri(cursor.position)?.let { uri ->
                        sounds.add(mapOf("uri" to uri.toString(), "group" to group))
                    }
                }
            }
        }
        if (granted(context, musicPermission)) {
            context.contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Audio.Media._ID, MediaStore.Audio.Media.DURATION),
                "${MediaStore.Audio.Media.IS_MUSIC} != 0",
                null,
                null,
            )?.use { cursor ->
                val id = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val duration = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                while (cursor.moveToNext()) {
                    val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, cursor.getLong(id))
                    sounds.add(
                        mapOf(
                            "uri" to uri.toString(),
                            "group" to "song",
                            "lengthMs" to cursor.getLong(duration).toInt(),
                        ),
                    )
                }
            }
        }
        return sounds
    }

    fun permissions(context: Context): Map<String, Boolean> {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val notifications = context.getSystemService(NotificationManager::class.java)
        val power = context.getSystemService(PowerManager::class.java)
        return mapOf(
            "exactAlarms" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()),
            "notifications" to NotificationManagerCompat.from(context).areNotificationsEnabled(),
            "fullScreen" to (Build.VERSION.SDK_INT < 34 || notifications.canUseFullScreenIntent()),
            "battery" to power.isIgnoringBatteryOptimizations(context.packageName),
            "music" to granted(context, musicPermission),
        )
    }

    /** Asks for [permission] with the system dialog or its settings page. */
    fun request(activity: Activity, permission: String) {
        val app = Uri.parse("package:${activity.packageName}")
        when (permission) {
            "exactAlarms" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                activity.startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, app))
            }
            "notifications" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
            } else {
                activity.startActivity(
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName),
                )
            }
            "fullScreen" -> if (Build.VERSION.SDK_INT >= 34) {
                activity.startActivity(Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, app))
            }
            "battery" -> activity.startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, app),
            )
            "music" -> activity.requestPermissions(arrayOf(musicPermission), 2)
        }
    }

    private fun granted(context: Context, permission: String) =
        ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
}

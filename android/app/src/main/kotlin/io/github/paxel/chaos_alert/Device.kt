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
import android.provider.DocumentsContract
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

    /** The longest song a ring plays; longer ones are mostly audiobooks. */
    private const val MAX_SONG_MS = 20 * 60 * 1000

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
                songSelection(),
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

    /** Music, without audiobooks, podcasts and anything over 20 minutes. */
    private fun songSelection(): String {
        val parts = mutableListOf(
            "${MediaStore.Audio.Media.IS_MUSIC} != 0",
            "${MediaStore.Audio.Media.IS_PODCAST} = 0",
            "IFNULL(${MediaStore.Audio.Media.DURATION}, 0) <= $MAX_SONG_MS",
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            parts.add("${MediaStore.Audio.Media.IS_AUDIOBOOK} = 0")
        }
        return parts.joinToString(" AND ")
    }

    /**
     * The audio files in the picked folder [tree] and its subfolders, or
     * null once the phone no longer gives access to it.
     */
    fun folderSounds(context: Context, tree: Uri): List<String>? {
        val granted = context.contentResolver.persistedUriPermissions
            .any { it.uri == tree && it.isReadPermission }
        if (!granted) return null
        return try {
            val files = mutableListOf<String>()
            val pending = ArrayDeque(listOf(DocumentsContract.getTreeDocumentId(tree)))
            while (pending.isNotEmpty()) {
                val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, pending.removeFirst())
                context.contentResolver.query(
                    children,
                    arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_MIME_TYPE),
                    null,
                    null,
                    null,
                )?.use { cursor ->
                    while (cursor.moveToNext()) {
                        val id = cursor.getString(0)
                        val mime = cursor.getString(1) ?: ""
                        when {
                            mime == DocumentsContract.Document.MIME_TYPE_DIR -> pending.add(id)
                            mime.startsWith("audio/") ->
                                files.add(DocumentsContract.buildDocumentUriUsingTree(tree, id).toString())
                        }
                    }
                }
            }
            files
        } catch (e: Exception) {
            null
        }
    }

    /** Keeps access to a folder the user picked; returns its uri and name. */
    fun keepFolder(context: Context, tree: Uri): Map<String, String> {
        context.contentResolver.takePersistableUriPermission(tree, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val document = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val name = runCatching {
            context.contentResolver.query(
                document, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null,
            )?.use { if (it.moveToFirst()) it.getString(0) else null }
        }.getOrNull() ?: tree.lastPathSegment ?: tree.toString()
        return mapOf("uri" to tree.toString(), "name" to name)
    }

    fun releaseFolder(context: Context, tree: Uri) {
        runCatching {
            context.contentResolver.releasePersistableUriPermission(tree, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
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

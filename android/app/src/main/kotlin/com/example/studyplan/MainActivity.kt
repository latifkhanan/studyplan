package com.example.studyplan

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val SOUND_CHANNEL = "com.example.studyplan/notification_sound"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SOUND_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "importCustomAlarmSound" -> {
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name")
                    if (path == null || name == null) {
                        result.error("INVALID_ARGUMENT", "Audio path and name are required.", null)
                    } else {
                        try {
                            result.success(importCustomAlarmSound(path, name))
                        } catch (error: Exception) {
                            result.error("IMPORT_FAILED", error.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun importCustomAlarmSound(path: String, name: String): String {
        check(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            "Custom notification sounds require Android 10 or newer."
        }

        val source = File(path)
        check(source.isFile && source.canRead()) { "The selected audio file cannot be read." }

        val extension = source.extension.lowercase()
        val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
            ?: "audio/mpeg"
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                "${Environment.DIRECTORY_NOTIFICATIONS}/StudyPlan",
            )
            put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
            put(MediaStore.Audio.Media.IS_ALARM, 1)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            values,
        ) ?: error("Android could not create a notification sound entry.")

        try {
            val output = contentResolver.openOutputStream(uri, "w")
                ?: error("Android could not open the notification sound entry.")
            source.inputStream().use { input ->
                output.use { input.copyTo(it) }
            }
            val readyValues = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            contentResolver.update(uri, readyValues, null, null)
            return uri.toString()
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }
}
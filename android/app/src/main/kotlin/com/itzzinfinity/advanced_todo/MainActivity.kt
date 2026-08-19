package com.itzzinfinity.advanced_todo

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the `dayforge/sound_picker` channel: opens the system ringtone picker
 * so a reminder can use any alarm/ringtone already on the phone (Settings →
 * Reminder sound → "Pick from device…"). Returns `{uri, label}`, or null when
 * the user backs out or picks Silent.
 */
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickSound" -> pickSound(call.argument<String>("currentUri"), result)
            else -> result.notImplemented()
        }
    }

    private fun pickSound(currentUri: String?, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "The sound picker is already open", null)
            return
        }
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_TYPE,
                RingtoneManager.TYPE_ALARM or
                    RingtoneManager.TYPE_NOTIFICATION or
                    RingtoneManager.TYPE_RINGTONE
            )
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Reminder sound")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            if (currentUri != null) {
                putExtra(
                    RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                    Uri.parse(currentUri)
                )
            }
        }
        pendingResult = result
        try {
            startActivityForResult(intent, REQUEST_PICK_SOUND)
        } catch (e: Exception) {
            pendingResult = null
            result.error("unavailable", "No sound picker on this device", null)
        }
    }

    @Suppress("DEPRECATION") // getParcelableExtra(String) — minSdk is below 33.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_PICK_SOUND) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingResult ?: return
        pendingResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }
        val uri = data?.getParcelableExtra<Uri>(
            RingtoneManager.EXTRA_RINGTONE_PICKED_URI
        )
        if (uri == null) {
            // "Silent" was chosen — the app models that as its own setting.
            result.success(null)
            return
        }
        val label = try {
            RingtoneManager.getRingtone(this, uri)?.getTitle(this)
        } catch (e: Exception) {
            null
        }
        result.success(
            mapOf("uri" to uri.toString(), "label" to (label ?: "Device sound"))
        )
    }

    private companion object {
        const val CHANNEL = "dayforge/sound_picker"
        const val REQUEST_PICK_SOUND = 5417
    }
}

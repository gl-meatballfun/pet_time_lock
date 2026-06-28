package com.example.pet_time_lock

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel plugin for overlay-specific operations.
 *
 * This is intentionally lightweight: the actual overlay window is managed by
 * the flutter_overlay_window plugin. This plugin only handles permission checks
 * and bringing the main activity back to the foreground.
 */
class OverlayPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.example.pet_time_lock/overlay"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canDrawOverlays" -> {
                result.success(canDrawOverlays())
            }
            "requestOverlayPermission" -> {
                requestOverlayPermission()
                result.success(true)
            }
            "bringAppToForeground" -> {
                val payload = call.argument<String>("payload")
                bringAppToForeground(payload)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}")
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }

    private fun bringAppToForeground(payload: String?) {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            if (payload != null) {
                intent.putExtra("overlay_payload", payload)
            }
            context.startActivity(intent)
        }
    }
}

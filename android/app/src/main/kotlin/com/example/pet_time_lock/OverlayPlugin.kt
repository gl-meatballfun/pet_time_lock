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
 * The actual overlay window is managed by the flutter_overlay_window plugin.
 * This plugin handles permission checks, bringing the main activity back to
 * the foreground, and persisting the overlay position.
 */
class OverlayPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = Constants.OVERLAY_CHANNEL
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Constants.CAN_DRAW_OVERLAYS -> {
                result.success(canDrawOverlays())
            }
            Constants.REQUEST_OVERLAY_PERMISSION -> {
                requestOverlayPermission()
                result.success(true)
            }
            Constants.BRING_APP_TO_FOREGROUND -> {
                val payload = call.argument<String>(Constants.FIELD_PAYLOAD)
                bringAppToForeground(payload)
                result.success(true)
            }
            Constants.SAVE_OVERLAY_POSITION -> {
                val x = call.argument<Double>(Constants.FIELD_X)?.toFloat() ?: 0f
                val y = call.argument<Double>(Constants.FIELD_Y)?.toFloat() ?: 0f
                saveOverlayPosition(x, y)
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
            intent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            if (payload != null) {
                intent.putExtra(Constants.FIELD_PAYLOAD, payload)
            }
            context.startActivity(intent)
        }
    }

    private fun saveOverlayPosition(x: Float, y: Float) {
        context.getSharedPreferences(Constants.OVERLAY_ENABLED, Context.MODE_PRIVATE)
            .edit()
            .putFloat(Constants.OVERLAY_X, x)
            .putFloat(Constants.OVERLAY_Y, y)
            .apply()
    }
}

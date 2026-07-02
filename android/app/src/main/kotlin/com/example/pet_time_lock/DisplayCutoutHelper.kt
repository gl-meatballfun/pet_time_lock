package com.example.pet_time_lock

import android.content.Context
import android.graphics.Rect
import android.os.Build
import android.util.DisplayMetrics
import android.view.Display
import android.view.WindowInsets
import android.view.WindowManager
import android.view.WindowMetrics

/**
 * Helper that computes the safe area where the overlay pet can be dragged.
 *
 * It excludes status bars, navigation bars, and display cutouts (notch /
 * hole-punch) so the floating pet is never hidden by system UI.
 */
object DisplayCutoutHelper {

    data class SafeArea(
        val left: Int,
        val top: Int,
        val right: Int,
        val bottom: Int
    ) {
        val width: Int get() = right - left
        val height: Int get() = bottom - top
    }

    @Suppress("DEPRECATION")
    fun getSafeArea(context: Context): SafeArea {
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val displayMetrics = DisplayMetrics()
        val displayWidth: Int
        val displayHeight: Int

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val windowMetrics: WindowMetrics = windowManager.currentWindowMetrics
            val bounds: Rect = windowMetrics.bounds
            displayWidth = bounds.width()
            displayHeight = bounds.height()

            val insets = windowMetrics.windowInsets
                .getInsetsIgnoringVisibility(
                    WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout()
                )
            return SafeArea(
                left = insets.left,
                top = insets.top,
                right = displayWidth - insets.right,
                bottom = displayHeight - insets.bottom
            )
        } else {
            val display: Display = windowManager.defaultDisplay
            display.getRealMetrics(displayMetrics)
            displayWidth = displayMetrics.widthPixels
            displayHeight = displayMetrics.heightPixels

            // On older devices we approximate the safe margins from the
            // display's standard insets via the decor view if available.
            return SafeArea(
                left = 0,
                top = getStatusBarHeight(context),
                right = displayWidth,
                bottom = displayHeight - getNavigationBarHeight(context)
            )
        }
    }

    private fun getStatusBarHeight(context: Context): Int {
        val resourceId = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (resourceId > 0) context.resources.getDimensionPixelSize(resourceId) else 0
    }

    private fun getNavigationBarHeight(context: Context): Int {
        val resourceId = context.resources.getIdentifier("navigation_bar_height", "dimen", "android")
        return if (resourceId > 0) context.resources.getDimensionPixelSize(resourceId) else 0
    }
}

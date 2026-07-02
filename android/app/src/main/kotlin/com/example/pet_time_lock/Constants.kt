package com.example.pet_time_lock

/**
 * Native constants that mirror [lib/constants/overlay_constants.dart].
 *
 * KEEP IN SYNC with the Dart side. Do not inline these strings elsewhere.
 */
object Constants {
    // MethodChannel names
    const val OVERLAY_CHANNEL = "com.example.pet_time_lock/overlay"
    const val SCREEN_TIME_CHANNEL = "com.example.pet_time_lock/screen_time"

    // Overlay plugin method names
    const val CAN_DRAW_OVERLAYS = "canDrawOverlays"
    const val REQUEST_OVERLAY_PERMISSION = "requestOverlayPermission"
    const val BRING_APP_TO_FOREGROUND = "bringAppToForeground"
    const val SAVE_OVERLAY_POSITION = "saveOverlayPosition"

    // SharedPreferences keys
    const val OVERLAY_ENABLED = "overlay_enabled"
    const val OVERLAY_X = "overlay_x"
    const val OVERLAY_Y = "overlay_y"
    const val OVERLAY_OPACITY = "overlay_opacity"
    const val OVERLAY_TRIGGER_DURATION_MS = "overlay_trigger_duration_ms"
    const val OVERLAY_PENDING_ACTION = "overlay_pending_action"

    // Trigger toggles
    const val TRIGGER_FOCUS_COMPLETE_ENABLED = "trigger_focus_complete_enabled"
    const val TRIGGER_OVER_LIMIT_ENABLED = "trigger_over_limit_enabled"
    const val TRIGGER_EVOLUTION_ENABLED = "trigger_evolution_enabled"

    // Overlay payload actions
    const val ACTION_REFRESH_PET = "refresh_pet"
    const val ACTION_SHOW_TRIGGER = "show_trigger"
    const val ACTION_COLLAPSE = "collapse"
    const val ACTION_ACK_REFRESH = "ack_refresh"
    const val ACTION_UPDATE_POSITION = "update_position"

    // Payload fields
    const val FIELD_ACTION = "action"
    const val FIELD_TRIGGER = "trigger"
    const val FIELD_MESSAGE = "message"
    const val FIELD_DURATION = "duration"
    const val FIELD_VERSION = "version"
    const val FIELD_X = "x"
    const val FIELD_Y = "y"
    const val FIELD_PAYLOAD = "payload"

    // Defaults
    const val DEFAULT_OPACITY = 0.95
    const val DEFAULT_TRIGGER_DURATION_MS = 8000
    const val AUTO_COLLAPSE_DELAY_MS = 5000L
    const val REFRESH_TIMEOUT_MS = 5000L
    const val REFRESH_INTERVAL_SECONDS = 30L

    const val OVERLAY_HEIGHT = 720
    const val OVERLAY_WIDTH = 420
    const val COLLAPSED_PET_SIZE_DP = 80
    const val TRIGGERED_PET_SIZE_DP = 120
    const val DEFAULT_START_X = 24.0
    const val DEFAULT_START_Y = 120.0
}

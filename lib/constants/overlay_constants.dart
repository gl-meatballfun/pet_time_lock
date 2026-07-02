/// Unified constants for the floating overlay pet across Dart and Android.
///
/// Any changes here should be mirrored in the native [Constants.kt] file so the
/// MethodChannel and overlay payloads stay in sync.
class OverlayConstants {
  OverlayConstants._();

  // MethodChannel names
  static const String overlayChannel =
      'com.example.pet_time_lock/overlay';
  static const String screenTimeChannel =
      'com.example.pet_time_lock/screen_time';

  // Method names (overlay plugin)
  static const String canDrawOverlays = 'canDrawOverlays';
  static const String requestOverlayPermission = 'requestOverlayPermission';
  static const String bringAppToForeground = 'bringAppToForeground';
  static const String saveOverlayPosition = 'saveOverlayPosition';

  // SharedPreferences keys
  static const String overlayEnabled = 'overlay_enabled';
  static const String overlayX = 'overlay_x';
  static const String overlayY = 'overlay_y';
  static const String overlayOpacity = 'overlay_opacity';
  static const String overlayTriggerDurationMs =
      'overlay_trigger_duration_ms';
  static const String overlayPendingAction = 'overlay_pending_action';

  // Trigger toggles
  static const String triggerFocusCompleteEnabled =
      'trigger_focus_complete_enabled';
  static const String triggerOverLimitEnabled = 'trigger_over_limit_enabled';
  static const String triggerEvolutionEnabled = 'trigger_evolution_enabled';
  static const String triggerTimeSlotBlockEnabled =
      'trigger_time_slot_block_enabled';
  static const String triggerComplianceRewardEnabled =
      'trigger_compliance_reward_enabled';

  // Overlay payload actions (sent to / from the overlay engine)
  static const String actionRefreshPet = 'refresh_pet';
  static const String actionShowTrigger = 'show_trigger';
  static const String actionCollapse = 'collapse';
  static const String actionAckRefresh = 'ack_refresh';
  static const String actionUpdatePosition = 'update_position';

  // Payload fields
  static const String fieldAction = 'action';
  static const String fieldTrigger = 'trigger';
  static const String fieldMessage = 'message';
  static const String fieldDuration = 'duration';
  static const String fieldVersion = 'version';
  static const String fieldX = 'x';
  static const String fieldY = 'y';
  static const String fieldPayload = 'payload';

  // Default overlay configuration
  static const double defaultOpacity = 0.95;
  static const int defaultTriggerDurationMs = 8000;
  static const int autoCollapseDelayMs = 5000;
  static const int refreshTimeoutMs = 5000;
  static const int refreshIntervalSeconds = 30;

  // Overlay window dimensions (logical pixels)
  static const int overlayHeight = 720;
  static const int overlayWidth = 420;
  static const double collapsedPetSize = 80;
  static const double triggeredPetSize = 120;
  static const double defaultStartX = 24;
  static const double defaultStartY = 120;
}

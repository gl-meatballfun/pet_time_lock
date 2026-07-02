import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/overlay_constants.dart';
import '../models/overlay_payload.dart';

/// Manages the floating overlay pet on Android.
///
/// On iOS this feature is not supported; all public methods degrade gracefully.
class OverlayService {
  static final OverlayService _instance = OverlayService._internal();
  factory OverlayService() => _instance;
  OverlayService._internal();

  static const _channel = MethodChannel(OverlayConstants.overlayChannel);

  Timer? _refreshRetryTimer;

  /// Whether the current platform supports a floating overlay pet.
  bool get isSupported => Platform.isAndroid;

  /// Checks if the system has granted overlay permission.
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod(OverlayConstants.canDrawOverlays) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Opens the system overlay permission settings for this app.
  Future<void> requestPermission() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod(OverlayConstants.requestOverlayPermission);
    } catch (e) {
      debugPrint('Failed to request overlay permission: $e');
    }
  }

  /// Reads whether the user has enabled the floating pet.
  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(OverlayConstants.overlayEnabled) ?? false;
  }

  /// Enables or disables the floating pet.
  ///
  /// When enabling, this method first checks for overlay permission and
  /// requests it if missing. The caller should re-invoke after permission
  /// is granted (e.g. in [WidgetsBindingObserver.didChangeAppLifecycleState]).
  Future<bool> setEnabled(bool enabled) async {
    if (!isSupported) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OverlayConstants.overlayEnabled, enabled);

    if (enabled) {
      final permitted = await hasPermission();
      if (!permitted) {
        await requestPermission();
        return false;
      }
      await showOverlay();
    } else {
      await hideOverlay();
    }
    return true;
  }

  /// Shows the floating pet overlay at the last known position.
  Future<void> showOverlay() async {
    if (!isSupported) return;

    final active = await FlutterOverlayWindow.isActive();
    if (active) return;

    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(OverlayConstants.overlayX);
    final y = prefs.getDouble(OverlayConstants.overlayY);

    await FlutterOverlayWindow.showOverlay(
      height: OverlayConstants.overlayHeight,
      width: OverlayConstants.overlayWidth,
      alignment: OverlayAlignment.topLeft,
      startPosition: (x != null && y != null)
          ? OverlayPosition(x, y)
          : const OverlayPosition(
              OverlayConstants.defaultStartX,
              OverlayConstants.defaultStartY,
            ),
      enableDrag: true,
      positionGravity: PositionGravity.auto,
      overlayTitle: '宠物时间锁',
      overlayContent: '悬浮宠物正在陪伴你',
    );
  }

  /// Hides the floating pet overlay.
  Future<void> hideOverlay() async {
    if (!isSupported) return;
    await FlutterOverlayWindow.closeOverlay();
  }

  /// Shows the overlay pet (if enabled) and displays a temporary trigger
  /// animation with a message.
  Future<void> showOverlayWithTrigger(
    OverlayTrigger trigger, {
    String? message,
  }) async {
    if (!isSupported) return;

    if (!await _isTriggerEnabled(trigger)) return;

    final enabled = await isEnabled();
    if (!enabled) return;

    final permitted = await hasPermission();
    if (!permitted) return;

    await showOverlay();

    final duration = await _triggerDuration();

    await FlutterOverlayWindow.shareData({
      OverlayConstants.fieldAction: OverlayConstants.actionShowTrigger,
      OverlayConstants.fieldTrigger: trigger.name,
      OverlayConstants.fieldMessage: message ?? trigger.message,
      OverlayConstants.fieldDuration: duration.inMilliseconds,
    });
  }

  /// Asks the overlay to refresh its pet state from the database.
  ///
  /// Sends the current [version] so the overlay can skip reading when it
  /// already has the latest data. If no acknowledgement is received within
  /// [OverlayConstants.refreshTimeoutMs], the request is retried once.
  Future<void> refreshOverlayPet({int? version}) async {
    if (!isSupported) return;
    final active = await FlutterOverlayWindow.isActive();
    if (!active) return;

    _refreshRetryTimer?.cancel();

    final payload = {
      OverlayConstants.fieldAction: OverlayConstants.actionRefreshPet,
      if (version != null) OverlayConstants.fieldVersion: version,
    };

    await FlutterOverlayWindow.shareData(payload);

    _refreshRetryTimer = Timer(
      const Duration(milliseconds: OverlayConstants.refreshTimeoutMs),
      () async {
        final stillActive = await FlutterOverlayWindow.isActive();
        if (stillActive) {
          await FlutterOverlayWindow.shareData(payload);
        }
      },
    );
  }

  /// Cancels any pending refresh retry timer.
  void cancelRefreshRetry() {
    _refreshRetryTimer?.cancel();
    _refreshRetryTimer = null;
  }

  /// Saves the overlay's screen position so it can be restored later.
  Future<void> savePosition(double x, double y) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(OverlayConstants.overlayX, x);
    await prefs.setDouble(OverlayConstants.overlayY, y);
  }

  /// Reads the configured overlay opacity (0.0 - 1.0).
  Future<double> opacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(OverlayConstants.overlayOpacity) ??
        OverlayConstants.defaultOpacity;
  }

  /// Persists the overlay opacity.
  Future<void> setOpacity(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      OverlayConstants.overlayOpacity,
      value.clamp(0.3, 1.0),
    );
    await refreshOverlayPet();
  }

  /// Reads the trigger popup duration.
  Future<Duration> _triggerDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(OverlayConstants.overlayTriggerDurationMs) ??
        OverlayConstants.defaultTriggerDurationMs;
    return Duration(milliseconds: ms);
  }

  /// Persists the trigger popup duration.
  Future<void> setTriggerDuration(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      OverlayConstants.overlayTriggerDurationMs,
      duration.inMilliseconds,
    );
  }

  /// Whether a given trigger type is enabled in settings.
  Future<bool> _isTriggerEnabled(OverlayTrigger trigger) async {
    final prefs = await SharedPreferences.getInstance();
    final key = switch (trigger) {
      OverlayTrigger.focusComplete => OverlayConstants.triggerFocusCompleteEnabled,
      OverlayTrigger.overLimit => OverlayConstants.triggerOverLimitEnabled,
      OverlayTrigger.evolution => OverlayConstants.triggerEvolutionEnabled,
    };
    return prefs.getBool(key) ?? true;
  }

  /// Enables or disables a trigger type.
  Future<void> setTriggerEnabled(OverlayTrigger trigger, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = switch (trigger) {
      OverlayTrigger.focusComplete => OverlayConstants.triggerFocusCompleteEnabled,
      OverlayTrigger.overLimit => OverlayConstants.triggerOverLimitEnabled,
      OverlayTrigger.evolution => OverlayConstants.triggerEvolutionEnabled,
    };
    await prefs.setBool(key, enabled);
  }

  /// Brings the main app to the foreground and asks it to handle [payload].
  Future<void> bringAppToForeground(OverlayPayload payload) async {
    if (!isSupported) return;

    // Persist the action so the main app can handle it even after a cold start.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OverlayConstants.overlayPendingAction, payload.value);

    try {
      await FlutterOverlayWindow.launchMainActivity(payload.value);
    } catch (e) {
      debugPrint('Failed to bring app to foreground: $e');
    }
  }

  /// Reads and clears any pending overlay action.
  Future<OverlayPayload?> takePendingAction() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(OverlayConstants.overlayPendingAction);
    if (value == null) return null;
    await prefs.remove(OverlayConstants.overlayPendingAction);
    return OverlayPayload.fromValue(value);
  }
}

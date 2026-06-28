import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/overlay_payload.dart';

/// Manages the floating overlay pet on Android.
///
/// On iOS this feature is not supported; all public methods degrade gracefully.
class OverlayService {
  static final OverlayService _instance = OverlayService._internal();
  factory OverlayService() => _instance;
  OverlayService._internal();

  static const _channel = MethodChannel('com.example.pet_time_lock/overlay');

  static const _kOverlayEnabled = 'overlay_enabled';
  static const _kOverlayX = 'overlay_x';
  static const _kOverlayY = 'overlay_y';

  /// Whether the current platform supports a floating overlay pet.
  bool get isSupported => Platform.isAndroid;

  /// Checks if the system has granted overlay permission.
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod('canDrawOverlays') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Opens the system overlay permission settings for this app.
  Future<void> requestPermission() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('Failed to request overlay permission: $e');
    }
  }

  /// Reads whether the user has enabled the floating pet.
  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOverlayEnabled) ?? false;
  }

  /// Enables or disables the floating pet.
  ///
  /// When enabling, this method first checks for overlay permission and
  /// requests it if missing. The caller should re-invoke after permission
  /// is granted (e.g. in [WidgetsBindingObserver.didChangeAppLifecycleState]).
  Future<bool> setEnabled(bool enabled) async {
    if (!isSupported) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOverlayEnabled, enabled);

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
    final x = prefs.getDouble(_kOverlayX);
    final y = prefs.getDouble(_kOverlayY);

    await FlutterOverlayWindow.showOverlay(
      height: 520,
      width: 420,
      alignment: OverlayAlignment.topLeft,
      startPosition: (x != null && y != null)
          ? OverlayPosition(x, y)
          : const OverlayPosition(24, 120),
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
  Future<void> showOverlayWithTrigger(OverlayTrigger trigger) async {
    if (!isSupported) return;

    final enabled = await isEnabled();
    if (!enabled) return;

    final permitted = await hasPermission();
    if (!permitted) return;

    await showOverlay();

    await FlutterOverlayWindow.shareData({
      'action': 'show_trigger',
      'trigger': trigger.name,
      'message': trigger.message,
    });
  }

  /// Asks the overlay to refresh its pet state from the database.
  Future<void> refreshOverlayPet() async {
    if (!isSupported) return;
    final active = await FlutterOverlayWindow.isActive();
    if (!active) return;

    await FlutterOverlayWindow.shareData({'action': 'refresh_pet'});
  }

  /// Saves the overlay's screen position so it can be restored later.
  Future<void> savePosition(double x, double y) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kOverlayX, x);
    await prefs.setDouble(_kOverlayY, y);
  }

  /// Brings the main app to the foreground and asks it to handle [payload].
  Future<void> bringAppToForeground(OverlayPayload payload) async {
    if (!isSupported) return;

    // Persist the action so the main app can handle it even after a cold start.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('overlay_pending_action', payload.value);

    try {
      await _channel.invokeMethod('bringAppToForeground', {
        'payload': payload.value,
      });
    } catch (e) {
      debugPrint('Failed to bring app to foreground: $e');
    }
  }

  /// Reads and clears any pending overlay action.
  Future<OverlayPayload?> takePendingAction() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('overlay_pending_action');
    if (value == null) return null;
    await prefs.remove('overlay_pending_action');
    return OverlayPayload.fromValue(value);
  }
}

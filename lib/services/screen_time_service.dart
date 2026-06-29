import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class ScreenTimeService {
  Future<bool> requestAuthorization();
  Future<Map<String, int>> getTodayUsageByPackage();
  Future<void> startFocusMode(Duration duration);
  Future<void> stopFocusMode();
  Stream<FocusEvent> get focusEvents;
}

class FocusEvent {
  final FocusEventType type;
  final DateTime timestamp;

  FocusEvent(this.type, this.timestamp);
}

enum FocusEventType { started, completed, cancelled }

class AppUsage {
  final String packageName;
  final int totalTimeInForeground;
  final int lastTimeUsed;

  AppUsage({
    required this.packageName,
    required this.totalTimeInForeground,
    required this.lastTimeUsed,
  });

  factory AppUsage.fromMap(Map<dynamic, dynamic> map) {
    return AppUsage(
      packageName: map['packageName'] as String,
      totalTimeInForeground: (map['totalTimeInForeground'] as num).toInt(),
      lastTimeUsed: (map['lastTimeUsed'] as num).toInt(),
    );
  }
}

/// Returns the appropriate implementation based on platform.
ScreenTimeService createScreenTimeService() {
  if (!kIsWeb && Platform.isAndroid) {
    return AndroidScreenTimeService();
  }
  return LocalScreenTimeService();
}

/// Android native implementation using UsageStatsManager via platform channel.
class AndroidScreenTimeService implements ScreenTimeService {
  static const MethodChannel _channel =
      MethodChannel('com.example.pet_time_lock/screen_time');

  @override
  Future<bool> requestAuthorization() async {
    try {
      return await _channel.invokeMethod('requestUsageStatsPermission') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasAuthorization() async {
    try {
      return await _channel.invokeMethod('hasUsageStatsPermission') ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, int>> getTodayUsageByPackage() async {
    try {
      final hasPermission = await hasAuthorization();
      if (!hasPermission) {
        return _mockUsageData();
      }

      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getTodayUsageByPackage',
      );
      if (result == null) return _mockUsageData();

      return result.map((key, value) =>
          MapEntry(key.toString(), (value as num).toInt()));
    } catch (e) {
      return _mockUsageData();
    }
  }

  Future<List<AppUsage>> getUsageStats({int hours = 24}) async {
    try {
      final hasPermission = await hasAuthorization();
      if (!hasPermission) return [];

      final result = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'getUsageStats',
        {'hours': hours},
      );
      if (result == null) return [];

      return result.map((map) => AppUsage.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, int> _mockUsageData() {
    return {
      'com.tencent.mm': 1800,
      'com.ss.android.ugc.aweme': 900,
      'com.example.app': 120,
    };
  }

  Timer? _focusTimer;
  final _focusController = StreamController<FocusEvent>.broadcast();

  @override
  Future<void> startFocusMode(Duration duration) async {
    _focusTimer?.cancel();
    _focusController.add(FocusEvent(FocusEventType.started, DateTime.now()));
    _focusTimer = Timer(duration, () {
      _focusController.add(FocusEvent(FocusEventType.completed, DateTime.now()));
    });
  }

  @override
  Future<void> stopFocusMode() async {
    _focusTimer?.cancel();
    _focusController.add(FocusEvent(FocusEventType.cancelled, DateTime.now()));
  }

  @override
  Stream<FocusEvent> get focusEvents => _focusController.stream;

  void dispose() {
    _focusTimer?.cancel();
    _focusController.close();
  }
}

class LocalScreenTimeService implements ScreenTimeService {
  Timer? _focusTimer;
  final _focusController = StreamController<FocusEvent>.broadcast();

  @override
  Future<bool> requestAuthorization() async => true;

  @override
  Future<Map<String, int>> getTodayUsageByPackage() async {
    return {
      'com.tencent.mm': 1800,
      'com.ss.android.ugc.aweme': 900,
      'com.example.app': 120,
    };
  }

  @override
  Future<void> startFocusMode(Duration duration) async {
    _focusTimer?.cancel();
    _focusController.add(FocusEvent(FocusEventType.started, DateTime.now()));
    _focusTimer = Timer(duration, () {
      _focusController.add(FocusEvent(FocusEventType.completed, DateTime.now()));
    });
  }

  @override
  Future<void> stopFocusMode() async {
    _focusTimer?.cancel();
    _focusController.add(FocusEvent(FocusEventType.cancelled, DateTime.now()));
  }

  @override
  Stream<FocusEvent> get focusEvents => _focusController.stream;

  void dispose() {
    _focusTimer?.cancel();
    _focusController.close();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../bloc/pet_cubit.dart';
import '../data/database_helper.dart';
import '../models/app_models.dart';
import '../models/compliance_models.dart';
import '../models/overlay_payload.dart';
import 'notification_service.dart';
import 'overlay_service.dart';
import 'screen_time_service.dart';

/// Background task name registered with WorkManager.
const _backgroundCheckTask = 'app_limit_check';

/// Top-level callback dispatcher for WorkManager.
///
/// It must be a top-level or static function annotated with
/// `@pragma('vm:entry-point')` so it survives tree-shaking.
@pragma('vm:entry-point')
void appMonitorCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _backgroundCheckTask) {
      final db = DatabaseHelper.instance;
      final screenTimeService = createScreenTimeService();
      final prefs = await SharedPreferences.getInstance();
      final monitor = AppMonitorService(
        db: db,
        screenTimeService: screenTimeService,
        prefs: prefs,
      );
      await monitor.checkLimitsAndSlots();
    }
    return Future.value(true);
  });
}

/// Monitors app usage against configured limits and time slots.
///
/// When the app is in the foreground a short-period [Timer] is used so
/// feedback is near real-time. When the app is in the background the
/// WorkManager periodic task takes over (Android minimum interval is
/// 15 minutes).
class AppMonitorService {
  static const _kMonitoringEnabled = 'monitoring_enabled';
  static const _kForegroundIntervalSeconds = 'foreground_interval_seconds';

  final DatabaseHelper db;
  final ScreenTimeService screenTimeService;
  final SharedPreferences prefs;
  final NotificationService _notificationService;

  PetCubit? _petCubit;
  Timer? _foregroundTimer;

  AppMonitorService({
    required this.db,
    required this.screenTimeService,
    required this.prefs,
    NotificationService? notificationService,
  }) : _notificationService = notificationService ?? NotificationService();

  /// Provides the [PetCubit] so the monitor can trigger pet state changes
  /// through the existing state-management layer.
  void setPetCubit(PetCubit cubit) {
    _petCubit = cubit;
  }

  /// Whether monitoring is supported on this platform.
  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Whether the user has enabled monitoring.
  bool get isEnabled => prefs.getBool(_kMonitoringEnabled) ?? true;

  /// Foreground polling interval in seconds.
  int get foregroundIntervalSeconds => prefs.getInt(_kForegroundIntervalSeconds) ?? 30;

  /// One-time initialization. Must be called before [startMonitoring].
  Future<void> initialize() async {
    await Workmanager().initialize(appMonitorCallbackDispatcher);
    await _notificationService.initialize();
    if (isEnabled && isSupported) {
      await _scheduleBackgroundWork();
    }
  }

  /// Enables or disables monitoring.
  Future<void> setEnabled(bool enabled) async {
    await prefs.setBool(_kMonitoringEnabled, enabled);
    if (enabled) {
      await _scheduleBackgroundWork();
      startForegroundMonitoring();
    } else {
      await _cancelBackgroundWork();
      stopForegroundMonitoring();
    }
  }

  /// Sets the foreground polling interval.
  Future<void> setForegroundInterval(int seconds) async {
    final clamped = seconds.clamp(10, 300);
    await prefs.setInt(_kForegroundIntervalSeconds, clamped);
    if (_foregroundTimer != null) {
      startForegroundMonitoring();
    }
  }

  /// Starts the foreground polling timer.
  void startForegroundMonitoring() {
    stopForegroundMonitoring();
    if (!isEnabled || !isSupported) return;

    _foregroundTimer = Timer.periodic(
      Duration(seconds: foregroundIntervalSeconds),
      (_) => checkLimitsAndSlots(),
    );
    // Run an immediate check.
    checkLimitsAndSlots();
  }

  /// Stops the foreground polling timer.
  void stopForegroundMonitoring() {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
  }

  /// Performs a single check: records usage, checks limits and time slots,
  /// and applies pet rewards/penalties.
  Future<void> checkLimitsAndSlots() async {
    if (!await screenTimeService.hasAuthorization()) return;

    final usage = await screenTimeService.getTodayUsageByPackage();
    final now = DateTime.now();
    final today = DatabaseHelper.formatDate(now);

    await _recordUsage(usage, today);
    await _checkLimits(usage, today, now);
    await _checkTimeSlots(now);
    await _checkDailyCompliance(usage, today);
  }

  /// Records today's usage into [usage_logs].
  Future<void> _recordUsage(Map<String, int> usage, String date) async {
    // For MVP we store one aggregated log per package per day.
    // Future improvement: record session-level events.
    for (final entry in usage.entries) {
      final seconds = entry.value;
      if (seconds <= 0) continue;

      final existing = await db.getUsageLogsByDate(date);
      final match = existing.where((l) => l.packageName == entry.key).firstOrNull;
      if (match != null && match.durationSeconds == seconds) {
        // No change since last record.
        continue;
      }

      final log = UsageLog(
        packageName: entry.key,
        startTime: nowAtMidnight(date),
        endTime: DateTime.now(),
        durationSeconds: seconds,
        date: date,
      );
      await db.insertUsageLog(log);
    }
  }

  DateTime nowAtMidnight(String date) {
    final parts = date.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// Checks configured app limits and triggers penalties for violations.
  Future<void> _checkLimits(
    Map<String, int> usage,
    String date,
    DateTime now,
  ) async {
    final limits = await db.getAppLimits();
    final todayViolations = await db.getViolationCountForDate(date);

    for (final limit in limits.where((l) => l.isActive)) {
      final seconds = usage[limit.packageName] ?? 0;
      final minutes = seconds ~/ 60;
      if (minutes < limit.dailyLimitMinutes) continue;

      final violation = ViolationLog(
        packageName: limit.packageName,
        appName: limit.appName,
        violationType: 'daily_limit',
        limitMinutes: limit.dailyLimitMinutes,
        actualMinutes: minutes,
        timestamp: now,
      );

      await _handleViolation(
        violation: violation,
        cooldownKey: 'limit_violation_${limit.packageName}_${date}h${now.hour}',
        cooldownMinutes: 5,
        progressiveBase: todayViolations,
      );
    }
  }

  /// Checks active time slots and triggers penalties for violations.
  Future<void> _checkTimeSlots(DateTime now) async {
    final slots = await db.getActiveTimeSlots();
    final currentForeground = await screenTimeService.getCurrentForegroundApp();
    final date = DatabaseHelper.formatDate(now);

    for (final slot in slots) {
      if (!_isInSlot(now, slot)) continue;

      // Whitelist check.
      if (currentForeground != null && await db.isWhitelisted(currentForeground)) {
        continue;
      }

      final blocked = await _isAppBlockedBySlot(currentForeground, slot);
      if (!blocked) continue;

      final appName = currentForeground ?? '当前应用';
      final violation = ViolationLog(
        packageName: currentForeground ?? 'unknown',
        appName: appName,
        violationType: 'time_slot',
        timestamp: now,
      );

      await _handleViolation(
        violation: violation,
        cooldownKey: 'slot_violation_${slot.id}_${date}h${now.hour}',
        cooldownMinutes: 10,
      );
    }
  }

  bool _isInSlot(DateTime now, TimeSlot slot) {
    if (!slot.daysOfWeek.contains(now.weekday)) return false;

    final start = _parseTime(slot.startTime);
    final end = _parseTime(slot.endTime);
    if (start == null || end == null) return false;

    final current = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return current >= startMinutes && current <= endMinutes;
    }
    // Crosses midnight, e.g. 22:00-07:00.
    return current >= startMinutes || current <= endMinutes;
  }

  ({int hour, int minute})? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour: hour, minute: minute);
  }

  Future<bool> _isAppBlockedBySlot(String? packageName, TimeSlot slot) async {
    if (packageName == null) return false;
    if (slot.blockAll) return true;
    if (!slot.blockEntertainment) return false;

    final limits = await db.getAppLimits();
    final limit = limits.where((l) => l.packageName == packageName).firstOrNull;
    return limit != null && limit.category == 'entertainment';
  }

  /// Handles a violation with cooldown and progressive penalty.
  Future<void> _handleViolation({
    required ViolationLog violation,
    required String cooldownKey,
    required int cooldownMinutes,
    int progressiveBase = 0,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastPenalty = prefs.getInt(cooldownKey) ?? 0;
    if (now - lastPenalty < cooldownMinutes * 60 * 1000) return;

    await prefs.setInt(cooldownKey, now);
    await db.insertViolationLog(violation);

    // Notify.
    if (violation.violationType == 'daily_limit') {
      await _notificationService.showAppOverLimitNotification(
        appName: violation.appName ?? violation.packageName,
        limitMinutes: violation.limitMinutes ?? 0,
        actualMinutes: violation.actualMinutes ?? 0,
      );
    } else {
      await _notificationService.showTimeSlotRestrictionNotification(
        slotName: '限制时段',
        blockedAppName: violation.appName ?? violation.packageName,
      );
    }

    // Overlay pet feedback.
    final trigger = violation.violationType == 'daily_limit'
        ? OverlayTrigger.overLimit
        : OverlayTrigger.timeSlotBlock;
    await OverlayService().showOverlayWithTrigger(
      trigger,
      message: _violationMessage(violation),
    );

    // Pet penalty via callback to avoid tight coupling.
    await _applyPetPenalty(violation, progressiveBase);
  }

  String _violationMessage(ViolationLog violation) {
    if (violation.violationType == 'daily_limit') {
      return '${violation.appName ?? violation.packageName} 已超时，休息一下吧~';
    }
    return '现在是限制时段，不要玩啦~';
  }

  Future<void> _applyPetPenalty(ViolationLog violation, int progressiveBase) async {
    final petCubit = _petCubit;
    if (petCubit != null) {
      if (violation.violationType == 'daily_limit') {
        await petCubit.onAppOverLimit(
          packageName: violation.packageName,
          appName: violation.appName,
          overMinutes: violation.actualMinutes != null && violation.limitMinutes != null
              ? violation.actualMinutes! - violation.limitMinutes!
              : null,
          progressiveExtra: progressiveBase,
        );
      } else {
        await petCubit.onTimeSlotViolation(
          packageName: violation.packageName,
          appName: violation.appName,
          progressiveExtra: progressiveBase,
        );
      }
      return;
    }

    // Fallback when running in the background isolate without a PetCubit.
    final pet = await db.getPetState();
    if (pet == null) return;

    final extra = progressiveBase;
    final disciplinePenalty = violation.violationType == 'daily_limit' ? -10 - extra * 2 : -15 - extra * 2;
    final happinessPenalty = violation.violationType == 'daily_limit' ? -5 - extra : -10 - extra;
    final healthPenalty = violation.violationType == 'daily_limit' ? 0 : -5;

    final updated = pet.copyWith(
      discipline: (pet.discipline + disciplinePenalty).clamp(0, 100),
      happiness: (pet.happiness + happinessPenalty).clamp(0, 100),
      health: (pet.health + healthPenalty).clamp(0, 100),
      lastUpdatedAt: DateTime.now(),
    );
    await db.updatePetState(updated);
  }

  /// Checks daily compliance and awards pet rewards.
  Future<void> _checkDailyCompliance(Map<String, int> usage, String date) async {
    final limits = await db.getAppLimits();
    if (limits.isEmpty) return;

    bool allCompliant = true;
    for (final limit in limits.where((l) => l.isActive)) {
      final minutes = (usage[limit.packageName] ?? 0) ~/ 60;
      final wasCompliant = minutes < limit.dailyLimitMinutes;

      final existing = await db.getComplianceRecord(date, limit.packageName);
      final record = ComplianceRecord(
        id: existing?.id,
        date: date,
        packageName: limit.packageName,
        limitMinutes: limit.dailyLimitMinutes,
        actualMinutes: minutes,
        wasCompliant: wasCompliant,
        petRewarded: existing?.petRewarded ?? false,
      );
      await db.insertOrUpdateComplianceRecord(record);

      if (!wasCompliant) allCompliant = false;
    }

    if (!allCompliant) return;

    // Award daily compliance bonus once per day.
    final globalRecord = await db.getComplianceRecord(date, null);
    if (globalRecord?.petRewarded ?? false) return;

    final streak = await _calculateComplianceStreak(date);
    final (happiness, discipline, health, xp, coins) = switch (streak) {
      >= 7 => (50, 25, 20, 50, 25),
      >= 3 => (30, 15, 10, 20, 10),
      _ => (20, 10, 5, 10, 5),
    };

    final petCubit = _petCubit;
    if (petCubit != null) {
      await petCubit.onComplianceDay(
        streak: streak,
        happiness: happiness,
        discipline: discipline,
        health: health,
        xp: xp,
        coins: coins,
      );
    } else {
      final pet = await db.getPetState();
      if (pet == null) return;
      final updated = pet.copyWith(
        happiness: (pet.happiness + happiness).clamp(0, 100),
        discipline: (pet.discipline + discipline).clamp(0, 100),
        health: (pet.health + health).clamp(0, 100),
        growthXp: pet.growthXp + xp,
        growthCoins: pet.growthCoins + coins,
        lastUpdatedAt: DateTime.now(),
      );
      await db.updatePetState(updated);
    }

    await db.insertOrUpdateComplianceRecord(
      ComplianceRecord(
        id: globalRecord?.id,
        date: date,
        actualMinutes: 0,
        wasCompliant: true,
        petRewarded: true,
      ),
    );

    await _notificationService.showComplianceRewardNotification();
    await OverlayService().showOverlayWithTrigger(
      OverlayTrigger.complianceReward,
      message: '今天全部限额都遵守了，宠物为你骄傲！连续 $streak 天~',
    );
  }

  Future<int> _calculateComplianceStreak(String todayDate) async {
    int streak = 0;
    var date = DateTime.parse(todayDate);
    while (true) {
      final record = await db.getComplianceRecord(
        DatabaseHelper.formatDate(date),
        null,
      );
      if (record == null || !record.wasCompliant || !record.petRewarded) break;
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _scheduleBackgroundWork() async {
    await Workmanager().registerPeriodicTask(
      _backgroundCheckTask,
      _backgroundCheckTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  Future<void> _cancelBackgroundWork() async {
    await Workmanager().cancelByUniqueName(_backgroundCheckTask);
  }

  /// Disposes resources. Call when the app is terminating.
  void dispose() {
    stopForegroundMonitoring();
  }
}

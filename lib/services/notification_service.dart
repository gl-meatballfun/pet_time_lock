import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap if needed
  }

  Future<bool> requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> showFocusCompleteNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'focus_channel',
      '专注模式',
      channelDescription: '专注模式完成提醒',
      importance: Importance.high,
      priority: Priority.high,
      ticker: '专注完成',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      '专注完成！',
      '宠物因为你完成了专注而非常开心，继续加油！',
      notificationDetails,
    );
  }

  Future<void> showOverLimitReminder({required String appName}) async {
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      '使用提醒',
      channelDescription: '应用使用时长超额提醒',
      importance: Importance.high,
      priority: Priority.high,
      ticker: '使用提醒',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      2,
      '$appName 使用时长已超标',
      '宠物有点担心你，回来看看它吧~',
      notificationDetails,
    );
  }

  Future<void> showAppOverLimitNotification({
    required String appName,
    required int limitMinutes,
    required int actualMinutes,
  }) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'limit_channel',
      '应用限额提醒',
      channelDescription: '应用每日使用限额提醒',
      importance: Importance.high,
      priority: Priority.high,
      ticker: '应用限额提醒',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      3,
      '$appName 已超时',
      '限额 $limitMinutes 分钟，已使用 $actualMinutes 分钟，休息一下吧~',
      notificationDetails,
    );
  }

  Future<void> showTimeSlotRestrictionNotification({
    required String slotName,
    required String blockedAppName,
  }) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'slot_channel',
      '时段限制提醒',
      channelDescription: '限制时段使用应用提醒',
      importance: Importance.high,
      priority: Priority.high,
      ticker: '时段限制提醒',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      4,
      '$slotName：$blockedAppName 被限制',
      '现在是限制时段，不要玩手机啦，陪陪宠物吧~',
      notificationDetails,
    );
  }

  Future<void> showComplianceRewardNotification() async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'reward_channel',
      '合规奖励',
      channelDescription: '每日屏幕时间合规奖励',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: '合规奖励',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      5,
      '今天表现超棒！',
      '所有应用限额都遵守了，宠物获得额外奖励~',
      notificationDetails,
    );
  }

  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    await _notifications.zonedSchedule(
      6,
      '该休息啦',
      '今天用手机时间有点长，让眼睛休息一下，陪陪宠物吧。',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          '每日提醒',
          channelDescription: '每日休息提醒',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

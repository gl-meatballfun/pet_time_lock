import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../models/app_models.dart';
import '../models/overlay_payload.dart';
import '../constants/overlay_constants.dart';
import '../services/app_monitor_service.dart';
import '../services/notification_service.dart';
import '../services/overlay_service.dart';
import '../services/screen_time_service.dart';
import 'app_limits_screen.dart';
import 'grade_select_screen.dart';
import 'time_slots_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseHelper.instance;
  final _prefsFuture = SharedPreferences.getInstance();
  final _notificationService = NotificationService();

  List<AppLimit> _appLimits = [];
  bool _notificationsEnabled = false;
  bool _overlayEnabled = false;
  bool _overlaySupported = false;
  bool _overlayPermissionGranted = false;
  int _dailyReminderHour = 21;
  int _dailyReminderMinute = 30;
  double _overlayOpacity = OverlayConstants.defaultOpacity;
  int _triggerDurationMs = OverlayConstants.defaultTriggerDurationMs;
  bool _triggerFocusComplete = true;
  bool _triggerOverLimit = true;
  bool _triggerEvolution = true;
  bool _triggerTimeSlotBlock = true;
  bool _triggerComplianceReward = true;
  bool _triggerFeed = true;
  bool _triggerPlay = true;
  bool _triggerPet = true;
  bool _triggerLearn = true;
  bool _monitoringEnabled = true;
  int _monitoringIntervalSeconds = 30;
  bool _monitoringSupported = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _notificationService.initialize();
  }

  Future _loadSettings() async {
    final prefs = await _prefsFuture;
    final limits = await _db.getAppLimits();
    final overlayService = OverlayService();
    final monitorService = AppMonitorService(
      prefs: prefs,
      db: _db,
      screenTimeService: context.read<ScreenTimeService>(),
    );
    setState(() {
      _appLimits = limits;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _dailyReminderHour = prefs.getInt('daily_reminder_hour') ?? 21;
      _dailyReminderMinute = prefs.getInt('daily_reminder_minute') ?? 30;
      _overlayEnabled = prefs.getBool(OverlayConstants.overlayEnabled) ?? false;
      _overlaySupported = overlayService.isSupported;
      _overlayOpacity = prefs.getDouble(OverlayConstants.overlayOpacity) ??
          OverlayConstants.defaultOpacity;
      _triggerDurationMs = prefs.getInt(OverlayConstants.overlayTriggerDurationMs) ??
          OverlayConstants.defaultTriggerDurationMs;
      _triggerFocusComplete =
          prefs.getBool(OverlayConstants.triggerFocusCompleteEnabled) ?? true;
      _triggerOverLimit =
          prefs.getBool(OverlayConstants.triggerOverLimitEnabled) ?? true;
      _triggerEvolution =
          prefs.getBool(OverlayConstants.triggerEvolutionEnabled) ?? true;
      _triggerTimeSlotBlock =
          prefs.getBool(OverlayConstants.triggerTimeSlotBlockEnabled) ?? true;
      _triggerComplianceReward =
          prefs.getBool(OverlayConstants.triggerComplianceRewardEnabled) ?? true;
      _triggerFeed = prefs.getBool(OverlayConstants.triggerFeedEnabled) ?? true;
      _triggerPlay = prefs.getBool(OverlayConstants.triggerPlayEnabled) ?? true;
      _triggerPet = prefs.getBool(OverlayConstants.triggerPetEnabled) ?? true;
      _triggerLearn = prefs.getBool(OverlayConstants.triggerLearnEnabled) ?? true;
      _monitoringEnabled = monitorService.isEnabled;
      _monitoringIntervalSeconds = monitorService.foregroundIntervalSeconds;
      _monitoringSupported = monitorService.isSupported;
    });
    if (_overlaySupported) {
      final permitted = await overlayService.hasPermission();
      setState(() => _overlayPermissionGranted = permitted);
    }
  }

  Future _saveNotificationSettings() async {
    final prefs = await _prefsFuture;
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setInt('daily_reminder_hour', _dailyReminderHour);
    await prefs.setInt('daily_reminder_minute', _dailyReminderMinute);

    if (_notificationsEnabled) {
      await _notificationService.requestPermissions();
      await _notificationService.scheduleDailyReminder(
        hour: _dailyReminderHour,
        minute: _dailyReminderMinute,
      );
    } else {
      await _notificationService.cancelAll();
    }
  }

  Future<void> _onOverlayChanged(bool enabled) async {
    final overlayService = OverlayService();
    if (!overlayService.isSupported) return;

    if (enabled) {
      final permitted = await overlayService.hasPermission();
      if (!permitted) {
        if (mounted) {
          _showOverlayPermissionDialog();
        }
        return;
      }
    }

    final success = await overlayService.setEnabled(enabled);
    if (mounted) {
      setState(() {
        _overlayEnabled = success ? enabled : false;
        if (success && enabled) _overlayPermissionGranted = true;
      });
    }
  }

  void _showOverlayPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开启悬浮宠物'),
        content: const Text(
          '宠物需要「悬浮窗」权限才能陪伴你到桌面和其他应用。\n\n'
          '接下来会跳转系统设置，请允许本应用在其他应用上层显示。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              OverlayService().requestPermission().then((_) {
                // The user must come back and toggle again after granting.
              });
            },
            child: const Text('去开启'),
          ),
        ],
      ),
    );
  }

  Future _requestUsageStatsPermission() async {
    final service = context.read<ScreenTimeService>();
    await service.requestAuthorization();
  }

  Future _resetGrade() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置年级'),
        content: const Text('重置后会清除当前宠物数据，重新选择年级。确定吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await _prefsFuture;
      await prefs.remove('selected_grade');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GradeSelectScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionTitle('屏幕时间权限'),
          ListTile(
            leading: const Icon(Icons.perm_device_information),
            title: const Text('使用情况访问权限'),
            subtitle: const Text('用于统计应用使用时长'),
            trailing: ElevatedButton(
              onPressed: _requestUsageStatsPermission,
              child: const Text('申请'),
            ),
          ),
          _buildSectionTitle('应用限额'),
          ListTile(
            leading: const Icon(Icons.apps),
            title: const Text('管理应用限额'),
            subtitle: Text('已设置 ${_appLimits.length} 个应用'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppLimitsScreen()),
            ),
          ),
          _buildSectionTitle('时段限制'),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('管理时段限制'),
            subtitle: const Text('设置禁用时段，如睡前时间'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TimeSlotsScreen()),
            ),
          ),
          _buildSectionTitle('监控设置'),
          if (!_monitoringSupported)
            const ListTile(
              leading: Icon(Icons.phone_iphone),
              title: Text('使用监控'),
              subtitle: Text('iOS / Web 平台暂不支持自动监控，仅作演示'),
            )
          else
            Column(
              children: [
                SwitchListTile(
                  title: const Text('启用使用监控'),
                  subtitle: const Text('自动检测应用是否超时'),
                  value: _monitoringEnabled,
                  onChanged: (value) async {
                    final monitor = context.read<AppMonitorService>();
                    await monitor.setEnabled(value);
                    setState(() => _monitoringEnabled = value);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('前台检测间隔'),
                  subtitle: Text('$_monitoringIntervalSeconds 秒'),
                  trailing: DropdownButton<int>(
                    value: _monitoringIntervalSeconds,
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10 秒')),
                      DropdownMenuItem(value: 30, child: Text('30 秒')),
                      DropdownMenuItem(value: 60, child: Text('60 秒')),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      final monitor = context.read<AppMonitorService>();
                      await monitor.setForegroundInterval(value);
                      setState(() => _monitoringIntervalSeconds = value);
                    },
                  ),
                ),
              ],
            ),
          _buildSectionTitle('提醒通知'),
          SwitchListTile(
            title: const Text('启用通知'),
            subtitle: const Text('专注完成、超额使用等提醒'),
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              await _saveNotificationSettings();
            },
          ),
          if (_notificationsEnabled)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('每日提醒时间'),
              subtitle: Text(
                  '${_dailyReminderHour.toString().padLeft(2, '0')}:${_dailyReminderMinute.toString().padLeft(2, '0')}'),
              trailing: TextButton(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: _dailyReminderHour,
                      minute: _dailyReminderMinute,
                    ),
                  );
                  if (time != null) {
                    setState(() {
                      _dailyReminderHour = time.hour;
                      _dailyReminderMinute = time.minute;
                    });
                    await _saveNotificationSettings();
                  }
                },
                child: const Text('修改'),
              ),
            ),
          _buildSectionTitle('悬浮宠物'),
          if (!_overlaySupported)
            const ListTile(
              leading: Icon(Icons.phone_iphone),
              title: Text('悬浮宠物'),
              subtitle: Text('iOS 系统暂不支持全局悬浮窗，可在 App 内与宠物互动'),
            )
          else
            Column(
              children: [
                SwitchListTile(
                  title: const Text('桌面悬浮宠物'),
                  subtitle: Text(
                    _overlayPermissionGranted
                        ? '宠物会常驻桌面，随时陪伴你'
                        : '需要悬浮窗权限，开启后宠物会出现在桌面',
                  ),
                  value: _overlayEnabled,
                  onChanged: (value) async {
                    await _onOverlayChanged(value);
                  },
                ),
                if (!_overlayPermissionGranted)
                  ListTile(
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: const Text('悬浮窗权限未开启'),
                    subtitle: const Text('点击重新跳转系统设置授权'),
                    trailing: TextButton(
                      onPressed: () => OverlayService().requestPermission(),
                      child: const Text('去开启'),
                    ),
                  ),
                if (_overlayEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.opacity),
                    title: const Text('悬浮宠物透明度'),
                    subtitle: Slider(
                      value: _overlayOpacity,
                      min: 0.3,
                      max: 1.0,
                      divisions: 7,
                      label: '${(_overlayOpacity * 100).toInt()}%',
                      onChanged: (value) async {
                        setState(() => _overlayOpacity = value);
                        await OverlayService().setOpacity(value);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('提醒弹窗时长'),
                    subtitle: Text('${_triggerDurationMs ~/ 1000} 秒'),
                    trailing: DropdownButton<int>(
                      value: _triggerDurationMs,
                      items: const [
                        DropdownMenuItem(value: 5000, child: Text('5 秒')),
                        DropdownMenuItem(value: 8000, child: Text('8 秒')),
                        DropdownMenuItem(value: 10000, child: Text('10 秒')),
                      ],
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => _triggerDurationMs = value);
                        await OverlayService().setTriggerDuration(
                          Duration(milliseconds: value),
                        );
                      },
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('专注完成提醒'),
                    subtitle: const Text('专注结束后弹出宠物庆祝'),
                    value: _triggerFocusComplete,
                    onChanged: (value) async {
                      setState(() => _triggerFocusComplete = value);
                      await OverlayService().setTriggerEnabled(
                        OverlayTrigger.focusComplete,
                        value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('使用超时提醒'),
                    subtitle: const Text('超额使用手机时弹出宠物提醒'),
                    value: _triggerOverLimit,
                    onChanged: (value) async {
                      setState(() => _triggerOverLimit = value);
                      await OverlayService().setTriggerEnabled(
                        OverlayTrigger.overLimit,
                        value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('宠物进化提醒'),
                    subtitle: const Text('宠物进化时弹出提示'),
                    value: _triggerEvolution,
                    onChanged: (value) async {
                      setState(() => _triggerEvolution = value);
                      await OverlayService().setTriggerEnabled(
                        OverlayTrigger.evolution,
                        value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('时段限制提醒'),
                    subtitle: const Text('限制时段使用应用时弹出提示'),
                    value: _triggerTimeSlotBlock,
                    onChanged: (value) async {
                      setState(() => _triggerTimeSlotBlock = value);
                      await OverlayService().setTriggerEnabled(
                        OverlayTrigger.timeSlotBlock,
                        value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('合规奖励提醒'),
                    subtitle: const Text('全天遵守限额时弹出庆祝'),
                    value: _triggerComplianceReward,
                    onChanged: (value) async {
                      setState(() => _triggerComplianceReward = value);
                      await OverlayService().setTriggerEnabled(
                        OverlayTrigger.complianceReward,
                        value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('喂食反馈'),
                    subtitle: const Text('喂食后悬浮宠物弹出互动反馈'),
                    value: _triggerFeed,
                    onChanged: (value) async {
                      setState(() => _triggerFeed = value);
                      await OverlayService().setTriggerEnabled(
                        OverlayTrigger.feed,
                        value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('玩耍反馈'),
                    subtitle: const Text('玩耍后悬浮宠物弹出互动反馈'),
                    value: _triggerPlay,
                    onChanged: (value) async {
                      setState(() => _triggerPlay = value);
                      await OverlayService().setTriggerEnabled(
                        OverlayTrigger.play,
                        value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('抚摸反馈'),
                    subtitle: const Text('抚摸后悬浮宠物弹出互动反馈'),
                    value: _triggerPet,
                    onChanged: (value) async {
                      setState(() => _triggerPet = value);
                      await OverlayService().setTriggerEnabled(
                        OverlayTrigger.pet,
                        value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('学习反馈'),
                    subtitle: const Text('答题学习后悬浮宠物弹出互动反馈'),
                    value: _triggerLearn,
                    onChanged: (value) async {
                      setState(() => _triggerLearn = value);
                      await OverlayService().setTriggerEnabled(
                        OverlayTrigger.learn,
                        value,
                      );
                    },
                  ),
                ],
              ],
            ),
          _buildSectionTitle('数据'),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('重置年级和宠物'),
            subtitle: const Text('清除当前数据，重新选择年级'),
            onTap: _resetGrade,
          ),
          _buildSectionTitle('测试'),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('测试专注完成通知'),
            onTap: () => _notificationService.showFocusCompleteNotification(),
          ),
          ListTile(
            leading: const Icon(Icons.timer_off),
            title: const Text('测试超额提醒通知'),
            onTap: () => _notificationService.showOverLimitReminder(appName: '微信'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

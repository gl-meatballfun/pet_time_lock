import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../models/app_models.dart';
import '../services/notification_service.dart';
import '../services/overlay_service.dart';
import '../services/screen_time_service.dart';
import 'grade_select_screen.dart';

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
    setState(() {
      _appLimits = limits;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _dailyReminderHour = prefs.getInt('daily_reminder_hour') ?? 21;
      _dailyReminderMinute = prefs.getInt('daily_reminder_minute') ?? 30;
      _overlayEnabled = prefs.getBool('overlay_enabled') ?? false;
      _overlaySupported = overlayService.isSupported;
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

  Future _addAppLimit() async {
    final packageNameController = TextEditingController();
    final appNameController = TextEditingController();
    int limitMinutes = 30;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加应用限额'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: packageNameController,
              decoration: const InputDecoration(
                labelText: '应用包名（如 com.tencent.mm）',
                hintText: 'com.tencent.mm',
              ),
            ),
            TextField(
              controller: appNameController,
              decoration: const InputDecoration(
                labelText: '应用名称',
                hintText: '微信',
              ),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) => Column(
                children: [
                  Text('每日限额：$limitMinutes 分钟'),
                  Slider(
                    value: limitMinutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    label: '$limitMinutes 分钟',
                    onChanged: (value) {
                      setDialogState(() {
                        limitMinutes = value.toInt();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (packageNameController.text.isNotEmpty &&
                  appNameController.text.isNotEmpty) {
                final limit = AppLimit(
                  packageName: packageNameController.text.trim(),
                  appName: appNameController.text.trim(),
                  dailyLimitMinutes: limitMinutes,
                );
                await _db.insertOrUpdateAppLimit(limit);
                await _loadSettings();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('保存'),
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
          ..._appLimits.map((limit) => ListTile(
                leading: const Icon(Icons.apps),
                title: Text(limit.appName),
                subtitle: Text('包名：${limit.packageName}'),
                trailing: Text('${limit.dailyLimitMinutes} 分钟/天'),
              )),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加应用限额'),
            onTap: _addAppLimit,
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

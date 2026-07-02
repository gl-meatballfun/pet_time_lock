import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pet_time_lock/data/database_helper.dart';
import 'package:pet_time_lock/models/app_models.dart';
import 'package:pet_time_lock/models/compliance_models.dart';
import 'package:pet_time_lock/services/app_monitor_service.dart';
import 'package:pet_time_lock/services/notification_service.dart';
import 'package:pet_time_lock/services/screen_time_service.dart';

import '../fake_database_helper.dart';
import '../mocks.dart';
import '../test_helper.dart';

class MockScreenTimeService extends Mock implements ScreenTimeService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerAllFallbackValues);

  group('AppMonitorService', () {
    late FakeDatabaseHelper fakeDb;
    late MockScreenTimeService mockScreenTime;
    late MockNotificationService mockNotifications;
    late MockSharedPreferences mockPrefs;
    late AppMonitorService service;

    setUp(() {
      fakeDb = FakeDatabaseHelper();
      mockScreenTime = MockScreenTimeService();
      mockNotifications = MockNotificationService();
      mockPrefs = MockSharedPreferences();
      service = AppMonitorService(
        db: fakeDb,
        screenTimeService: mockScreenTime,
        prefs: mockPrefs,
        notificationService: mockNotifications,
      );

      when(() => mockScreenTime.hasAuthorization()).thenAnswer((_) async => true);
      when(() => mockScreenTime.getTodayUsageByPackage())
          .thenAnswer((_) async => {});
      when(() => mockScreenTime.getCurrentForegroundApp())
          .thenAnswer((_) async => null);
      when(() => mockPrefs.getBool('monitoring_enabled')).thenReturn(true);
      when(() => mockPrefs.getInt('foreground_interval_seconds')).thenReturn(30);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.getInt(any())).thenReturn(0);
      when(() => mockNotifications.showAppOverLimitNotification(
            appName: any(named: 'appName'),
            limitMinutes: any(named: 'limitMinutes'),
            actualMinutes: any(named: 'actualMinutes'),
          )).thenAnswer((_) async {});
      when(() => mockNotifications.showTimeSlotRestrictionNotification(
            slotName: any(named: 'slotName'),
            blockedAppName: any(named: 'blockedAppName'),
          )).thenAnswer((_) async {});
      when(() => mockNotifications.showComplianceRewardNotification())
          .thenAnswer((_) async {});
    });

    test('检测到应用超限时写入违规记录', () async {
      fakeDb.seedPetState(PetState(currentGrade: 5));
      await fakeDb.insertOrUpdateAppLimit(const AppLimit(
        packageName: 'com.tencent.mm',
        appName: '微信',
        dailyLimitMinutes: 30,
      ));

      when(() => mockScreenTime.getTodayUsageByPackage())
          .thenAnswer((_) async => {'com.tencent.mm': 2400}); // 40 min

      await service.checkLimitsAndSlots();

      final today = DatabaseHelper.formatDate(DateTime.now());
      final violations = await fakeDb.getViolationsForDate(today);
      expect(violations.length, 1);
      expect(violations.first.packageName, 'com.tencent.mm');
      expect(violations.first.violationType, 'daily_limit');
    });

    test('未超限时写入合规记录', () async {
      fakeDb.seedPetState(PetState(currentGrade: 5));
      await fakeDb.insertOrUpdateAppLimit(const AppLimit(
        packageName: 'com.tencent.mm',
        appName: '微信',
        dailyLimitMinutes: 30,
      ));

      when(() => mockScreenTime.getTodayUsageByPackage())
          .thenAnswer((_) async => {'com.tencent.mm': 600}); // 10 min

      await service.checkLimitsAndSlots();

      final today = DatabaseHelper.formatDate(DateTime.now());
      final records = await fakeDb.getComplianceRecordsForDate(today);
      expect(records.isNotEmpty, true);
      final record = records.firstWhere((r) => r.packageName == 'com.tencent.mm');
      expect(record.wasCompliant, true);
      expect(record.actualMinutes, 10);
    });

    test('白名单应用不受时段限制', () async {
      await fakeDb.addWhitelistEntry(const AppWhitelistEntry(
        packageName: 'com.android.dialer',
        appName: '电话',
      ));
      await fakeDb.insertTimeSlot(const TimeSlot(
        name: '测试',
        startTime: '00:00',
        endTime: '23:59',
        blockAll: true,
      ));

      when(() => mockScreenTime.getCurrentForegroundApp())
          .thenAnswer((_) async => 'com.android.dialer');

      await service.checkLimitsAndSlots();

      final today = DatabaseHelper.formatDate(DateTime.now());
      final violations = await fakeDb.getViolationsForDate(today);
      expect(violations.where((v) => v.packageName == 'com.android.dialer'), isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_time_lock/models/compliance_models.dart';
import 'package:pet_time_lock/services/time_slot_service.dart';

import '../fake_database_helper.dart';

void main() {
  group('TimeSlotService', () {
    late FakeDatabaseHelper fakeDb;
    late TimeSlotService service;

    setUp(() {
      fakeDb = FakeDatabaseHelper();
      service = TimeSlotService(fakeDb);
    });

    test('普通时段内返回受限', () async {
      await fakeDb.insertTimeSlot(const TimeSlot(
        name: '上课',
        startTime: '08:00',
        endTime: '12:00',
        daysOfWeek: [1, 2, 3, 4, 5],
      ));

      final restricted = await service.isCurrentlyRestricted(
        DateTime(2026, 7, 2, 10, 0), // Thursday 10:00
      );
      expect(restricted, true);
    });

    test('普通时段外返回不受限', () async {
      await fakeDb.insertTimeSlot(const TimeSlot(
        name: '上课',
        startTime: '08:00',
        endTime: '12:00',
        daysOfWeek: [1, 2, 3, 4, 5],
      ));

      final restricted = await service.isCurrentlyRestricted(
        DateTime(2026, 7, 2, 14, 0),
      );
      expect(restricted, false);
    });

    test('跨午夜时段在夜间返回受限', () async {
      await fakeDb.insertTimeSlot(const TimeSlot(
        name: '睡眠',
        startTime: '22:00',
        endTime: '07:00',
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      ));

      expect(
        await service.isCurrentlyRestricted(DateTime(2026, 7, 2, 23, 0)),
        true,
      );
      expect(
        await service.isCurrentlyRestricted(DateTime(2026, 7, 2, 6, 0)),
        true,
      );
      expect(
        await service.isCurrentlyRestricted(DateTime(2026, 7, 2, 12, 0)),
        false,
      );
    });

    test('星期过滤生效', () async {
      await fakeDb.insertTimeSlot(const TimeSlot(
        name: '周末限制',
        startTime: '08:00',
        endTime: '12:00',
        daysOfWeek: [6, 7], // Saturday, Sunday
      ));

      expect(
        await service.isCurrentlyRestricted(DateTime(2026, 7, 4, 10, 0)), // Saturday
        true,
      );
      expect(
        await service.isCurrentlyRestricted(DateTime(2026, 7, 2, 10, 0)), // Thursday
        false,
      );
    });
  });
}

import '../data/database_helper.dart';
import '../models/compliance_models.dart';

/// Business logic for evaluating time-slot restrictions.
class TimeSlotService {
  final DatabaseHelper _db;

  TimeSlotService(this._db);

  /// Returns all time slots ordered by start time.
  Future<List<TimeSlot>> getTimeSlots() => _db.getTimeSlots();

  /// Returns all active time slots.
  Future<List<TimeSlot>> getActiveTimeSlots() => _db.getActiveTimeSlots();

  /// Whether the current moment falls inside any active restricted slot.
  Future<bool> isCurrentlyRestricted(DateTime now) async {
    final slots = await _db.getActiveTimeSlots();
    return slots.any((slot) => _isInSlot(now, slot));
  }

  /// Returns the active slot that currently applies, if any.
  Future<TimeSlot?> getCurrentSlot(DateTime now) async {
    final slots = await _db.getActiveTimeSlots();
    return slots.where((slot) => _isInSlot(now, slot)).firstOrNull;
  }

  /// Whether a specific package is blocked in the given slot.
  Future<bool> isAppBlockedInSlot(
    String packageName,
    TimeSlot slot,
  ) async {
    if (await _db.isWhitelisted(packageName)) return false;
    if (slot.blockAll) return true;
    if (!slot.blockEntertainment) return false;

    final limits = await _db.getAppLimits();
    final limit = limits.where((l) => l.packageName == packageName).firstOrNull;
    return limit != null && limit.category == 'entertainment';
  }

  /// Public helper to test slot membership.
  bool isInSlot(DateTime now, TimeSlot slot) => _isInSlot(now, slot);

  bool _isInSlot(DateTime now, TimeSlot slot) {
    if (!slot.daysOfWeek.contains(now.weekday)) return false;

    final start = _parseTime(slot.startTime);
    final end = _parseTime(slot.endTime);
    if (start == null || end == null) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
    // Crosses midnight, e.g. 22:00-07:00.
    return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
  }

  ({int hour, int minute})? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour: hour, minute: minute);
  }
}

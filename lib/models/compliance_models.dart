import 'dart:convert';

/// A time window during which certain apps are restricted.
class TimeSlot {
  final int? id;
  final String name;
  final String startTime; // HH:MM
  final String endTime; // HH:MM
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday
  final bool isActive;
  final bool blockEntertainment;
  final bool blockAll;

  const TimeSlot({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.isActive = true,
    this.blockEntertainment = true,
    this.blockAll = false,
  });

  TimeSlot copyWith({
    int? id,
    String? name,
    String? startTime,
    String? endTime,
    List<int>? daysOfWeek,
    bool? isActive,
    bool? blockEntertainment,
    bool? blockAll,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      blockEntertainment: blockEntertainment ?? this.blockEntertainment,
      blockAll: blockAll ?? this.blockAll,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'days_of_week': jsonEncode(daysOfWeek),
      'is_active': isActive ? 1 : 0,
      'block_entertainment': blockEntertainment ? 1 : 0,
      'block_all': blockAll ? 1 : 0,
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      id: map['id'] as int?,
      name: map['name'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      daysOfWeek: map['days_of_week'] == null
          ? const [1, 2, 3, 4, 5, 6, 7]
          : List<int>.from(jsonDecode(map['days_of_week'] as String) as List),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      blockEntertainment: (map['block_entertainment'] as int? ?? 1) == 1,
      blockAll: (map['block_all'] as int? ?? 0) == 1,
    );
  }
}

/// Daily compliance summary per app.
class ComplianceRecord {
  final int? id;
  final String date;
  final String? packageName;
  final int? limitMinutes;
  final int actualMinutes;
  final bool wasCompliant;
  final bool petRewarded;

  const ComplianceRecord({
    this.id,
    required this.date,
    this.packageName,
    this.limitMinutes,
    required this.actualMinutes,
    this.wasCompliant = true,
    this.petRewarded = false,
  });

  ComplianceRecord copyWith({
    int? id,
    String? date,
    String? packageName,
    int? limitMinutes,
    int? actualMinutes,
    bool? wasCompliant,
    bool? petRewarded,
  }) {
    return ComplianceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      packageName: packageName ?? this.packageName,
      limitMinutes: limitMinutes ?? this.limitMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      wasCompliant: wasCompliant ?? this.wasCompliant,
      petRewarded: petRewarded ?? this.petRewarded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'package_name': packageName,
      'limit_minutes': limitMinutes,
      'actual_minutes': actualMinutes,
      'was_compliant': wasCompliant ? 1 : 0,
      'pet_rewarded': petRewarded ? 1 : 0,
    };
  }

  factory ComplianceRecord.fromMap(Map<String, dynamic> map) {
    return ComplianceRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      packageName: map['package_name'] as String?,
      limitMinutes: map['limit_minutes'] as int?,
      actualMinutes: map['actual_minutes'] as int? ?? 0,
      wasCompliant: (map['was_compliant'] as int? ?? 1) == 1,
      petRewarded: (map['pet_rewarded'] as int? ?? 0) == 1,
    );
  }
}

/// A single limit or time-slot violation.
class ViolationLog {
  final int? id;
  final String packageName;
  final String? appName;
  final String violationType; // 'daily_limit' | 'time_slot'
  final int? limitMinutes;
  final int? actualMinutes;
  final DateTime timestamp;
  final bool petPenalized;

  const ViolationLog({
    this.id,
    required this.packageName,
    this.appName,
    required this.violationType,
    this.limitMinutes,
    this.actualMinutes,
    required this.timestamp,
    this.petPenalized = false,
  });

  ViolationLog copyWith({
    int? id,
    String? packageName,
    String? appName,
    String? violationType,
    int? limitMinutes,
    int? actualMinutes,
    DateTime? timestamp,
    bool? petPenalized,
  }) {
    return ViolationLog(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      violationType: violationType ?? this.violationType,
      limitMinutes: limitMinutes ?? this.limitMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      timestamp: timestamp ?? this.timestamp,
      petPenalized: petPenalized ?? this.petPenalized,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'package_name': packageName,
      'app_name': appName,
      'violation_type': violationType,
      'limit_minutes': limitMinutes,
      'actual_minutes': actualMinutes,
      'timestamp': timestamp.toIso8601String(),
      'pet_penalized': petPenalized ? 1 : 0,
    };
  }

  factory ViolationLog.fromMap(Map<String, dynamic> map) {
    return ViolationLog(
      id: map['id'] as int?,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String?,
      violationType: map['violation_type'] as String,
      limitMinutes: map['limit_minutes'] as int?,
      actualMinutes: map['actual_minutes'] as int?,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      petPenalized: (map['pet_penalized'] as int? ?? 0) == 1,
    );
  }
}

/// An app that is always allowed regardless of limits or time slots.
class AppWhitelistEntry {
  final String packageName;
  final String appName;
  final String reason;
  final bool isAlwaysAllowed;

  const AppWhitelistEntry({
    required this.packageName,
    required this.appName,
    this.reason = '',
    this.isAlwaysAllowed = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'package_name': packageName,
      'app_name': appName,
      'reason': reason,
      'is_always_allowed': isAlwaysAllowed ? 1 : 0,
    };
  }

  factory AppWhitelistEntry.fromMap(Map<String, dynamic> map) {
    return AppWhitelistEntry(
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      reason: map['reason'] as String? ?? '',
      isAlwaysAllowed: (map['is_always_allowed'] as int? ?? 1) == 1,
    );
  }
}

/// Aggregated screen-time summary for display.
class ScreenTimeSummary {
  final int totalMinutes;
  final Map<String, int> usageByPackage;
  final List<AppUsageStatus> limitStatuses;

  const ScreenTimeSummary({
    required this.totalMinutes,
    required this.usageByPackage,
    required this.limitStatuses,
  });
}

class AppUsageStatus {
  final String packageName;
  final String appName;
  final int limitMinutes;
  final int actualMinutes;
  final bool isOverLimit;

  const AppUsageStatus({
    required this.packageName,
    required this.appName,
    required this.limitMinutes,
    required this.actualMinutes,
    required this.isOverLimit,
  });

  double get progress => limitMinutes > 0 ? actualMinutes / limitMinutes : 0;
}

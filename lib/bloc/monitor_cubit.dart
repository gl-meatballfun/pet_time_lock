import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/database_helper.dart';
import '../models/app_models.dart';
import '../models/compliance_models.dart';
import '../services/screen_time_service.dart';

part 'monitor_state.dart';

/// BLoC for the screen-time monitor state shown on the home screen.
class MonitorCubit extends Cubit<MonitorState> {
  final DatabaseHelper _db;
  final ScreenTimeService _screenTimeService;

  MonitorCubit(this._db, this._screenTimeService)
      : super(const MonitorState());

  /// Loads today's usage, limits, and time slots.
  Future<void> loadSummary() async {
    emit(state.copyWith(status: MonitorStatus.loading));
    try {
      final usage = await _screenTimeService.getTodayUsageByPackage();
      final limits = await _db.getAppLimits();
      final slots = await _db.getActiveTimeSlots();
      final statuses = _buildLimitStatuses(usage, limits);

      final totalMinutes = usage.values.fold<int>(0, (sum, s) => sum + s) ~/ 60;
      final overLimitApp = statuses.where((s) => s.isOverLimit).firstOrNull;

      emit(state.copyWith(
        status: MonitorStatus.loaded,
        todayUsage: usage,
        limitStatuses: statuses,
        activeTimeSlots: slots,
        totalScreenTimeMinutes: totalMinutes,
        currentlyOverLimitApp: overLimitApp?.packageName,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MonitorStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  List<AppUsageStatus> _buildLimitStatuses(
    Map<String, int> usage,
    List<AppLimit> limits,
  ) {
    return limits.where((l) => l.isActive).map((limit) {
      final actualMinutes = (usage[limit.packageName] ?? 0) ~/ 60;
      return AppUsageStatus(
        packageName: limit.packageName,
        appName: limit.appName,
        limitMinutes: limit.dailyLimitMinutes,
        actualMinutes: actualMinutes,
        isOverLimit: actualMinutes >= limit.dailyLimitMinutes,
      );
    }).toList();
  }
}

part of 'monitor_cubit.dart';

enum MonitorStatus { initial, loading, loaded, error }

class MonitorState extends Equatable {
  final MonitorStatus status;
  final Map<String, int> todayUsage;
  final List<AppUsageStatus> limitStatuses;
  final List<TimeSlot> activeTimeSlots;
  final int totalScreenTimeMinutes;
  final String? currentlyOverLimitApp;
  final String? errorMessage;

  const MonitorState({
    this.status = MonitorStatus.initial,
    this.todayUsage = const {},
    this.limitStatuses = const [],
    this.activeTimeSlots = const [],
    this.totalScreenTimeMinutes = 0,
    this.currentlyOverLimitApp,
    this.errorMessage,
  });

  MonitorState copyWith({
    MonitorStatus? status,
    Map<String, int>? todayUsage,
    List<AppUsageStatus>? limitStatuses,
    List<TimeSlot>? activeTimeSlots,
    int? totalScreenTimeMinutes,
    String? currentlyOverLimitApp,
    String? errorMessage,
  }) {
    return MonitorState(
      status: status ?? this.status,
      todayUsage: todayUsage ?? this.todayUsage,
      limitStatuses: limitStatuses ?? this.limitStatuses,
      activeTimeSlots: activeTimeSlots ?? this.activeTimeSlots,
      totalScreenTimeMinutes:
          totalScreenTimeMinutes ?? this.totalScreenTimeMinutes,
      currentlyOverLimitApp:
          currentlyOverLimitApp ?? this.currentlyOverLimitApp,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        todayUsage,
        limitStatuses,
        activeTimeSlots,
        totalScreenTimeMinutes,
        currentlyOverLimitApp,
        errorMessage,
      ];
}

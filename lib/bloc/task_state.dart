part of 'task_cubit.dart';

enum TaskStatus { initial, loading, loaded, error }

class TaskState extends Equatable {
  final TaskStatus status;
  final List<DailyTask> tasks;
  final String? errorMessage;

  const TaskState({
    this.status = TaskStatus.initial,
    this.tasks = const [],
    this.errorMessage,
  });

  TaskState copyWith({
    TaskStatus? status,
    List<DailyTask>? tasks,
    String? errorMessage,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tasks, errorMessage];
}

import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/database_helper.dart';
import '../models/task_models.dart';
import '../services/reward_service.dart';

part 'task_state.dart';

class _TaskTemplate {
  final String title;
  final String description;
  final TaskType type;
  final String? subject;
  final int targetCount;
  final int rewardGrowthCoins;
  final int rewardHealthPoints;

  const _TaskTemplate({
    required this.title,
    required this.description,
    required this.type,
    this.subject,
    required this.targetCount,
    required this.rewardGrowthCoins,
    this.rewardHealthPoints = 0,
  });
}

class TaskCubit extends Cubit<TaskState> {
  final DatabaseHelper _db;

  TaskCubit(this._db) : super(const TaskState()) {
    _init();
  }

  Future<void> _init() async {
    await loadOrGenerateTasks();
  }

  Future<void> loadOrGenerateTasks() async {
    emit(state.copyWith(status: TaskStatus.loading));
    try {
      final today = DatabaseHelper.formatDate(DateTime.now());
      final existing = await _db.getDailyTasksForDate(today);

      if (existing.isEmpty) {
        await _generateDailyTasks(today);
      }

      final tasks = await _db.getDailyTasksForDate(today);
      emit(state.copyWith(status: TaskStatus.loaded, tasks: tasks));
    } catch (e) {
      emit(state.copyWith(status: TaskStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _generateDailyTasks(String date) async {
    final random = Random();
    const templates = [
      _TaskTemplate(
        title: '文科挑战',
        description: '完成 2 道语文或英语题目',
        type: TaskType.answerQuestions,
        subject: 'humanities',
        targetCount: 2,
        rewardGrowthCoins: 15,
      ),
      _TaskTemplate(
        title: '理科挑战',
        description: '完成 2 道数学或物理题目',
        type: TaskType.answerQuestions,
        subject: 'science',
        targetCount: 2,
        rewardGrowthCoins: 15,
      ),
      _TaskTemplate(
        title: '照顾宠物',
        description: '喂食宠物 2 次',
        type: TaskType.feedPet,
        targetCount: 2,
        rewardGrowthCoins: 10,
        rewardHealthPoints: 5,
      ),
      _TaskTemplate(
        title: '陪伴玩耍',
        description: '和宠物玩耍 2 次',
        type: TaskType.playWithPet,
        targetCount: 2,
        rewardGrowthCoins: 10,
        rewardHealthPoints: 5,
      ),
      _TaskTemplate(
        title: '专注时光',
        description: '完成一次至少 15 分钟的专注模式',
        type: TaskType.focusSession,
        targetCount: 1,
        rewardGrowthCoins: 20,
        rewardHealthPoints: 10,
      ),
      _TaskTemplate(
        title: '今日学习',
        description: '完成任意 1 个学习内容',
        type: TaskType.completeAnyContent,
        targetCount: 1,
        rewardGrowthCoins: 8,
      ),
      _TaskTemplate(
        title: '防沉迷',
        description: '今日不超额使用任何娱乐应用',
        type: TaskType.reduceScreenTime,
        targetCount: 1,
        rewardGrowthCoins: 30,
        rewardHealthPoints: 15,
      ),
    ];

    final shuffled = List<_TaskTemplate>.of(templates)..shuffle(random);
    final selected = shuffled.take(3 + random.nextInt(3)).toList();

    for (int i = 0; i < selected.length; i++) {
      final template = selected[i];
      final task = DailyTask(
        id: 'task_${date}_$i',
        title: template.title,
        description: template.description,
        taskType: template.type,
        subject: template.subject,
        targetCount: template.targetCount,
        rewardGrowthCoins: template.rewardGrowthCoins,
        rewardHealthPoints: template.rewardHealthPoints,
        assignedDate: date,
      );
      await _db.insertOrUpdateDailyTask(task);
    }
  }

  /// 增加指定类型任务的进度。subject 仅对 answerQuestions 类型有效。
  ///
  /// 如果任务尚未加载（例如用户在 App 启动后立即答题），会先触发加载/生成，
  /// 避免进度丢失。
  Future<void> incrementTaskProgress(TaskType type, {String? subject}) async {
    if (state.status == TaskStatus.error) return;

    if (state.status != TaskStatus.loaded) {
      await loadOrGenerateTasks();
    }

    if (state.status != TaskStatus.loaded) return;

    final today = DatabaseHelper.formatDate(DateTime.now());
    var hasChanges = false;

    for (final task in state.tasks) {
      if (task.completed || task.taskType != type) continue;

      if (type == TaskType.answerQuestions && task.subject != null) {
        if (task.subject == 'humanities' &&
            !(subject == '语文' || subject == '英语')) {
          continue;
        }
        if (task.subject == 'science' &&
            !(subject == '数学' || subject == '物理')) {
          continue;
        }
      }

      final newCount = task.currentCount + 1;
      final reachedTarget = newCount >= task.targetCount;
      final updated = task.copyWith(
        currentCount: newCount,
        completed: reachedTarget,
        completedAt: reachedTarget ? DateTime.now() : task.completedAt,
      );
      await _db.insertOrUpdateDailyTask(updated);
      hasChanges = true;
    }

    if (hasChanges) {
      final tasks = await _db.getDailyTasksForDate(today);
      emit(state.copyWith(status: TaskStatus.loaded, tasks: tasks));
    }
  }

  Future<bool> claimTaskReward(DailyTask task) async {
    if (!task.completed) return false;

    try {
      await RewardService().awardCurrency(
        db: _db,
        source: RewardService.sourceDailyTask,
        growthCoinsDelta: task.rewardGrowthCoins,
        healthPointsDelta: task.rewardHealthPoints,
        description: '完成任务: ${task.title}',
      );

      // 标记为已领取：将奖励置 0 避免重复领取
      final claimed = DailyTask(
        id: task.id,
        title: task.title,
        description: task.description,
        taskType: task.taskType,
        subject: task.subject,
        targetCount: task.targetCount,
        currentCount: task.currentCount,
        completed: true,
        completedAt: task.completedAt,
        rewardGrowthCoins: 0,
        rewardHealthPoints: 0,
        assignedDate: task.assignedDate,
      );
      await _db.insertOrUpdateDailyTask(claimed);

      final today = DatabaseHelper.formatDate(DateTime.now());
      final tasks = await _db.getDailyTasksForDate(today);
      emit(state.copyWith(status: TaskStatus.loaded, tasks: tasks));
      return true;
    } catch (e) {
      return false;
    }
  }
}

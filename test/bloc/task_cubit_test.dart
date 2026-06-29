import 'package:flutter_test/flutter_test.dart';
import 'package:pet_time_lock/bloc/task_cubit.dart';
import 'package:pet_time_lock/data/database_helper.dart';
import 'package:pet_time_lock/models/app_models.dart';
import 'package:pet_time_lock/models/task_models.dart';

import '../fake_database_helper.dart';
import '../test_helper.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('TaskCubit', () {
    late FakeDatabaseHelper fakeDb;

    setUp(() {
      fakeDb = FakeDatabaseHelper();
      fakeDb.seedPetState(PetState(currentGrade: 5));
    });

    final today = DatabaseHelper.formatDate(DateTime.now());

    test('init 无任务时自动生成今日任务', () async {
      final cubit = TaskCubit(fakeDb);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.state.tasks.length, greaterThanOrEqualTo(3));
      expect(cubit.state.tasks.length, lessThanOrEqualTo(5));
    });

    test('incrementTaskProgress 累加答题任务进度', () async {
      fakeDb.seedDailyTasks([
        DailyTask(
          id: 'task_001',
          title: '文科挑战',
          description: '',
          taskType: TaskType.answerQuestions,
          subject: 'humanities',
          targetCount: 2,
          rewardGrowthCoins: 10,
          assignedDate: today,
        ),
      ]);

      final cubit = TaskCubit(fakeDb);
      await Future.delayed(const Duration(milliseconds: 100));
      await cubit.incrementTaskProgress(TaskType.answerQuestions, subject: '语文');

      expect(cubit.state.tasks.first.currentCount, 1);
    });

    test('incrementTaskProgress 达到目标后标记完成', () async {
      fakeDb.seedDailyTasks([
        DailyTask(
          id: 'task_001',
          title: '今日学习',
          description: '',
          taskType: TaskType.completeAnyContent,
          targetCount: 1,
          rewardGrowthCoins: 8,
          assignedDate: today,
        ),
      ]);

      final cubit = TaskCubit(fakeDb);
      await Future.delayed(const Duration(milliseconds: 100));
      await cubit.incrementTaskProgress(TaskType.completeAnyContent);

      expect(cubit.state.tasks.first.completed, true);
      expect(cubit.state.tasks.first.currentCount, 1);
    });

    test('claimTaskReward 领取奖励后货币更新且奖励归零', () async {
      fakeDb.seedDailyTasks([
        DailyTask(
          id: 'task_001',
          title: '喂食任务',
          description: '',
          taskType: TaskType.feedPet,
          targetCount: 2,
          currentCount: 2,
          completed: true,
          rewardGrowthCoins: 10,
          rewardHealthPoints: 5,
          assignedDate: today,
        ),
      ]);

      final cubit = TaskCubit(fakeDb);
      await Future.delayed(const Duration(milliseconds: 100));
      final success = await cubit.claimTaskReward(cubit.state.tasks.first);

      expect(success, true);
      expect(cubit.state.tasks.first.rewardGrowthCoins, 0);
      expect(cubit.state.tasks.first.rewardHealthPoints, 0);
      expect(fakeDb.rewardLogs.length, 1);
    });

    test('未完成任务不能领取奖励', () async {
      fakeDb.seedDailyTasks([
        DailyTask(
          id: 'task_001',
          title: '未完成',
          description: '',
          taskType: TaskType.feedPet,
          targetCount: 2,
          currentCount: 0,
          rewardGrowthCoins: 10,
          assignedDate: today,
        ),
      ]);

      final cubit = TaskCubit(fakeDb);
      await Future.delayed(const Duration(milliseconds: 100));
      final success = await cubit.claimTaskReward(cubit.state.tasks.first);

      expect(success, false);
      expect(fakeDb.rewardLogs.length, 0);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_time_lock/bloc/task_cubit.dart';
import 'package:pet_time_lock/models/app_models.dart';
import 'package:pet_time_lock/models/task_models.dart';
import 'package:pet_time_lock/screens/daily_tasks_screen.dart';

import '../fake_database_helper.dart';
import '../test_helper.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('DailyTasksScreen', () {
    late FakeDatabaseHelper fakeDb;
    final today = DateTime.now().toIso8601String().split('T').first;

    setUp(() {
      fakeDb = FakeDatabaseHelper();
      fakeDb.seedPetState(PetState(currentGrade: 5));
    });

    Widget buildTestableWidget(Widget child) {
      return BlocProvider(
        create: (_) => TaskCubit(fakeDb),
        child: MaterialApp(home: child),
      );
    }

    Future<void> pumpTasks(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(buildTestableWidget(const DailyTasksScreen()));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('未完成任务显示剩余奖励角标', (tester) async {
      fakeDb.seedDailyTasks([
        DailyTask(
          id: 'task_001',
          title: '文科挑战',
          description: '完成 2 道语文/英语题',
          taskType: TaskType.answerQuestions,
          targetCount: 2,
          currentCount: 0,
          rewardGrowthCoins: 15,
          rewardHealthPoints: 5,
          assignedDate: today,
        ),
      ]);

      await pumpTasks(tester);

      expect(find.text('文科挑战'), findsOneWidget);
      expect(find.text('📌15 ❤️5'), findsOneWidget);
      expect(find.text('完成'), findsNothing);
    });

    testWidgets('已完成任务显示完成状态而非奖励角标', (tester) async {
      fakeDb.seedDailyTasks([
        DailyTask(
          id: 'task_001',
          title: '喂食任务',
          description: '喂食 1 次',
          taskType: TaskType.feedPet,
          targetCount: 1,
          currentCount: 1,
          completed: true,
          rewardGrowthCoins: 10,
          assignedDate: today,
        ),
      ]);

      await pumpTasks(tester);

      expect(find.text('喂食任务'), findsOneWidget);
      expect(find.text('完成'), findsOneWidget);
      expect(find.text('📌10'), findsNothing);
    });
  });
}

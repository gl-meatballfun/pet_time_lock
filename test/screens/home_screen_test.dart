import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pet_time_lock/bloc/content_cubit.dart';
import 'package:pet_time_lock/bloc/inventory_cubit.dart';
import 'package:pet_time_lock/bloc/monitor_cubit.dart';
import 'package:pet_time_lock/bloc/pet_cubit.dart';
import 'package:pet_time_lock/bloc/shop_cubit.dart';
import 'package:pet_time_lock/bloc/task_cubit.dart';
import 'package:pet_time_lock/models/app_models.dart';
import 'package:pet_time_lock/screens/home_screen.dart';
import 'package:pet_time_lock/services/screen_time_service.dart';

import '../fake_database_helper.dart';
import '../mocks.dart';
import '../test_helper.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('HomeScreen', () {
    late FakeDatabaseHelper fakeDb;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      fakeDb = FakeDatabaseHelper();
      mockPrefs = MockSharedPreferences();
    });

    Widget buildTestableWidget(Widget child) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<FakeDatabaseHelper>.value(value: fakeDb),
          RepositoryProvider<ScreenTimeService>.value(
            value: LocalScreenTimeService(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => PetCubit(fakeDb, mockPrefs)),
            BlocProvider(create: (_) => ContentCubit(fakeDb)),
            BlocProvider(create: (_) => ShopCubit(fakeDb)),
            BlocProvider(create: (_) => InventoryCubit(fakeDb)),
            BlocProvider(create: (_) => TaskCubit(fakeDb)),
            BlocProvider(create: (_) => MonitorCubit(fakeDb, LocalScreenTimeService())),
          ],
          child: MaterialApp(home: child),
        ),
      );
    }

    Future<void> pumpHome(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(buildTestableWidget(const HomeScreen()));
      // 使用多次 pump 等待 Cubit 异步初始化完成；
      // AnimatedPetWidget 有循环动画，不能用 pumpAndSettle。
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('加载后显示四种货币余额', (tester) async {
      fakeDb.seedPetState(PetState(
        currentGrade: 5,
        growthCoins: 123,
        humanitiesPoints: 45,
        sciencePoints: 67,
        healthPoints: 89,
      ));
      when(() => mockPrefs.getInt('selected_grade')).thenReturn(5);

      await pumpHome(tester);

      expect(find.text('123'), findsOneWidget); // 成长币
      expect(find.text('45'), findsOneWidget);  // 文科
      expect(find.text('67'), findsOneWidget);  // 理科
      expect(find.text('89'), findsOneWidget);  // 健康
      expect(find.text('商店'), findsOneWidget);
      expect(find.text('每日任务'), findsOneWidget);
    });
  });
}

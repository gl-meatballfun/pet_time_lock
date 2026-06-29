import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pet_time_lock/bloc/pet_cubit.dart';
import 'package:pet_time_lock/models/app_models.dart';

import '../fake_database_helper.dart';
import '../mocks.dart';
import '../test_helper.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('PetCubit', () {
    late FakeDatabaseHelper fakeDb;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      fakeDb = FakeDatabaseHelper();
      mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getInt('selected_grade')).thenReturn(5);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    });

    PetState createPet({
      int grade = 5,
      int stage = 0,
      int growthCoins = 0,
      int humanitiesPoints = 0,
      int sciencePoints = 0,
      int healthPoints = 0,
      int growthXp = 0,
      int hunger = 100,
    }) {
      return PetState(
        currentGrade: grade,
        stage: stage,
        growthCoins: growthCoins,
        humanitiesPoints: humanitiesPoints,
        sciencePoints: sciencePoints,
        healthPoints: healthPoints,
        growthXp: growthXp,
        hunger: hunger,
      );
    }

    test('loadPetState 从数据库加载宠物状态', () async {
      fakeDb.seedPetState(createPet());
      final cubit = PetCubit(fakeDb, mockPrefs);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.status, PetStatus.loaded);
      expect(cubit.state.petState, isNotNull);
    });

    blocTest<PetCubit, PetManagerState>(
      'answerQuestionCorrectly 答对语文题发放文科积分与成长币',
      build: () {
        fakeDb.seedPetState(createPet());
        return PetCubit(fakeDb, mockPrefs);
      },
      act: (cubit) async {
        await Future.delayed(const Duration(milliseconds: 50));
        await cubit.answerQuestionCorrectly('语文', 5);
      },
      verify: (cubit) {
        final pet = cubit.state.petState!;
        expect(pet.humanitiesPoints, greaterThan(0));
        expect(pet.growthCoins, greaterThan(0));
        expect(pet.knowledge, greaterThan(0));
        expect(fakeDb.rewardLogs.length, 1);
      },
    );

    blocTest<PetCubit, PetManagerState>(
      'answerQuestionCorrectly 答对数学题发放理科积分',
      build: () {
        fakeDb.seedPetState(createPet());
        return PetCubit(fakeDb, mockPrefs);
      },
      act: (cubit) async {
        await Future.delayed(const Duration(milliseconds: 50));
        await cubit.answerQuestionCorrectly('数学', 5);
      },
      verify: (cubit) {
        expect(cubit.state.petState!.sciencePoints, greaterThan(0));
      },
    );

    blocTest<PetCubit, PetManagerState>(
      'completeFocusSession 发放健康积分与成长币',
      build: () {
        fakeDb.seedPetState(createPet());
        return PetCubit(fakeDb, mockPrefs);
      },
      act: (cubit) async {
        await Future.delayed(const Duration(milliseconds: 50));
        await cubit.completeFocusSession(25);
      },
      verify: (cubit) {
        final pet = cubit.state.petState!;
        expect(pet.healthPoints, greaterThan(0));
        expect(pet.growthCoins, greaterThan(0));
        expect(pet.growthXp, 50); // 25 * 2
      },
    );

    blocTest<PetCubit, PetManagerState>(
      '成长 XP 达到阈值触发进化并奖励成长币',
      build: () {
        fakeDb.seedPetState(createPet(growthXp: 55, hunger: 50)); // 超过 stage 1 阈值 50
        return PetCubit(fakeDb, mockPrefs);
      },
      act: (cubit) async {
        await Future.delayed(const Duration(milliseconds: 50));
        await cubit.feedPet();
      },
      verify: (cubit) {
        final pet = cubit.state.petState!;
        expect(pet.stage, 1);
        expect(pet.growthCoins, greaterThan(0)); // 进化奖励
        expect(pet.appearance.unlockedAccessories, contains('🍼'));
      },
    );
  });
}

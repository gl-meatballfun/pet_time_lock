import 'package:flutter_test/flutter_test.dart';
import 'package:pet_time_lock/models/app_models.dart';
import 'package:pet_time_lock/models/currency_models.dart';
import 'package:pet_time_lock/models/task_models.dart';
import 'package:pet_time_lock/services/reward_service.dart';

import '../fake_database_helper.dart';
import '../test_helper.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('RewardService', () {
    late RewardService rewardService;
    late FakeDatabaseHelper fakeDb;

    setUp(() {
      rewardService = RewardService();
      fakeDb = FakeDatabaseHelper();
    });

    group('calculateSubjectReward', () {
      test('语文/英语 返回文科积分', () {
        final reward = RewardService.calculateSubjectReward('语文', 5);
        expect(reward.currencyName, '文科积分');
        expect(reward.subjectPoints, greaterThanOrEqualTo(5 + (5 - 1) ~/ 2));
        expect(reward.growthCoins, 2 + (5 ~/ 3));
      });

      test('数学/物理 返回理科积分', () {
        final reward = RewardService.calculateSubjectReward('物理', 8);
        expect(reward.currencyName, '理科积分');
        expect(reward.subjectPoints, greaterThanOrEqualTo(5 + (8 - 1) ~/ 2));
      });

      test('未知学科只发成长币', () {
        final reward = RewardService.calculateSubjectReward('美术', 3);
        expect(reward.currencyName, '积分');
        expect(reward.subjectPoints, greaterThanOrEqualTo(3)); // (5+1)~/2 = 3 起步，含随机加成
      });
    });

    group('calculateFocusReward', () {
      test('15 分钟专注奖励 4 健康积分', () {
        expect(RewardService.calculateFocusReward(15), 4);
      });

      test('60 分钟专注奖励 9 健康积分', () {
        expect(RewardService.calculateFocusReward(60), 9);
      });
    });

    group('calculateTaskReward', () {
      test('答题任务成长币随年级增加', () {
        expect(RewardService.calculateTaskRewardGrowthCoins(TaskType.answerQuestions, 5), 15);
      });

      test('专注任务成长币高于喂食', () {
        expect(
          RewardService.calculateTaskRewardGrowthCoins(TaskType.focusSession, 1),
          greaterThan(
            RewardService.calculateTaskRewardGrowthCoins(TaskType.feedPet, 1),
          ),
        );
      });
    });

    group('awardCurrency', () {
      test('发放货币并记录流水', () async {
        fakeDb.seedPetState(PetState(currentGrade: 5, growthCoins: 10));

        final updated = await rewardService.awardCurrency(
          db: fakeDb,
          source: RewardService.sourceAnswerCorrect,
          growthCoinsDelta: 3,
          humanitiesPointsDelta: 7,
          description: '测试奖励',
        );

        expect(updated.growthCoins, 13);
        expect(updated.humanitiesPoints, 7);
        expect(fakeDb.rewardLogs.length, 1);
      });
    });

    group('deductCurrencyForPurchase', () {
      test('余额充足时扣款成功', () async {
        fakeDb.seedPetState(PetState(
          currentGrade: 5,
          growthCoins: 100,
          humanitiesPoints: 50,
        ));

        final pet = (await fakeDb.getPetState())!;
        const item = ShopItem(
          id: 'test_item',
          name: '测试物品',
          description: '',
          iconEmoji: '🧪',
          category: ShopItemCategory.food,
          growthCoinsCost: 30,
          humanitiesPointsCost: 20,
          effectHunger: 10,
        );

        final success = await rewardService.deductCurrencyForPurchase(
          db: fakeDb,
          pet: pet,
          item: item,
        );

        expect(success, true);
        expect((await fakeDb.getPetState())!.growthCoins, 70);
        expect(fakeDb.rewardLogs.length, 1);
      });

      test('余额不足时返回 false 不扣款', () async {
        fakeDb.seedPetState(PetState(currentGrade: 5, growthCoins: 5));
        final pet = (await fakeDb.getPetState())!;
        const item = ShopItem(
          id: 'test_item',
          name: '测试物品',
          description: '',
          iconEmoji: '🧪',
          category: ShopItemCategory.food,
          growthCoinsCost: 30,
          effectHunger: 10,
        );

        final success = await rewardService.deductCurrencyForPurchase(
          db: fakeDb,
          pet: pet,
          item: item,
        );

        expect(success, false);
        expect(fakeDb.rewardLogs.length, 0);
      });
    });
  });
}

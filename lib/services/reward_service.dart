import 'dart:math';

import '../data/database_helper.dart';
import '../models/app_models.dart';
import '../models/currency_models.dart';
import '../models/task_models.dart';

/// 奖励计算结果：学科积分 + 成长币 + 货币名称。
class RewardCalculation {
  final int subjectPoints;
  final int growthCoins;
  final String currencyName;

  const RewardCalculation({
    required this.subjectPoints,
    required this.growthCoins,
    required this.currencyName,
  });
}

/// 统一负责所有货币增减与奖励流水记录。
class RewardService {
  static const String sourceAnswerCorrect = 'answer_correct';
  static const String sourceFocusComplete = 'focus_complete';
  static const String sourceEvolution = 'evolution';
  static const String sourceDailyTask = 'daily_task';
  static const String sourceShopPurchase = 'shop_purchase';
  static const String sourceItemUse = 'item_use';

  /// 基础奖励公式：5 + (grade - 1) ~/ 2，再随机加 0-3。
  static int _baseReward(int grade) {
    final base = 5 + ((grade - 1) ~/ 2);
    final bonus = Random().nextInt(4);
    return base + bonus;
  }

  /// 根据学科计算答题正确奖励。
  static RewardCalculation calculateSubjectReward(String subject, int grade) {
    final points = _baseReward(grade);
    final coins = 2 + (grade ~/ 3);

    if (subject == '语文' || subject == '英语') {
      return RewardCalculation(
        subjectPoints: points,
        growthCoins: coins,
        currencyName: '文科积分',
      );
    } else if (subject == '数学' || subject == '物理') {
      return RewardCalculation(
        subjectPoints: points,
        growthCoins: coins,
        currencyName: '理科积分',
      );
    }

    return RewardCalculation(
      subjectPoints: points ~/ 2,
      growthCoins: coins,
      currencyName: '积分',
    );
  }

  /// 计算专注模式奖励的健康积分。
  static int calculateFocusReward(int minutes) {
    return 3 + (minutes ~/ 10);
  }

  /// 计算每日任务的成长币奖励。
  static int calculateTaskRewardGrowthCoins(TaskType type, int grade) {
    return switch (type) {
      TaskType.answerQuestions => 10 + grade,
      TaskType.focusSession => 15 + grade * 2,
      TaskType.feedPet => 5,
      TaskType.playWithPet => 5,
      TaskType.completeAnyContent => 8,
      TaskType.reduceScreenTime => 20,
    };
  }

  /// 计算每日任务的健康积分奖励。
  static int calculateTaskRewardHealthPoints(TaskType type) {
    return switch (type) {
      TaskType.focusSession => 10,
      TaskType.reduceScreenTime => 15,
      TaskType.feedPet => 5,
      TaskType.playWithPet => 5,
      _ => 0,
    };
  }

  /// 发放货币并写入奖励流水，返回更新后的 PetState。
  Future<PetState> awardCurrency({
    required DatabaseHelper db,
    required String source,
    int growthCoinsDelta = 0,
    int humanitiesPointsDelta = 0,
    int sciencePointsDelta = 0,
    int healthPointsDelta = 0,
    required String description,
  }) async {
    final updated = await db.updatePetCurrencies(
      growthCoinsDelta: growthCoinsDelta,
      humanitiesPointsDelta: humanitiesPointsDelta,
      sciencePointsDelta: sciencePointsDelta,
      healthPointsDelta: healthPointsDelta,
    );

    await db.insertRewardLog(RewardLog(
      source: source,
      growthCoinsDelta: growthCoinsDelta,
      humanitiesPointsDelta: humanitiesPointsDelta,
      sciencePointsDelta: sciencePointsDelta,
      healthPointsDelta: healthPointsDelta,
      description: description,
      createdAt: DateTime.now(),
    ));

    return updated;
  }

  /// 为商店购买扣款，失败返回 false。
  Future<bool> deductCurrencyForPurchase({
    required DatabaseHelper db,
    required PetState pet,
    required ShopItem item,
  }) async {
    if (pet.growthCoins < item.growthCoinsCost) return false;
    if (pet.humanitiesPoints < item.humanitiesPointsCost) return false;
    if (pet.sciencePoints < item.sciencePointsCost) return false;
    if (pet.healthPoints < item.healthPointsCost) return false;

    await db.updatePetCurrencies(
      growthCoinsDelta: -item.growthCoinsCost,
      humanitiesPointsDelta: -item.humanitiesPointsCost,
      sciencePointsDelta: -item.sciencePointsCost,
      healthPointsDelta: -item.healthPointsCost,
    );

    await db.insertRewardLog(RewardLog(
      source: sourceShopPurchase,
      growthCoinsDelta: -item.growthCoinsCost,
      humanitiesPointsDelta: -item.humanitiesPointsCost,
      sciencePointsDelta: -item.sciencePointsCost,
      healthPointsDelta: -item.healthPointsCost,
      description: '购买 ${item.name}',
      createdAt: DateTime.now(),
    ));

    return true;
  }
}

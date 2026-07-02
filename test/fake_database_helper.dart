import 'package:pet_time_lock/data/database_helper.dart';
import 'package:pet_time_lock/models/app_models.dart';
import 'package:pet_time_lock/models/currency_models.dart';
import 'package:pet_time_lock/models/task_models.dart';

/// 用于测试的内存数据库 Fake，避免 sqflite 依赖。
class FakeDatabaseHelper implements DatabaseHelper {
  PetState? _petState;
  final List<ShopItem> _shopItems = [];
  final List<InventoryItem> _inventory = [];
  final List<DailyTask> _dailyTasks = [];
  final List<RewardLog> _rewardLogs = [];
  final List<WrongAnswer> _wrongAnswers = [];

  void seedPetState(PetState pet) => _petState = pet;

  void seedShopItems(List<ShopItem> items) {
    _shopItems.clear();
    _shopItems.addAll(items);
  }

  void seedInventory(List<InventoryItem> items) {
    _inventory.clear();
    _inventory.addAll(items);
  }

  void seedDailyTasks(List<DailyTask> tasks) {
    _dailyTasks.clear();
    _dailyTasks.addAll(tasks);
  }

  List<RewardLog> get rewardLogs => List.unmodifiable(_rewardLogs);

  @override
  Future<PetState?> getPetState() async => _petState;

  @override
  Future<PetState> createPetState(int grade, {String? name}) async {
    _petState = PetState(currentGrade: grade, name: name ?? '小宠');
    return _petState!;
  }

  @override
  Future<int> updatePetState(PetState petState) async {
    _petState = petState.copyWith(
      lastUpdatedAt: DateTime.now(),
      version: petState.version + 1,
    );
    return 1;
  }

  @override
  Future<PetState> updatePetCurrencies({
    required int growthCoinsDelta,
    required int humanitiesPointsDelta,
    required int sciencePointsDelta,
    required int healthPointsDelta,
  }) async {
    if (_petState == null) throw Exception('No pet state');
    _petState = _petState!.copyWith(
      growthCoins: (_petState!.growthCoins + growthCoinsDelta).clamp(0, 999999),
      humanitiesPoints: (_petState!.humanitiesPoints + humanitiesPointsDelta).clamp(0, 999999),
      sciencePoints: (_petState!.sciencePoints + sciencePointsDelta).clamp(0, 999999),
      healthPoints: (_petState!.healthPoints + healthPointsDelta).clamp(0, 999999),
      lastUpdatedAt: DateTime.now(),
    );
    return _petState!;
  }

  @override
  Future<List<ShopItem>> getAllShopItems() async => List.unmodifiable(_shopItems);

  @override
  Future<ShopItem?> getShopItem(String id) async {
    try {
      return _shopItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<InventoryItem>> getAllInventory() async => List.unmodifiable(_inventory);

  @override
  Future<InventoryItem?> getInventoryItem(String itemId) async {
    try {
      return _inventory.firstWhere((item) => item.itemId == itemId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> addOrUpdateInventoryItem(InventoryItem item) async {
    final index = _inventory.indexWhere((i) => i.itemId == item.itemId);
    if (index >= 0) {
      _inventory[index] = item;
    } else {
      _inventory.add(item);
    }
    return 1;
  }

  @override
  Future<int> updateInventoryItem(InventoryItem item) async => addOrUpdateInventoryItem(item);

  @override
  Future<int> deleteInventoryItem(String itemId) async {
    _inventory.removeWhere((item) => item.itemId == itemId);
    return 1;
  }

  @override
  Future<int> insertRewardLog(RewardLog log) async {
    _rewardLogs.add(log);
    return 1;
  }

  @override
  Future<List<RewardLog>> getRewardLogs({int limit = 50}) async {
    return List.unmodifiable(_rewardLogs.take(limit));
  }

  @override
  Future<List<DailyTask>> getDailyTasksForDate(String date) async {
    return _dailyTasks.where((task) => task.assignedDate == date).toList();
  }

  @override
  Future<int> insertOrUpdateDailyTask(DailyTask task) async {
    final index = _dailyTasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _dailyTasks[index] = task;
    } else {
      _dailyTasks.add(task);
    }
    return 1;
  }

  @override
  Future<int> deleteDailyTasksForDate(String date) async {
    _dailyTasks.removeWhere((task) => task.assignedDate == date);
    return 1;
  }

  @override
  Future<int> insertOrUpdateWrongAnswer(WrongAnswer wrong) async {
    final index = _wrongAnswers.indexWhere((w) => w.contentId == wrong.contentId);
    if (index >= 0) {
      final current = _wrongAnswers[index];
      _wrongAnswers[index] = current.copyWith(
        mistakeCount: current.mistakeCount + 1,
        lastMistakeAt: DateTime.now(),
      );
    } else {
      _wrongAnswers.add(wrong);
    }
    return 1;
  }

  @override
  Future<List<WrongAnswer>> getAllWrongAnswers() async {
    return List.unmodifiable(_wrongAnswers);
  }

  @override
  Future<int> getWrongAnswerCountForSubject(String subject) async {
    return _wrongAnswers
        .where((w) => w.subject == subject)
        .fold<int>(0, (sum, w) => sum + w.mistakeCount);
  }

  // 未使用的方法
  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'package:pet_time_lock/data/database_helper.dart';
import 'package:pet_time_lock/models/app_models.dart';
import 'package:pet_time_lock/models/compliance_models.dart';
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
  final List<TimeSlot> _timeSlots = [];
  final List<ViolationLog> _violationLogs = [];
  final Map<String, ComplianceRecord> _complianceRecords = {};
  final Map<String, AppWhitelistEntry> _whitelist = {};

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

  // App Limits
  @override
  Future<List<AppLimit>> getAppLimits() async {
    return List.unmodifiable(_appLimits);
  }

  @override
  Future<int> insertOrUpdateAppLimit(AppLimit limit) async {
    final index = _appLimits.indexWhere((l) => l.packageName == limit.packageName);
    if (index >= 0) {
      _appLimits[index] = limit;
    } else {
      _appLimits.add(limit);
    }
    return 1;
  }

  // Time Slots
  @override
  Future<List<TimeSlot>> getTimeSlots() async => List.unmodifiable(_timeSlots);

  @override
  Future<List<TimeSlot>> getActiveTimeSlots() async =>
      List.unmodifiable(_timeSlots.where((s) => s.isActive));

  @override
  Future<int> insertTimeSlot(TimeSlot slot) async {
    _timeSlots.add(slot);
    return _timeSlots.length;
  }

  @override
  Future<int> updateTimeSlot(TimeSlot slot) async {
    final index = _timeSlots.indexWhere((s) => s.id == slot.id);
    if (index >= 0) _timeSlots[index] = slot;
    return 1;
  }

  @override
  Future<int> deleteTimeSlot(int id) async {
    _timeSlots.removeWhere((s) => s.id == id);
    return 1;
  }

  // Compliance Records
  @override
  Future<ComplianceRecord?> getComplianceRecord(String date, String? packageName) async {
    return _complianceRecords['$date:$packageName'];
  }

  @override
  Future<int> insertOrUpdateComplianceRecord(ComplianceRecord record) async {
    _complianceRecords['${record.date}:${record.packageName}'] = record;
    return 1;
  }

  @override
  Future<List<ComplianceRecord>> getComplianceRecordsForDate(String date) async {
    return _complianceRecords.values.where((r) => r.date == date).toList();
  }

  // Violation Logs
  @override
  Future<int> insertViolationLog(ViolationLog log) async {
    _violationLogs.add(log);
    return _violationLogs.length;
  }

  @override
  Future<List<ViolationLog>> getViolationsForDate(String date) async {
    return _violationLogs.where((v) =>
      DatabaseHelper.formatDate(v.timestamp) == date).toList();
  }

  @override
  Future<int> getViolationCountForDate(String date) async {
    return (await getViolationsForDate(date)).length;
  }

  // Whitelist
  @override
  Future<List<AppWhitelistEntry>> getWhitelist() async =>
      List.unmodifiable(_whitelist.values);

  @override
  Future<bool> isWhitelisted(String packageName) async =>
      _whitelist.containsKey(packageName);

  @override
  Future<int> addWhitelistEntry(AppWhitelistEntry entry) async {
    _whitelist[entry.packageName] = entry;
    return 1;
  }

  @override
  Future<int> removeWhitelistEntry(String packageName) async {
    _whitelist.remove(packageName);
    return 1;
  }

  // Usage Logs
  final List<UsageLog> _usageLogs = [];

  @override
  Future<int> insertUsageLog(UsageLog log) async {
    _usageLogs.add(log);
    return _usageLogs.length;
  }

  @override
  Future<List<UsageLog>> getUsageLogsByDate(String date) async {
    return _usageLogs.where((l) => l.date == date).toList();
  }

  @override
  Future<Map<String, int>> getTodayUsageByPackage() async {
    final today = DatabaseHelper.formatDate(DateTime.now());
    final result = <String, int>{};
    for (final log in _usageLogs.where((l) => l.date == today)) {
      result[log.packageName] = (result[log.packageName] ?? 0) + log.durationSeconds;
    }
    return result;
  }

  // 未使用的方法
  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final List<AppLimit> _appLimits = [];
}

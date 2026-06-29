import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_models.dart';
import '../models/currency_models.dart';
import '../models/task_models.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pet_time_lock.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 迁移旧的 appearance_json，确保是合法 JSON
      final pets = await db.query('pet_state');
      for (final map in pets) {
        final appearanceJson = map['appearance_json'] as String?;
        if (appearanceJson == null || appearanceJson == '{}') {
          final pet = PetState.fromMap(map);
          final updated = pet.copyWithAppearance(const PetAppearance());
          await db.update(
            'pet_state',
            updated.toMap(),
            where: 'id = ?',
            whereArgs: [pet.id],
          );
        }
      }
    }

    if (oldVersion < 3) {
      // 新增货币与积分字段
      await db.execute('ALTER TABLE pet_state ADD COLUMN growth_coins INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE pet_state ADD COLUMN humanities_points INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE pet_state ADD COLUMN science_points INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE pet_state ADD COLUMN health_points INTEGER DEFAULT 0');

      // 扩展 educational_content
      await db.execute('ALTER TABLE educational_content ADD COLUMN time_limit_seconds INTEGER');
      await db.execute('ALTER TABLE educational_content ADD COLUMN question_type TEXT DEFAULT "choice"');

      // 新增商店、背包、任务、奖励日志、错题本表
      await db.execute('''
        CREATE TABLE shop_items (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          icon_emoji TEXT,
          category TEXT,
          growth_coins_cost INTEGER DEFAULT 0,
          humanities_points_cost INTEGER DEFAULT 0,
          science_points_cost INTEGER DEFAULT 0,
          health_points_cost INTEGER DEFAULT 0,
          effect_health INTEGER DEFAULT 0,
          effect_happiness INTEGER DEFAULT 0,
          effect_hunger INTEGER DEFAULT 0,
          effect_knowledge INTEGER DEFAULT 0,
          required_stage INTEGER DEFAULT 0,
          is_consumable INTEGER DEFAULT 1,
          appearance_unlock TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE inventory (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id TEXT NOT NULL UNIQUE,
          quantity INTEGER DEFAULT 1,
          acquired_at TEXT,
          is_equipped INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE daily_tasks (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          task_type TEXT,
          subject TEXT,
          target_count INTEGER,
          current_count INTEGER DEFAULT 0,
          completed INTEGER DEFAULT 0,
          completed_at TEXT,
          reward_growth_coins INTEGER DEFAULT 0,
          reward_health_points INTEGER DEFAULT 0,
          assigned_date TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE reward_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          source TEXT,
          growth_coins_delta INTEGER DEFAULT 0,
          humanities_points_delta INTEGER DEFAULT 0,
          science_points_delta INTEGER DEFAULT 0,
          health_points_delta INTEGER DEFAULT 0,
          description TEXT,
          created_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE wrong_answers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content_id TEXT NOT NULL UNIQUE,
          subject TEXT,
          mistake_count INTEGER DEFAULT 1,
          last_mistake_at TEXT
        )
      ''');

      await _seedShopItems(db);
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pet_state (
        id INTEGER PRIMARY KEY,
        stage INTEGER DEFAULT 0,
        health INTEGER DEFAULT 100,
        happiness INTEGER DEFAULT 100,
        hunger INTEGER DEFAULT 100,
        knowledge INTEGER DEFAULT 0,
        discipline INTEGER DEFAULT 50,
        growth_xp INTEGER DEFAULT 0,
        growth_coins INTEGER DEFAULT 0,
        humanities_points INTEGER DEFAULT 0,
        science_points INTEGER DEFAULT 0,
        health_points INTEGER DEFAULT 0,
        name TEXT,
        appearance_json TEXT DEFAULT '{}',
        current_grade INTEGER NOT NULL,
        created_at TEXT,
        last_updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE app_limits (
        package_name TEXT PRIMARY KEY,
        app_name TEXT,
        category TEXT,
        daily_limit_minutes INTEGER,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE usage_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT,
        start_time TEXT,
        end_time TEXT,
        duration_seconds INTEGER,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE educational_content (
        id TEXT PRIMARY KEY,
        type TEXT,
        title TEXT,
        content TEXT,
        question TEXT,
        options TEXT,
        correct_answer TEXT,
        explanation TEXT,
        grade INTEGER,
        subject TEXT,
        estimated_seconds INTEGER,
        time_limit_seconds INTEGER,
        requires_interaction INTEGER DEFAULT 0,
        question_type TEXT DEFAULT 'choice',
        is_local INTEGER DEFAULT 1,
        is_downloaded INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE user_progress (
        content_id TEXT PRIMARY KEY,
        completed INTEGER DEFAULT 0,
        score INTEGER,
        grade INTEGER,
        last_attempt TEXT,
        time_spent_seconds INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE persuasion_quotes (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        grade INTEGER NOT NULL,
        scene TEXT NOT NULL,
        feedback TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT,
        end_time TEXT,
        planned_duration_minutes INTEGER,
        actual_duration_minutes INTEGER,
        success INTEGER DEFAULT 1,
        pet_xp_gained INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT,
        record_id TEXT,
        operation TEXT,
        payload_json TEXT,
        created_at TEXT,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE shop_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon_emoji TEXT,
        category TEXT,
        growth_coins_cost INTEGER DEFAULT 0,
        humanities_points_cost INTEGER DEFAULT 0,
        science_points_cost INTEGER DEFAULT 0,
        health_points_cost INTEGER DEFAULT 0,
        effect_health INTEGER DEFAULT 0,
        effect_happiness INTEGER DEFAULT 0,
        effect_hunger INTEGER DEFAULT 0,
        effect_knowledge INTEGER DEFAULT 0,
        required_stage INTEGER DEFAULT 0,
        is_consumable INTEGER DEFAULT 1,
        appearance_unlock TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id TEXT NOT NULL UNIQUE,
        quantity INTEGER DEFAULT 1,
        acquired_at TEXT,
        is_equipped INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_tasks (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        task_type TEXT,
        subject TEXT,
        target_count INTEGER,
        current_count INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0,
        completed_at TEXT,
        reward_growth_coins INTEGER DEFAULT 0,
        reward_health_points INTEGER DEFAULT 0,
        assigned_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reward_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT,
        growth_coins_delta INTEGER DEFAULT 0,
        humanities_points_delta INTEGER DEFAULT 0,
        science_points_delta INTEGER DEFAULT 0,
        health_points_delta INTEGER DEFAULT 0,
        description TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE wrong_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id TEXT NOT NULL UNIQUE,
        subject TEXT,
        mistake_count INTEGER DEFAULT 1,
        last_mistake_at TEXT
      )
    ''');

    await _seedData(db);
  }

  Future _seedData(Database db) async {
    final batch = db.batch();

    for (final content in SeedData.educationalContent) {
      batch.insert('educational_content', content.toMap());
    }

    for (final quote in SeedData.persuasionQuotes) {
      batch.insert('persuasion_quotes', quote.toMap());
    }

    await batch.commit(noResult: true);

    await _seedShopItems(db);
  }

  Future _seedShopItems(Database db) async {
    final batch = db.batch();
    for (final item in SeedData.shopItems) {
      batch.insert('shop_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // Pet State
  Future<PetState?> getPetState() async {
    final db = await database;
    final maps = await db.query('pet_state', limit: 1);
    if (maps.isNotEmpty) {
      return PetState.fromMap(maps.first);
    }
    return null;
  }

  Future<PetState> createPetState(int grade, {String? name}) async {
    final db = await database;
    final petState = PetState(currentGrade: grade, name: name ?? '小宠');
    await db.insert('pet_state', petState.toMap());
    return petState;
  }

  Future<int> updatePetState(PetState petState) async {
    final db = await database;
    return await db.update(
      'pet_state',
      petState.copyWith(lastUpdatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [petState.id],
    );
  }

  // Educational Content
  Future<List<EducationalContent>> getEducationalContentByGrade(int grade) async {
    final db = await database;
    final maps = await db.query(
      'educational_content',
      where: 'grade = ?',
      whereArgs: [grade],
    );
    return maps.map((map) => EducationalContent.fromMap(map)).toList();
  }

  Future<EducationalContent?> getEducationalContentById(String id) async {
    final db = await database;
    final maps = await db.query(
      'educational_content',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return EducationalContent.fromMap(maps.first);
    }
    return null;
  }

  Future<EducationalContent?> getRandomContentByGrade(int grade) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT * FROM educational_content WHERE grade = ? ORDER BY RANDOM() LIMIT 1',
      [grade],
    );
    if (maps.isNotEmpty) {
      return EducationalContent.fromMap(maps.first);
    }
    return null;
  }

  Future<List<EducationalContent>> getEducationalContentByGradeAndSubject(
    int grade,
    String subject,
  ) async {
    final db = await database;
    final maps = await db.query(
      'educational_content',
      where: 'grade = ? AND subject = ?',
      whereArgs: [grade, subject],
    );
    return maps.map((map) => EducationalContent.fromMap(map)).toList();
  }

  Future<EducationalContent?> getRandomContentByGradeAndSubject(
    int grade,
    String subject,
  ) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT * FROM educational_content WHERE grade = ? AND subject = ? ORDER BY RANDOM() LIMIT 1',
      [grade, subject],
    );
    if (maps.isNotEmpty) {
      return EducationalContent.fromMap(maps.first);
    }
    return null;
  }

  // Persuasion Quotes
  Future<List<PersuasionQuote>> getPersuasionQuotesByGrade(int grade, String scene) async {
    final db = await database;
    final maps = await db.query(
      'persuasion_quotes',
      where: 'grade = ? AND scene = ?',
      whereArgs: [grade, scene],
    );
    return maps.map((map) => PersuasionQuote.fromMap(map)).toList();
  }

  Future<PersuasionQuote?> getRandomQuote(int grade, String scene) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT * FROM persuasion_quotes WHERE grade = ? AND scene = ? ORDER BY RANDOM() LIMIT 1',
      [grade, scene],
    );
    if (maps.isNotEmpty) {
      return PersuasionQuote.fromMap(maps.first);
    }
    return null;
  }

  // App Limits
  Future<List<AppLimit>> getAppLimits() async {
    final db = await database;
    final maps = await db.query('app_limits');
    return maps.map((map) => AppLimit.fromMap(map)).toList();
  }

  Future<int> insertOrUpdateAppLimit(AppLimit limit) async {
    final db = await database;
    return await db.insert(
      'app_limits',
      limit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Usage Logs
  Future<int> insertUsageLog(UsageLog log) async {
    final db = await database;
    return await db.insert('usage_logs', log.toMap());
  }

  Future<List<UsageLog>> getUsageLogsByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'usage_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.map((map) => UsageLog.fromMap(map)).toList();
  }

  Future<Map<String, int>> getTodayUsageByPackage() async {
    final db = await database;
    final today = formatDate(DateTime.now());
    final maps = await db.rawQuery('''
      SELECT package_name, SUM(duration_seconds) as total_seconds
      FROM usage_logs
      WHERE date = ?
      GROUP BY package_name
    ''', [today]);

    final result = <String, int>{};
    for (final map in maps) {
      result[map['package_name'] as String] = map['total_seconds'] as int? ?? 0;
    }
    return result;
  }

  // Focus Sessions
  Future<int> insertFocusSession(FocusSession session) async {
    final db = await database;
    return await db.insert('focus_sessions', session.toMap());
  }

  Future<int> updateFocusSession(FocusSession session) async {
    final db = await database;
    return await db.update(
      'focus_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<FocusSession>> getFocusSessionsByDate(String date) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT * FROM focus_sessions
      WHERE date(start_time) = ?
      ORDER BY start_time DESC
    ''', [date]);
    return maps.map((map) => FocusSession.fromMap(map)).toList();
  }

  // User Progress
  Future<Map<String, UserProgress>> getAllProgress() async {
    final db = await database;
    final maps = await db.query('user_progress');
    return {
      for (final map in maps) map['content_id'] as String: UserProgress.fromMap(map)
    };
  }

  Future<UserProgress?> getProgress(String contentId) async {
    final db = await database;
    final maps = await db.query(
      'user_progress',
      where: 'content_id = ?',
      whereArgs: [contentId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserProgress.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertOrUpdateProgress(UserProgress progress) async {
    final db = await database;
    return await db.insert(
      'user_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getCompletedContentCountToday() async {
    final db = await database;
    final today = formatDate(DateTime.now());
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM user_progress
      WHERE completed = 1 AND date(last_attempt) = ?
    ''', [today]);
    return (result.first['count'] as int?) ?? 0;
  }

  // Currency atomic update
  Future<PetState> updatePetCurrencies({
    required int growthCoinsDelta,
    required int humanitiesPointsDelta,
    required int sciencePointsDelta,
    required int healthPointsDelta,
  }) async {
    final pet = await getPetState();
    if (pet == null) throw Exception('No pet state found');

    final updated = pet.copyWith(
      growthCoins: (pet.growthCoins + growthCoinsDelta).clamp(0, 999999),
      humanitiesPoints: (pet.humanitiesPoints + humanitiesPointsDelta).clamp(0, 999999),
      sciencePoints: (pet.sciencePoints + sciencePointsDelta).clamp(0, 999999),
      healthPoints: (pet.healthPoints + healthPointsDelta).clamp(0, 999999),
      lastUpdatedAt: DateTime.now(),
    );
    await updatePetState(updated);
    return updated;
  }

  // Shop Items
  Future<List<ShopItem>> getAllShopItems() async {
    final db = await database;
    final maps = await db.query('shop_items', orderBy: 'category, required_stage');
    return maps.map((m) => ShopItem.fromMap(m)).toList();
  }

  Future<ShopItem?> getShopItem(String id) async {
    final db = await database;
    final maps = await db.query(
      'shop_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return ShopItem.fromMap(maps.first);
    return null;
  }

  // Inventory
  Future<List<InventoryItem>> getAllInventory() async {
    final db = await database;
    final maps = await db.query('inventory', orderBy: 'acquired_at DESC');
    return maps.map((m) => InventoryItem.fromMap(m)).toList();
  }

  Future<InventoryItem?> getInventoryItem(String itemId) async {
    final db = await database;
    final maps = await db.query(
      'inventory',
      where: 'item_id = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    if (maps.isNotEmpty) return InventoryItem.fromMap(maps.first);
    return null;
  }

  Future<int> addOrUpdateInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.insert(
      'inventory',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.update(
      'inventory',
      item.toMap(),
      where: 'item_id = ?',
      whereArgs: [item.itemId],
    );
  }

  Future<int> deleteInventoryItem(String itemId) async {
    final db = await database;
    return await db.delete(
      'inventory',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  // Reward Logs
  Future<int> insertRewardLog(RewardLog log) async {
    final db = await database;
    return await db.insert('reward_logs', log.toMap());
  }

  Future<List<RewardLog>> getRewardLogs({int limit = 50}) async {
    final db = await database;
    final maps = await db.query(
      'reward_logs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((m) => RewardLog.fromMap(m)).toList();
  }

  // Daily Tasks
  Future<List<DailyTask>> getDailyTasksForDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'daily_tasks',
      where: 'assigned_date = ?',
      whereArgs: [date],
      orderBy: 'completed, id',
    );
    return maps.map((m) => DailyTask.fromMap(m)).toList();
  }

  Future<int> insertOrUpdateDailyTask(DailyTask task) async {
    final db = await database;
    return await db.insert(
      'daily_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteDailyTasksForDate(String date) async {
    final db = await database;
    return await db.delete(
      'daily_tasks',
      where: 'assigned_date = ?',
      whereArgs: [date],
    );
  }

  // Wrong Answers
  Future<int> insertOrUpdateWrongAnswer(WrongAnswer wrong) async {
    final db = await database;
    final existing = await db.query(
      'wrong_answers',
      where: 'content_id = ?',
      whereArgs: [wrong.contentId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final current = WrongAnswer.fromMap(existing.first);
      final updated = current.copyWith(
        mistakeCount: current.mistakeCount + 1,
        lastMistakeAt: DateTime.now(),
      );
      return await db.update(
        'wrong_answers',
        updated.toMap(),
        where: 'content_id = ?',
        whereArgs: [wrong.contentId],
      );
    }
    return await db.insert('wrong_answers', wrong.toMap());
  }

  Future<List<WrongAnswer>> getAllWrongAnswers() async {
    final db = await database;
    final maps = await db.query(
      'wrong_answers',
      orderBy: 'last_mistake_at DESC',
    );
    return maps.map((m) => WrongAnswer.fromMap(m)).toList();
  }

  Future<int> getWrongAnswerCountForSubject(String subject) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(mistake_count) as total FROM wrong_answers WHERE subject = ?',
      [subject],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future close() async {
    (await database).close();
  }
}

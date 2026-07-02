import 'dart:convert';

enum InteractionType {
  feed, // 喂食
  play, // 玩耍
  pet, // 抚摸
  focus, // 专注
  learn, // 学习
}

class PetAppearance {
  final int unlockedColorIndex;
  final int unlockedFaceIndex;
  final List<String> unlockedAccessories;
  final int evolutionCount;

  const PetAppearance({
    this.unlockedColorIndex = 0,
    this.unlockedFaceIndex = 0,
    this.unlockedAccessories = const [],
    this.evolutionCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'unlocked_color_index': unlockedColorIndex,
      'unlocked_face_index': unlockedFaceIndex,
      'unlocked_accessories': unlockedAccessories,
      'evolution_count': evolutionCount,
    };
  }

  factory PetAppearance.fromMap(Map<String, dynamic> map) {
    return PetAppearance(
      unlockedColorIndex: map['unlocked_color_index'] as int? ?? 0,
      unlockedFaceIndex: map['unlocked_face_index'] as int? ?? 0,
      unlockedAccessories: map['unlocked_accessories'] == null
          ? []
          : List<String>.from(map['unlocked_accessories'] as List<dynamic>),
      evolutionCount: map['evolution_count'] as int? ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PetAppearance.fromJson(String source) {
    try {
      final map = jsonDecode(source) as Map<String, dynamic>;
      return PetAppearance.fromMap(map);
    } catch (_) {
      return const PetAppearance();
    }
  }

  PetAppearance copyWith({
    int? unlockedColorIndex,
    int? unlockedFaceIndex,
    List<String>? unlockedAccessories,
    int? evolutionCount,
  }) {
    return PetAppearance(
      unlockedColorIndex: unlockedColorIndex ?? this.unlockedColorIndex,
      unlockedFaceIndex: unlockedFaceIndex ?? this.unlockedFaceIndex,
      unlockedAccessories: unlockedAccessories ?? this.unlockedAccessories,
      evolutionCount: evolutionCount ?? this.evolutionCount,
    );
  }
}

class PetState {
  final int id;
  final int stage;
  final int health;
  final int happiness;
  final int hunger;
  final int knowledge;
  final int discipline;
  final int growthXp;
  final int growthCoins;
  final int humanitiesPoints;
  final int sciencePoints;
  final int healthPoints;
  final String? name;
  final String appearanceJson;
  final int currentGrade;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  /// Monotonically increasing version used to keep the floating overlay pet
  /// in sync with the main app across two Flutter engines. Each mutation
  /// increments this value.
  final int version;

  PetState({
    this.id = 1,
    this.stage = 0,
    this.health = 100,
    this.happiness = 100,
    this.hunger = 100,
    this.knowledge = 0,
    this.discipline = 50,
    this.growthXp = 0,
    this.growthCoins = 0,
    this.humanitiesPoints = 0,
    this.sciencePoints = 0,
    this.healthPoints = 0,
    this.name,
    this.appearanceJson = '{}',
    this.currentGrade = 1,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    this.version = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUpdatedAt = lastUpdatedAt ?? DateTime.now();

  PetState copyWith({
    int? id,
    int? stage,
    int? health,
    int? happiness,
    int? hunger,
    int? knowledge,
    int? discipline,
    int? growthXp,
    int? growthCoins,
    int? humanitiesPoints,
    int? sciencePoints,
    int? healthPoints,
    String? name,
    String? appearanceJson,
    int? currentGrade,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    int? version,
  }) {
    return PetState(
      id: id ?? this.id,
      stage: stage ?? this.stage,
      health: health ?? this.health,
      happiness: happiness ?? this.happiness,
      hunger: hunger ?? this.hunger,
      knowledge: knowledge ?? this.knowledge,
      discipline: discipline ?? this.discipline,
      growthXp: growthXp ?? this.growthXp,
      growthCoins: growthCoins ?? this.growthCoins,
      humanitiesPoints: humanitiesPoints ?? this.humanitiesPoints,
      sciencePoints: sciencePoints ?? this.sciencePoints,
      healthPoints: healthPoints ?? this.healthPoints,
      name: name ?? this.name,
      appearanceJson: appearanceJson ?? this.appearanceJson,
      currentGrade: currentGrade ?? this.currentGrade,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stage': stage,
      'health': health,
      'happiness': happiness,
      'hunger': hunger,
      'knowledge': knowledge,
      'discipline': discipline,
      'growth_xp': growthXp,
      'growth_coins': growthCoins,
      'humanities_points': humanitiesPoints,
      'science_points': sciencePoints,
      'health_points': healthPoints,
      'name': name,
      'appearance_json': appearanceJson,
      'current_grade': currentGrade,
      'created_at': createdAt.toIso8601String(),
      'last_updated_at': lastUpdatedAt.toIso8601String(),
      'version': version,
    };
  }

  factory PetState.fromMap(Map<String, dynamic> map) {
    return PetState(
      id: map['id'] as int? ?? 1,
      stage: map['stage'] as int? ?? 0,
      health: map['health'] as int? ?? 100,
      happiness: map['happiness'] as int? ?? 100,
      hunger: map['hunger'] as int? ?? 100,
      knowledge: map['knowledge'] as int? ?? 0,
      discipline: map['discipline'] as int? ?? 50,
      growthXp: map['growth_xp'] as int? ?? 0,
      growthCoins: map['growth_coins'] as int? ?? 0,
      humanitiesPoints: map['humanities_points'] as int? ?? 0,
      sciencePoints: map['science_points'] as int? ?? 0,
      healthPoints: map['health_points'] as int? ?? 0,
      name: map['name'] as String?,
      appearanceJson: map['appearance_json'] as String? ?? '{}',
      currentGrade: map['current_grade'] as int? ?? 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      lastUpdatedAt: DateTime.tryParse(map['last_updated_at'] as String? ?? '') ?? DateTime.now(),
      version: map['version'] as int? ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PetState.fromJson(String source) => PetState.fromMap(jsonDecode(source));

  PetAppearance get appearance => PetAppearance.fromJson(appearanceJson);

  PetState copyWithAppearance(PetAppearance appearance) =>
      copyWith(appearanceJson: appearance.toJson());
}

class InteractionResult {
  final bool success;
  final String message;
  final InteractionType type;
  final bool didEvolve;
  final int newStage;

  const InteractionResult({
    required this.success,
    required this.message,
    required this.type,
    this.didEvolve = false,
    this.newStage = 0,
  });
}

enum ContentType { poem, english, math, physics }

enum QuestionType { choice, fillBlank, recitation }

class EducationalContent {
  final String id;
  final ContentType type;
  final String title;
  final String content;
  final String? question;
  final List<String>? options;
  final String? correctAnswer;
  final String? explanation;
  final int grade;
  final String subject;
  final int estimatedSeconds;
  final int? timeLimitSeconds;
  final bool requiresInteraction;
  final QuestionType questionType;

  const EducationalContent({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.question,
    this.options,
    this.correctAnswer,
    this.explanation,
    required this.grade,
    required this.subject,
    this.estimatedSeconds = 30,
    this.timeLimitSeconds,
    this.requiresInteraction = false,
    this.questionType = QuestionType.choice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'content': content,
      'question': question,
      'options': options == null ? null : jsonEncode(options),
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'grade': grade,
      'subject': subject,
      'estimated_seconds': estimatedSeconds,
      'time_limit_seconds': timeLimitSeconds,
      'requires_interaction': requiresInteraction ? 1 : 0,
      'question_type': questionType.name,
    };
  }

  factory EducationalContent.fromMap(Map<String, dynamic> map) {
    return EducationalContent(
      id: map['id'] as String,
      type: ContentType.values.byName(map['type'] as String),
      title: map['title'] as String,
      content: map['content'] as String,
      question: map['question'] as String?,
      options: map['options'] == null
          ? null
          : List<String>.from(jsonDecode(map['options'] as String)),
      correctAnswer: map['correct_answer'] as String?,
      explanation: map['explanation'] as String?,
      grade: map['grade'] as int,
      subject: map['subject'] as String,
      estimatedSeconds: map['estimated_seconds'] as int? ?? 30,
      timeLimitSeconds: map['time_limit_seconds'] as int?,
      requiresInteraction: (map['requires_interaction'] as int? ?? 0) == 1,
      questionType: map['question_type'] == null
          ? QuestionType.choice
          : QuestionType.values.byName(map['question_type'] as String),
    );
  }
}

class PersuasionQuote {
  final String id;
  final String content;
  final QuoteType type;
  final int grade;
  final String scene;
  final String feedback;

  const PersuasionQuote({
    required this.id,
    required this.content,
    required this.type,
    required this.grade,
    required this.scene,
    required this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'grade': grade,
      'scene': scene,
      'feedback': feedback,
    };
  }

  factory PersuasionQuote.fromMap(Map<String, dynamic> map) {
    return PersuasionQuote(
      id: map['id'] as String,
      content: map['content'] as String,
      type: QuoteType.values.byName(map['type'] as String),
      grade: map['grade'] as int,
      scene: map['scene'] as String,
      feedback: map['feedback'] as String,
    );
  }
}

enum QuoteType { poem, english }

class UserProgress {
  final String contentId;
  final bool completed;
  final int? score;
  final int attempts;
  final DateTime? lastAttemptAt;
  final int timeSpentSeconds;

  const UserProgress({
    required this.contentId,
    this.completed = false,
    this.score,
    this.attempts = 0,
    this.lastAttemptAt,
    this.timeSpentSeconds = 0,
  });

  UserProgress copyWith({
    bool? completed,
    int? score,
    int? attempts,
    DateTime? lastAttemptAt,
    int? timeSpentSeconds,
  }) {
    return UserProgress(
      contentId: contentId,
      completed: completed ?? this.completed,
      score: score ?? this.score,
      attempts: attempts ?? this.attempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content_id': contentId,
      'completed': completed ? 1 : 0,
      'score': score,
      'attempts': attempts,
      'last_attempt': lastAttemptAt?.toIso8601String(),
      'time_spent_seconds': timeSpentSeconds,
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      contentId: map['content_id'] as String,
      completed: (map['completed'] as int? ?? 0) == 1,
      score: map['score'] as int?,
      attempts: map['attempts'] as int? ?? 0,
      lastAttemptAt: map['last_attempt'] == null
          ? null
          : DateTime.parse(map['last_attempt'] as String),
      timeSpentSeconds: map['time_spent_seconds'] as int? ?? 0,
    );
  }
}

class AppLimit {
  final String packageName;
  final String appName;
  final String category;
  final int dailyLimitMinutes;
  final bool isActive;

  const AppLimit({
    required this.packageName,
    required this.appName,
    this.category = 'entertainment',
    required this.dailyLimitMinutes,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'package_name': packageName,
      'app_name': appName,
      'category': category,
      'daily_limit_minutes': dailyLimitMinutes,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory AppLimit.fromMap(Map<String, dynamic> map) {
    return AppLimit(
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      category: map['category'] as String? ?? 'entertainment',
      dailyLimitMinutes: map['daily_limit_minutes'] as int,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}

class UsageLog {
  final int? id;
  final String packageName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final String date;

  UsageLog({
    this.id,
    required this.packageName,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'package_name': packageName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'date': date,
    };
  }

  factory UsageLog.fromMap(Map<String, dynamic> map) {
    return UsageLog(
      id: map['id'] as int?,
      packageName: map['package_name'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] == null ? null : DateTime.parse(map['end_time'] as String),
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      date: map['date'] as String,
    );
  }
}

class FocusSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int plannedDurationMinutes;
  final int? actualDurationMinutes;
  final bool success;
  final int petXpGained;

  FocusSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.plannedDurationMinutes,
    this.actualDurationMinutes,
    this.success = true,
    this.petXpGained = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'planned_duration_minutes': plannedDurationMinutes,
      'actual_duration_minutes': actualDurationMinutes,
      'success': success ? 1 : 0,
      'pet_xp_gained': petXpGained,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] == null ? null : DateTime.parse(map['end_time'] as String),
      plannedDurationMinutes: map['planned_duration_minutes'] as int,
      actualDurationMinutes: map['actual_duration_minutes'] as int?,
      success: (map['success'] as int? ?? 1) == 1,
      petXpGained: map['pet_xp_gained'] as int? ?? 0,
    );
  }
}

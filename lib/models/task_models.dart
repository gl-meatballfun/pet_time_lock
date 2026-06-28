enum TaskType {
  answerQuestions, // 答题
  focusSession, // 专注模式
  feedPet, // 喂食
  playWithPet, // 玩耍
  completeAnyContent, // 完成任意学习内容
  reduceScreenTime, // 减少屏幕使用时间
}

class DailyTask {
  final String id;
  final String title;
  final String description;
  final TaskType taskType;
  final String? subject; // 用于 answerQuestions 类型
  final int targetCount;
  final int currentCount;
  final bool completed;
  final DateTime? completedAt;
  final int rewardGrowthCoins;
  final int rewardHealthPoints;
  final String assignedDate;

  const DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    this.subject,
    required this.targetCount,
    this.currentCount = 0,
    this.completed = false,
    this.completedAt,
    this.rewardGrowthCoins = 0,
    this.rewardHealthPoints = 0,
    required this.assignedDate,
  });

  DailyTask copyWith({
    int? currentCount,
    bool? completed,
    DateTime? completedAt,
  }) {
    return DailyTask(
      id: id,
      title: title,
      description: description,
      taskType: taskType,
      subject: subject,
      targetCount: targetCount,
      currentCount: currentCount ?? this.currentCount,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      rewardGrowthCoins: rewardGrowthCoins,
      rewardHealthPoints: rewardHealthPoints,
      assignedDate: assignedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'task_type': taskType.name,
      'subject': subject,
      'target_count': targetCount,
      'current_count': currentCount,
      'completed': completed ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'reward_growth_coins': rewardGrowthCoins,
      'reward_health_points': rewardHealthPoints,
      'assigned_date': assignedDate,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      taskType: TaskType.values.byName(map['task_type'] as String),
      subject: map['subject'] as String?,
      targetCount: map['target_count'] as int,
      currentCount: map['current_count'] as int? ?? 0,
      completed: (map['completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
      rewardGrowthCoins: map['reward_growth_coins'] as int? ?? 0,
      rewardHealthPoints: map['reward_health_points'] as int? ?? 0,
      assignedDate: map['assigned_date'] as String,
    );
  }
}

class WrongAnswer {
  final int? id;
  final String contentId;
  final String subject;
  final int mistakeCount;
  final DateTime lastMistakeAt;

  const WrongAnswer({
    this.id,
    required this.contentId,
    required this.subject,
    this.mistakeCount = 1,
    required this.lastMistakeAt,
  });

  WrongAnswer copyWith({
    int? mistakeCount,
    DateTime? lastMistakeAt,
  }) {
    return WrongAnswer(
      id: id,
      contentId: contentId,
      subject: subject,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      lastMistakeAt: lastMistakeAt ?? this.lastMistakeAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content_id': contentId,
      'subject': subject,
      'mistake_count': mistakeCount,
      'last_mistake_at': lastMistakeAt.toIso8601String(),
    };
  }

  factory WrongAnswer.fromMap(Map<String, dynamic> map) {
    return WrongAnswer(
      id: map['id'] as int?,
      contentId: map['content_id'] as String,
      subject: map['subject'] as String,
      mistakeCount: map['mistake_count'] as int? ?? 1,
      lastMistakeAt: DateTime.parse(map['last_mistake_at'] as String),
    );
  }
}

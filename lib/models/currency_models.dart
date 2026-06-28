enum ShopItemCategory {
  food, // 食物
  toy, // 玩具
  medicine, // 药品
  accessory, // 装饰
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final String iconEmoji;
  final ShopItemCategory category;
  final int growthCoinsCost;
  final int humanitiesPointsCost;
  final int sciencePointsCost;
  final int healthPointsCost;
  final int effectHealth;
  final int effectHappiness;
  final int effectHunger;
  final int effectKnowledge;
  final int requiredStage;
  final bool isConsumable;
  final String? appearanceUnlock;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.category,
    this.growthCoinsCost = 0,
    this.humanitiesPointsCost = 0,
    this.sciencePointsCost = 0,
    this.healthPointsCost = 0,
    this.effectHealth = 0,
    this.effectHappiness = 0,
    this.effectHunger = 0,
    this.effectKnowledge = 0,
    this.requiredStage = 0,
    this.isConsumable = true,
    this.appearanceUnlock,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_emoji': iconEmoji,
      'category': category.name,
      'growth_coins_cost': growthCoinsCost,
      'humanities_points_cost': humanitiesPointsCost,
      'science_points_cost': sciencePointsCost,
      'health_points_cost': healthPointsCost,
      'effect_health': effectHealth,
      'effect_happiness': effectHappiness,
      'effect_hunger': effectHunger,
      'effect_knowledge': effectKnowledge,
      'required_stage': requiredStage,
      'is_consumable': isConsumable ? 1 : 0,
      'appearance_unlock': appearanceUnlock,
    };
  }

  factory ShopItem.fromMap(Map<String, dynamic> map) {
    return ShopItem(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      iconEmoji: map['icon_emoji'] as String,
      category: ShopItemCategory.values.byName(map['category'] as String),
      growthCoinsCost: map['growth_coins_cost'] as int? ?? 0,
      humanitiesPointsCost: map['humanities_points_cost'] as int? ?? 0,
      sciencePointsCost: map['science_points_cost'] as int? ?? 0,
      healthPointsCost: map['health_points_cost'] as int? ?? 0,
      effectHealth: map['effect_health'] as int? ?? 0,
      effectHappiness: map['effect_happiness'] as int? ?? 0,
      effectHunger: map['effect_hunger'] as int? ?? 0,
      effectKnowledge: map['effect_knowledge'] as int? ?? 0,
      requiredStage: map['required_stage'] as int? ?? 0,
      isConsumable: (map['is_consumable'] as int? ?? 1) == 1,
      appearanceUnlock: map['appearance_unlock'] as String?,
    );
  }
}

class InventoryItem {
  final String itemId;
  final int quantity;
  final DateTime acquiredAt;
  final bool isEquipped;

  const InventoryItem({
    required this.itemId,
    this.quantity = 1,
    required this.acquiredAt,
    this.isEquipped = false,
  });

  InventoryItem copyWith({
    int? quantity,
    DateTime? acquiredAt,
    bool? isEquipped,
  }) {
    return InventoryItem(
      itemId: itemId,
      quantity: quantity ?? this.quantity,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      isEquipped: isEquipped ?? this.isEquipped,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'quantity': quantity,
      'acquired_at': acquiredAt.toIso8601String(),
      'is_equipped': isEquipped ? 1 : 0,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      itemId: map['item_id'] as String,
      quantity: map['quantity'] as int? ?? 1,
      acquiredAt: DateTime.parse(map['acquired_at'] as String),
      isEquipped: (map['is_equipped'] as int? ?? 0) == 1,
    );
  }
}

class RewardLog {
  final int? id;
  final String source;
  final int growthCoinsDelta;
  final int humanitiesPointsDelta;
  final int sciencePointsDelta;
  final int healthPointsDelta;
  final String description;
  final DateTime createdAt;

  const RewardLog({
    this.id,
    required this.source,
    this.growthCoinsDelta = 0,
    this.humanitiesPointsDelta = 0,
    this.sciencePointsDelta = 0,
    this.healthPointsDelta = 0,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source': source,
      'growth_coins_delta': growthCoinsDelta,
      'humanities_points_delta': humanitiesPointsDelta,
      'science_points_delta': sciencePointsDelta,
      'health_points_delta': healthPointsDelta,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RewardLog.fromMap(Map<String, dynamic> map) {
    return RewardLog(
      id: map['id'] as int?,
      source: map['source'] as String,
      growthCoinsDelta: map['growth_coins_delta'] as int? ?? 0,
      humanitiesPointsDelta: map['humanities_points_delta'] as int? ?? 0,
      sciencePointsDelta: map['science_points_delta'] as int? ?? 0,
      healthPointsDelta: map['health_points_delta'] as int? ?? 0,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

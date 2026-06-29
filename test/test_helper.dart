import 'package:mocktail/mocktail.dart';
import 'package:pet_time_lock/models/app_models.dart';
import 'package:pet_time_lock/models/currency_models.dart';
import 'package:pet_time_lock/models/task_models.dart';

void registerAllFallbackValues() {
  final now = DateTime.now();
  registerFallbackValue(PetState(currentGrade: 1));
  registerFallbackValue(const PetAppearance());
  registerFallbackValue(const ShopItem(
    id: 'fallback',
    name: '',
    description: '',
    iconEmoji: '',
    category: ShopItemCategory.food,
  ));
  registerFallbackValue(InventoryItem(
    itemId: 'fallback',
    acquiredAt: now,
  ));
  registerFallbackValue(RewardLog(
    source: 'fallback',
    description: '',
    createdAt: now,
  ));
  registerFallbackValue(const DailyTask(
    id: 'fallback',
    title: '',
    description: '',
    taskType: TaskType.feedPet,
    targetCount: 1,
    assignedDate: '',
  ));
  registerFallbackValue(WrongAnswer(
    contentId: 'fallback',
    subject: '',
    lastMistakeAt: now,
  ));
  registerFallbackValue(const InteractionResult(
    success: true,
    message: '',
    type: InteractionType.pet,
  ));
}

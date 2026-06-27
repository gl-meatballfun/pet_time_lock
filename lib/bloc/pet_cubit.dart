import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../models/app_models.dart';

part 'pet_state.dart';

class InteractionCooldown {
  DateTime? lastFedAt;
  DateTime? lastPlayedAt;
  DateTime? lastPetAt;

  bool canFeed({Duration cooldown = const Duration(minutes: 5)}) =>
      _canAct(lastFedAt, cooldown);

  bool canPlay({Duration cooldown = const Duration(minutes: 3)}) =>
      _canAct(lastPlayedAt, cooldown);

  bool canPet({Duration cooldown = const Duration(seconds: 10)}) =>
      _canAct(lastPetAt, cooldown);

  bool _canAct(DateTime? last, Duration cooldown) {
    if (last == null) return true;
    return DateTime.now().difference(last) >= cooldown;
  }

  String remainingFeedCooldown() =>
      _remaining(lastFedAt, const Duration(minutes: 5));

  String remainingPlayCooldown() =>
      _remaining(lastPlayedAt, const Duration(minutes: 3));

  String remainingPetCooldown() =>
      _remaining(lastPetAt, const Duration(seconds: 10));

  String _remaining(DateTime? last, Duration cooldown) {
    if (last == null) return '';
    final remaining = cooldown - DateTime.now().difference(last);
    if (remaining.inSeconds <= 0) return '';
    if (remaining.inSeconds < 60) return '${remaining.inSeconds} 秒';
    return '${remaining.inMinutes + 1} 分钟';
  }

  void recordFeed() => lastFedAt = DateTime.now();
  void recordPlay() => lastPlayedAt = DateTime.now();
  void recordPet() => lastPetAt = DateTime.now();
}

class PetCubit extends Cubit<PetManagerState> {
  final DatabaseHelper _db;
  final SharedPreferences _prefs;
  final InteractionCooldown _cooldown = InteractionCooldown();

  PetCubit(this._db, this._prefs) : super(const PetManagerState()) {
    _init();
  }

  Future _init() async {
    final grade = _prefs.getInt('selected_grade') ?? 0;
    if (grade > 0) {
      await loadPetState(grade);
    } else {
      emit(state.copyWith(status: PetStatus.needsGradeSelection));
    }
  }

  Future loadPetState(int grade) async {
    emit(state.copyWith(status: PetStatus.loading));
    try {
      PetState? petState = await _db.getPetState();
      if (petState == null) {
        petState = await _db.createPetState(grade);
      } else if (petState.currentGrade != grade) {
        petState = petState.copyWith(currentGrade: grade);
        await _db.updatePetState(petState);
      }

      // Apply time-based decay when app opens
      final now = DateTime.now();
      final updatedPet = _applyDecay(petState, now);
      await _db.updatePetState(updatedPet);

      emit(state.copyWith(
        status: PetStatus.loaded,
        petState: updatedPet,
      ));
    } catch (e) {
      emit(state.copyWith(status: PetStatus.error, errorMessage: e.toString()));
    }
  }

  Future selectGrade(int grade, {String? petName}) async {
    await _prefs.setInt('selected_grade', grade);
    await loadPetState(grade);
  }

  PetState _applyDecay(PetState pet, DateTime now) {
    final lastUpdated = pet.lastUpdatedAt;
    final diff = now.difference(lastUpdated);
    final hours = diff.inHours;

    if (hours <= 0) return pet;

    // Health decays 5 points every 2 hours
    final healthDecay = (hours / 2).floor() * 5;
    // Happiness decays 2 points every hour
    final happinessDecay = hours * 2;
    // Hunger decays 5 points every 30 minutes
    final hungerDecay = (hours * 2) * 5;

    return pet.copyWith(
      health: _clamp(pet.health - healthDecay),
      happiness: _clamp(pet.happiness - happinessDecay),
      hunger: _clamp(pet.hunger - hungerDecay),
      lastUpdatedAt: now,
    );
  }

  Future interactWithPet({
    int happinessDelta = 5,
    int knowledgeDelta = 0,
    int hungerDelta = 0,
    int disciplineDelta = 0,
    int xpDelta = 0,
  }) async {
    if (state.petState == null) return;

    final updated = state.petState!.copyWith(
      happiness: _clamp(state.petState!.happiness + happinessDelta),
      knowledge: _clamp(state.petState!.knowledge + knowledgeDelta, max: 10000),
      hunger: _clamp(state.petState!.hunger + hungerDelta),
      discipline: _clamp(state.petState!.discipline + disciplineDelta),
      growthXp: state.petState!.growthXp + xpDelta,
      lastUpdatedAt: DateTime.now(),
    );

    await _applyAndEmit(
      updated,
      successMessage: '',
      type: InteractionType.pet,
    );
  }

  Future<InteractionResult> feedPet() async {
    final pet = state.petState;
    if (pet == null) {
      return const InteractionResult(
        success: false,
        message: '宠物状态异常',
        type: InteractionType.feed,
      );
    }
    if (pet.hunger >= 100) {
      return const InteractionResult(
        success: false,
        message: '宠物已经饱啦！',
        type: InteractionType.feed,
      );
    }
    if (!_cooldown.canFeed()) {
      return InteractionResult(
        success: false,
        message: '喂食太频繁啦，请等待 ${_cooldown.remainingFeedCooldown()}',
        type: InteractionType.feed,
      );
    }

    _cooldown.recordFeed();
    final updated = pet.copyWith(
      hunger: _clamp(pet.hunger + 20),
      health: _clamp(pet.health + 5),
      happiness: _clamp(pet.happiness + 5),
      growthXp: pet.growthXp + 2,
      lastUpdatedAt: DateTime.now(),
    );
    return _applyAndEmit(
      updated,
      successMessage: '喂食成功！宠物很开心~',
      type: InteractionType.feed,
    );
  }

  Future<InteractionResult> playWithPet() async {
    final pet = state.petState;
    if (pet == null) {
      return const InteractionResult(
        success: false,
        message: '宠物状态异常',
        type: InteractionType.play,
      );
    }
    if (pet.hunger < 20) {
      return const InteractionResult(
        success: false,
        message: '宠物太饿了，先喂点东西吧~',
        type: InteractionType.play,
      );
    }
    if (pet.health < 20) {
      return const InteractionResult(
        success: false,
        message: '宠物太累了，需要休息~',
        type: InteractionType.play,
      );
    }
    if (!_cooldown.canPlay()) {
      return InteractionResult(
        success: false,
        message: '玩耍太频繁啦，请等待 ${_cooldown.remainingPlayCooldown()}',
        type: InteractionType.play,
      );
    }

    _cooldown.recordPlay();
    final updated = pet.copyWith(
      happiness: _clamp(pet.happiness + 25),
      hunger: _clamp(pet.hunger - 10),
      health: _clamp(pet.health - 5),
      growthXp: pet.growthXp + 5,
      lastUpdatedAt: DateTime.now(),
    );
    return _applyAndEmit(
      updated,
      successMessage: '玩耍很开心！宠物心情变好了~',
      type: InteractionType.play,
    );
  }

  Future<InteractionResult> petThePet() async {
    final pet = state.petState;
    if (pet == null) {
      return const InteractionResult(
        success: false,
        message: '宠物状态异常',
        type: InteractionType.pet,
      );
    }
    if (!_cooldown.canPet()) {
      return InteractionResult(
        success: false,
        message: '抚摸太频繁啦，请等待 ${_cooldown.remainingPetCooldown()}',
        type: InteractionType.pet,
      );
    }

    _cooldown.recordPet();
    final updated = pet.copyWith(
      happiness: _clamp(pet.happiness + 5),
      growthXp: pet.growthXp + 1,
      lastUpdatedAt: DateTime.now(),
    );
    return _applyAndEmit(
      updated,
      successMessage: '宠物感受到了你的关爱~',
      type: InteractionType.pet,
    );
  }

  Future<InteractionResult> completeFocusSession(int minutes) async {
    if (state.petState == null) {
      return const InteractionResult(
        success: false,
        message: '宠物状态异常',
        type: InteractionType.focus,
      );
    }

    final xp = minutes * 2;
    final updated = state.petState!.copyWith(
      happiness: _clamp(state.petState!.happiness + 15),
      knowledge: _clamp(state.petState!.knowledge + 10, max: 10000),
      discipline: _clamp(state.petState!.discipline + 5),
      growthXp: state.petState!.growthXp + xp,
      lastUpdatedAt: DateTime.now(),
    );

    return _applyAndEmit(
      updated,
      successMessage: '专注完成！宠物获得了成长能量~',
      type: InteractionType.focus,
    );
  }

  Future onAppOverLimit() async {
    if (state.petState == null) return;

    final updated = state.petState!.copyWith(
      discipline: _clamp(state.petState!.discipline - 10),
      happiness: _clamp(state.petState!.happiness - 5),
      lastUpdatedAt: DateTime.now(),
    );

    await _db.updatePetState(updated);
    emit(state.copyWith(petState: updated));
  }

  Future<InteractionResult> answerQuestionCorrectly() async {
    final pet = state.petState;
    if (pet == null) {
      return const InteractionResult(
        success: false,
        message: '宠物状态异常',
        type: InteractionType.learn,
      );
    }

    final updated = pet.copyWith(
      hunger: _clamp(pet.hunger + 10),
      knowledge: _clamp(pet.knowledge + 5, max: 10000),
      growthXp: pet.growthXp + 5,
      lastUpdatedAt: DateTime.now(),
    );
    return _applyAndEmit(
      updated,
      successMessage: '回答正确！宠物学到了新知识~',
      type: InteractionType.learn,
    );
  }

  Future<InteractionResult> _applyAndEmit(
    PetState updated, {
    required String successMessage,
    required InteractionType type,
  }) async {
    final evolved = _checkGrowth(updated);
    final didEvolve = evolved.stage != updated.stage;

    await _db.updatePetState(evolved);
    emit(state.copyWith(
      petState: evolved,
      justEvolved: didEvolve,
      previousStage: didEvolve ? updated.stage : null,
    ));
    if (didEvolve) {
      emit(state.copyWith(justEvolved: false, previousStage: null));
    }

    return InteractionResult(
      success: true,
      message: successMessage,
      type: type,
      didEvolve: didEvolve,
      newStage: evolved.stage,
    );
  }

  PetState _checkGrowth(PetState pet) {
    final thresholds = [0, 50, 150, 300, 500];
    int newStage = 0;
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (pet.growthXp >= thresholds[i]) {
        newStage = i;
        break;
      }
    }
    if (newStage > pet.stage) {
      final currentAppearance = pet.appearance;
      const stageAccessories = ['', '🍼', '🎀', '🎓', '👑'];
      final newAccessory = stageAccessories[newStage];
      final updatedAppearance = currentAppearance.copyWith(
        unlockedColorIndex: newStage,
        unlockedFaceIndex: newStage,
        unlockedAccessories: [
          ...currentAppearance.unlockedAccessories,
          if (newAccessory.isNotEmpty) newAccessory,
        ],
        evolutionCount: currentAppearance.evolutionCount + 1,
      );
      return pet.copyWith(
        stage: newStage,
        appearanceJson: updatedAppearance.toJson(),
      );
    }
    return pet;
  }

  int _clamp(int value, {int min = 0, int max = 100}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

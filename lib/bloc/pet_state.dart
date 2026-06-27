part of 'pet_cubit.dart';

enum PetStatus { initial, loading, loaded, needsGradeSelection, error }

class PetManagerState extends Equatable {
  final PetStatus status;
  final PetState? petState;
  final String? errorMessage;
  final bool justEvolved;
  final int? previousStage;

  const PetManagerState({
    this.status = PetStatus.initial,
    this.petState,
    this.errorMessage,
    this.justEvolved = false,
    this.previousStage,
  });

  PetManagerState copyWith({
    PetStatus? status,
    PetState? petState,
    String? errorMessage,
    bool? justEvolved,
    int? previousStage,
  }) {
    return PetManagerState(
      status: status ?? this.status,
      petState: petState ?? this.petState,
      errorMessage: errorMessage ?? this.errorMessage,
      // 默认重置进化标记，除非显式设置
      justEvolved: justEvolved ?? false,
      previousStage: previousStage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        petState,
        errorMessage,
        justEvolved,
        previousStage,
      ];
}

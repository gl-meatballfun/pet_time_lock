part of 'content_cubit.dart';

enum ContentStatus { initial, loading, loaded, showingContent, showingQuote, error }

class ContentState extends Equatable {
  final ContentStatus status;
  final List<EducationalContent> contents;
  final Map<String, UserProgress> progress;
  final EducationalContent? currentContent;
  final PersuasionQuote? currentQuote;
  final int? selectedGrade;
  final String? selectedSubject;
  final String? errorMessage;

  const ContentState({
    this.status = ContentStatus.initial,
    this.contents = const [],
    this.progress = const {},
    this.currentContent,
    this.currentQuote,
    this.selectedGrade,
    this.selectedSubject,
    this.errorMessage,
  });

  ContentState copyWith({
    ContentStatus? status,
    List<EducationalContent>? contents,
    Map<String, UserProgress>? progress,
    EducationalContent? currentContent,
    PersuasionQuote? currentQuote,
    int? selectedGrade,
    String? selectedSubject,
    String? errorMessage,
  }) {
    return ContentState(
      status: status ?? this.status,
      contents: contents ?? this.contents,
      progress: progress ?? this.progress,
      currentContent: currentContent ?? this.currentContent,
      currentQuote: currentQuote ?? this.currentQuote,
      selectedGrade: selectedGrade ?? this.selectedGrade,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    contents,
    progress,
    currentContent,
    currentQuote,
    selectedGrade,
    selectedSubject,
    errorMessage,
  ];
}

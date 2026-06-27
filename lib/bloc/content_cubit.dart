import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/database_helper.dart';
import '../models/app_models.dart';

part 'content_state.dart';

class ContentCubit extends Cubit<ContentState> {
  final DatabaseHelper _db;

  ContentCubit(this._db) : super(const ContentState());

  Future loadContentForGrade(int grade) async {
    emit(state.copyWith(status: ContentStatus.loading));
    try {
      final contents = await _db.getEducationalContentByGrade(grade);
      final progress = await _db.getAllProgress();
      emit(state.copyWith(
        status: ContentStatus.loaded,
        contents: contents,
        progress: progress,
        selectedGrade: grade,
      ));
    } catch (e) {
      emit(state.copyWith(status: ContentStatus.error, errorMessage: e.toString()));
    }
  }

  Future loadContentForGradeAndSubject(int grade, String? subject) async {
    emit(state.copyWith(status: ContentStatus.loading));
    try {
      List<EducationalContent> contents;
      if (subject == null || subject == 'all') {
        contents = await _db.getEducationalContentByGrade(grade);
      } else {
        contents = await _db.getEducationalContentByGradeAndSubject(grade, subject);
      }
      final progress = await _db.getAllProgress();
      emit(state.copyWith(
        status: ContentStatus.loaded,
        contents: contents,
        progress: progress,
        selectedGrade: grade,
        selectedSubject: subject,
      ));
    } catch (e) {
      emit(state.copyWith(status: ContentStatus.error, errorMessage: e.toString()));
    }
  }

  Future showRandomContent(int grade) async {
    emit(state.copyWith(status: ContentStatus.loading));
    try {
      final content = await _db.getRandomContentByGrade(grade);
      emit(state.copyWith(
        status: ContentStatus.showingContent,
        currentContent: content,
      ));
    } catch (e) {
      emit(state.copyWith(status: ContentStatus.error, errorMessage: e.toString()));
    }
  }

  Future showRandomContentBySubject(int grade, String subject) async {
    emit(state.copyWith(status: ContentStatus.loading));
    try {
      final content = await _db.getRandomContentByGradeAndSubject(grade, subject);
      emit(state.copyWith(
        status: ContentStatus.showingContent,
        currentContent: content,
      ));
    } catch (e) {
      emit(state.copyWith(status: ContentStatus.error, errorMessage: e.toString()));
    }
  }

  Future showContentById(String id) async {
    emit(state.copyWith(status: ContentStatus.loading));
    try {
      final content = await _db.getEducationalContentById(id);
      emit(state.copyWith(
        status: ContentStatus.showingContent,
        currentContent: content,
      ));
    } catch (e) {
      emit(state.copyWith(status: ContentStatus.error, errorMessage: e.toString()));
    }
  }

  Future recordProgress(String contentId, bool completed, {int? score}) async {
    try {
      final existing = await _db.getProgress(contentId);
      final progress = existing ?? UserProgress(contentId: contentId);
      final updated = progress.copyWith(
        completed: completed || progress.completed,
        score: score ?? progress.score,
        attempts: progress.attempts + 1,
        lastAttemptAt: DateTime.now(),
      );
      await _db.insertOrUpdateProgress(updated);

      // Refresh progress in state
      final allProgress = await _db.getAllProgress();
      emit(state.copyWith(progress: allProgress));
    } catch (e) {
      // Silently fail progress tracking
    }
  }

  Future showRandomQuote(int grade, {String scene = 'over_limit'}) async {
    emit(state.copyWith(status: ContentStatus.loading));
    try {
      final quote = await _db.getRandomQuote(grade, scene);
      emit(state.copyWith(
        status: ContentStatus.showingQuote,
        currentQuote: quote,
      ));
    } catch (e) {
      emit(state.copyWith(status: ContentStatus.error, errorMessage: e.toString()));
    }
  }

  void clearCurrentContent() {
    emit(state.copyWith(
      status: ContentStatus.loaded,
      currentContent: null,
      currentQuote: null,
    ));
  }
}

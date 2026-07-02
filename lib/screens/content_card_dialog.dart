import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/content_cubit.dart';
import '../bloc/pet_cubit.dart';
import '../bloc/task_cubit.dart';
import '../data/database_helper.dart';
import '../models/app_models.dart';
import '../models/task_models.dart';

class ContentCardDialog extends StatefulWidget {
  const ContentCardDialog({super.key});

  @override
  State<ContentCardDialog> createState() => _ContentCardDialogState();
}

class _ContentCardDialogState extends State<ContentCardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + _controller.value * 0.2,
          child: Opacity(
            opacity: _controller.value,
            child: child,
          ),
        );
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: BlocBuilder<ContentCubit, ContentState>(
          builder: (context, state) {
            if (state.status == ContentStatus.loading) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final content = state.currentContent;
            if (content == null) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('暂无内容'),
              );
            }

            return Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 560),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor(content.type).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _typeLabel(content.type),
                          style: TextStyle(
                            color: _typeColor(content.type),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isDuplicateOfQuestion(content))
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                content.content,
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.7,
                                ),
                              ),
                            ),
                          if (content.requiresInteraction && content.question != null)
                            _buildQuestion(context, content),
                          if (_answered && content.explanation != null)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _isCorrect ? Colors.green[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isCorrect ? Colors.green : Colors.orange,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isCorrect ? Icons.check_circle : Icons.lightbulb,
                                        color: _isCorrect ? Colors.green : Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isCorrect ? '回答正确！' : '再想想',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _isCorrect ? Colors.green[700] : Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '解析：${content.explanation}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isDuplicateOfQuestion(EducationalContent content) {
    if (!content.requiresInteraction || content.question == null) return false;
    return content.content.trim() == content.question!.trim();
  }

  Widget _buildQuestion(BuildContext context, EducationalContent content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          content.question!,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        if (content.options != null)
          ...content.options!.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: _answered
                      ? null
                      : () => _checkAnswer(context, option, content.correctAnswer),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: _answered && option == content.correctAnswer
                        ? Colors.green
                        : (_answered && option != content.correctAnswer
                            ? Colors.grey[300]
                            : Colors.blue),
                    foregroundColor: _answered && option != content.correctAnswer
                        ? Colors.black54
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    '${String.fromCharCode(65 + index)}. $option',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _checkAnswer(BuildContext context, String selected, String? correct) {
    final isCorrect = selected == correct;
    setState(() {
      _answered = true;
      _isCorrect = isCorrect;
    });

    final content = context.read<ContentCubit>().state.currentContent;
    if (content == null) return;

    if (isCorrect) {
      context.read<PetCubit>().answerQuestionCorrectly(content.subject, content.grade);
      context.read<ContentCubit>().recordProgress(content.id, true, score: 100);

      // 通知任务系统
      final taskCubit = context.read<TaskCubit>();
      taskCubit.incrementTaskProgress(TaskType.answerQuestions, subject: content.subject);
      taskCubit.incrementTaskProgress(TaskType.completeAnyContent);

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (context.mounted) Navigator.pop(context);
      });
    } else {
      DatabaseHelper.instance.insertOrUpdateWrongAnswer(
        WrongAnswer(
          contentId: content.id,
          subject: content.subject,
          lastMistakeAt: DateTime.now(),
        ),
      );
    }
  }

  String _typeLabel(ContentType type) {
    switch (type) {
      case ContentType.poem:
        return '古诗词';
      case ContentType.english:
        return '英语';
      case ContentType.math:
        return '数学';
      case ContentType.physics:
        return '物理';
    }
  }

  Color _typeColor(ContentType type) {
    switch (type) {
      case ContentType.poem:
        return Colors.purple;
      case ContentType.english:
        return Colors.blue;
      case ContentType.math:
        return Colors.orange;
      case ContentType.physics:
        return Colors.teal;
    }
  }
}

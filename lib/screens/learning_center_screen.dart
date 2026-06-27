import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/content_cubit.dart';
import '../data/database_helper.dart';
import '../models/app_models.dart';
import 'content_card_dialog.dart';

class LearningCenterScreen extends StatefulWidget {
  final int grade;

  const LearningCenterScreen({super.key, required this.grade});

  @override
  State<LearningCenterScreen> createState() => _LearningCenterScreenState();
}

class _LearningCenterScreenState extends State<LearningCenterScreen> {
  final Map<String, String> _subjects = {
    'all': '全部',
    '语文': '语文',
    '英语': '英语',
    '数学': '数学',
    '物理': '物理',
  };

  final Map<String, IconData> _subjectIcons = {
    'all': Icons.dashboard,
    '语文': Icons.menu_book,
    '英语': Icons.translate,
    '数学': Icons.calculate,
    '物理': Icons.science,
  };

  final Map<String, Color> _subjectColors = {
    'all': Colors.grey,
    '语文': Colors.purple,
    '英语': Colors.blue,
    '数学': Colors.orange,
    '物理': Colors.teal,
  };

  int _completedToday = 0;
  final int _dailyGoal = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future _loadData() async {
    context.read<ContentCubit>().loadContentForGrade(widget.grade);
    final count = await DatabaseHelper.instance.getCompletedContentCountToday();
    setState(() => _completedToday = count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildDailyGoalCard(),
              _buildSubjectFilter(),
              Expanded(
                child: _buildContentList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              '学习中心',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard() {
    final progress = (_completedToday / _dailyGoal).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[400]!, Colors.teal[600]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '今日学习目标',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_completedToday / $_dailyGoal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _completedToday >= _dailyGoal
                ? '太棒了！今日目标已完成 🎉'
                : '再完成 ${_dailyGoal - _completedToday} 道题即可达成目标',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return BlocBuilder<ContentCubit, ContentState>(
      builder: (context, state) {
        final selectedSubject = state.selectedSubject ?? 'all';
        return Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final subject = _subjects.keys.elementAt(index);
              final isSelected = selectedSubject == subject;
              final color = _subjectColors[subject]!;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    context.read<ContentCubit>().loadContentForGradeAndSubject(
                      widget.grade,
                      subject == 'all' ? null : subject,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _subjectIcons[subject],
                          color: isSelected ? Colors.white : color,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _subjects[subject]!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContentList() {
    return BlocBuilder<ContentCubit, ContentState>(
      builder: (context, state) {
        if (state.status == ContentStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ContentStatus.error) {
          return Center(child: Text('加载失败：${state.errorMessage}'));
        }

        final contents = state.contents;
        if (contents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无内容', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final content = contents[index];
            final progress = state.progress[content.id];
            return _buildContentCard(content, progress);
          },
        );
      },
    );
  }

  Widget _buildContentCard(EducationalContent content, UserProgress? progress) {
    final isCompleted = progress?.completed ?? false;
    final color = _getTypeColor(content.type);
    final subjectColor = _subjectColors[content.subject] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openContent(content),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _getTypeEmoji(content.type),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: subjectColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            content.subject,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: subjectColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 12, color: Colors.green),
                                SizedBox(width: 2),
                                Text(
                                  '已完成',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      content.content.length > 40
                          ? '${content.content.substring(0, 40)}...'
                          : content.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.repeat, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '已完成 ${progress.attempts} 次',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (progress.score != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.star, size: 14, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text(
                              '最近得分 ${progress.score}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openContent(EducationalContent content) async {
    final contentCubit = context.read<ContentCubit>();
    contentCubit.showContentById(content.id);
    await showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: contentCubit,
        child: const ContentCardDialog(),
      ),
    );

    // Record progress after closing content dialog
    if (contentCubit.state.currentContent?.id == content.id) {
      contentCubit.recordProgress(content.id, true);
    }

    // Refresh daily goal
    final count = await DatabaseHelper.instance.getCompletedContentCountToday();
    setState(() => _completedToday = count);
  }

  String _getTypeEmoji(ContentType type) {
    switch (type) {
      case ContentType.poem:
        return '📜';
      case ContentType.english:
        return '🔤';
      case ContentType.math:
        return '🔢';
      case ContentType.physics:
        return '🔬';
    }
  }

  Color _getTypeColor(ContentType type) {
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

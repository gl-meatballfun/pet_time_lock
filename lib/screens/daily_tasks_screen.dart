import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pet_cubit.dart';
import '../bloc/task_cubit.dart';
import '../models/task_models.dart';

class DailyTasksScreen extends StatelessWidget {
  const DailyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日任务'),
        centerTitle: true,
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          if (state.status == TaskStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == TaskStatus.error) {
            return Center(child: Text('出错了：${state.errorMessage}'));
          }

          final tasks = state.tasks;
          if (tasks.isEmpty) {
            return const Center(child: Text('今天还没有任务，下拉刷新试试'));
          }

          final completedCount = tasks.where((t) => t.completed).length;

          return Column(
            children: [
              _buildHeader(completedCount, tasks.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskCard(context, task);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(int completed, int total) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '今日任务进度',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed / $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : completed / total,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, DailyTask task) {
    final progress = task.targetCount == 0
        ? 0.0
        : (task.currentCount / task.targetCount).clamp(0.0, 1.0);

    final canClaim = task.completed &&
        (task.rewardGrowthCoins > 0 || task.rewardHealthPoints > 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (task.completed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          '完成',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              task.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            task.completed ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${task.currentCount} / ${task.targetCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (canClaim)
                  ElevatedButton(
                    onPressed: () => _claimReward(context, task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('领取奖励'),
                  )
                else if (task.completed)
                  Text(
                    '已领取',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  _buildRewardPreview(task),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardPreview(DailyTask task) {
    final parts = <String>[];
    if (task.rewardGrowthCoins > 0) parts.add('+${task.rewardGrowthCoins} 成长币');
    if (task.rewardHealthPoints > 0) parts.add('+${task.rewardHealthPoints} 健康积分');

    return Text(
      parts.isEmpty ? '无奖励' : parts.join('  '),
      style: TextStyle(
        fontSize: 12,
        color: Colors.amber[700],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Future<void> _claimReward(BuildContext context, DailyTask task) async {
    final cubit = context.read<TaskCubit>();
    final success = await cubit.claimTaskReward(task);

    if (!context.mounted) return;

    if (success) {
      // 刷新 PetCubit 以反映货币变化
      final pet = context.read<PetCubit>().state.petState;
      if (pet != null) {
        context.read<PetCubit>().loadPetState(pet.currentGrade);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('奖励领取成功！'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('领取失败，请重试'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

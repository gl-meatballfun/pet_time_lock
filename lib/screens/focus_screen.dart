import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pet_cubit.dart';
import '../bloc/task_cubit.dart';
import '../models/task_models.dart';
import '../services/notification_service.dart';
import '../services/reward_service.dart';
import '../services/screen_time_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isCompleted = false;

  final List<int> _durations = [15, 25, 45, 60];
  int _selectedDuration = 25;

  late AnimationController _petAnimController;

  @override
  void initState() {
    super.initState();
    _petAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  void _startFocus() {
    setState(() {
      _isRunning = true;
      _remainingSeconds = _selectedDuration * 60;
      _isCompleted = false;
    });

    _petAnimController.repeat(reverse: true);

    context.read<ScreenTimeService>().startFocusMode(
          Duration(minutes: _selectedDuration),
        );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _completeFocus();
        }
      });
    });
  }

  void _completeFocus() {
    _timer?.cancel();
    _petAnimController.stop();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });
    context.read<PetCubit>().completeFocusSession(_selectedDuration);
    context.read<TaskCubit>().incrementTaskProgress(TaskType.focusSession);
    context.read<ScreenTimeService>().stopFocusMode();
    NotificationService().showFocusCompleteNotification();
  }

  void _cancelFocus() {
    _timer?.cancel();
    _petAnimController.stop();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedDuration * 60;
    });
    context.read<ScreenTimeService>().stopFocusMode();
    if (mounted) Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _petAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (_isRunning) {
              _cancelFocus();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('专注模式'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning && !_isCompleted) ...[
                  _buildDurationSelector(),
                ] else if (_isRunning) ...[
                  _buildRunningFocus(),
                ] else ...[
                  _buildCompletedFocus(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      children: [
        const Text(
          '选择专注时长',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          '宠物会陪伴你一起专注',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 48),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _durations.map((duration) {
            final isSelected = _selectedDuration == duration;
            return ChoiceChip(
              label: Text('$duration 分钟'),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedDuration = duration;
                  _remainingSeconds = duration * 60;
                });
              },
              selectedColor: Colors.blue,
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
        const SizedBox(height: 64),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _startFocus,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text('开始专注', style: TextStyle(fontSize: 20)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunningFocus() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _petAnimController,
          builder: (context, child) {
            final scale = 1.0 + sin(_petAnimController.value * 2 * pi) * 0.08;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🧘', style: TextStyle(fontSize: 80)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            _formatTime(_remainingSeconds),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '宠物正在陪伴你，坚持就是胜利！',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 64),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _cancelFocus,
            icon: const Icon(Icons.stop),
            label: const Text('放弃专注', style: TextStyle(fontSize: 18)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedFocus() {
    final healthPoints = RewardService.calculateFocusReward(_selectedDuration);
    final growthCoins = _selectedDuration ~/ 5;
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Text('🎉', style: TextStyle(fontSize: 80)),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          '专注完成！',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          '宠物获得了 $_selectedDuration 分钟的成长能量',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                '+${_selectedDuration * 2} 成长值',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRewardBadge('+$growthCoins', '成长币', Icons.monetization_on, Colors.amber),
            const SizedBox(width: 12),
            _buildRewardBadge('+$healthPoints', '健康积分', Icons.favorite, Colors.red),
          ],
        ),
        const SizedBox(height: 64),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
            ),
            child: const Text('返回主页', style: TextStyle(fontSize: 20)),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardBadge(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/content_cubit.dart';
import '../bloc/inventory_cubit.dart';
import '../bloc/monitor_cubit.dart';
import '../bloc/pet_cubit.dart';
import '../bloc/task_cubit.dart';
import '../models/app_models.dart';
import '../models/overlay_payload.dart';
import '../models/task_models.dart';
import '../services/overlay_service.dart';
import '../widgets/animated_pet_widget.dart';
import 'app_limits_screen.dart';
import 'content_card_dialog.dart';
import 'daily_tasks_screen.dart';
import 'focus_screen.dart';
import 'grade_select_screen.dart';
import 'inventory_screen.dart';
import 'learning_center_screen.dart';
import 'quote_card_dialog.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'time_slots_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetCubit, PetManagerState>(
      builder: (context, state) {
        if (state.status == PetStatus.needsGradeSelection) {
          return const GradeSelectScreen();
        }

        if (state.status == PetStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == PetStatus.error) {
          return Scaffold(
            body: Center(child: Text('出错了：${state.errorMessage}')),
          );
        }

        if (state.petState == null) {
          return const GradeSelectScreen();
        }

        return _HomeContent(petState: state.petState!);
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  final PetState petState;

  const _HomeContent({required this.petState});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  bool _showOverLimit = false;
  bool _overlayEnabled = false;
  PetState? _previousPetState;

  @override
  void initState() {
    super.initState();
    _loadOverlayState();
    context.read<InventoryCubit>().loadInventory();
  }

  Future<void> _loadOverlayState() async {
    final enabled = await OverlayService().isEnabled();
    if (mounted) {
      setState(() => _overlayEnabled = enabled);
    }
  }

  Future<void> _toggleOverlay() async {
    final overlayService = OverlayService();
    if (!overlayService.isSupported) return;

    final newValue = !_overlayEnabled;
    final success = await overlayService.setEnabled(newValue);
    if (mounted) {
      setState(() => _overlayEnabled = success ? newValue : _overlayEnabled);
    }
  }

  String _stageName(int stage) {
    const names = ['蛋', '婴儿', '幼儿', '少年', '成年'];
    return names[stage.clamp(0, names.length - 1)];
  }

  void _refreshOverlayIfNeeded(PetState? current) {
    if (current == null) return;
    final previous = _previousPetState;
    if (previous == null ||
        previous.health != current.health ||
        previous.happiness != current.happiness ||
        previous.hunger != current.hunger ||
        previous.stage != current.stage) {
      OverlayService().refreshOverlayPet(version: current.version);
    }
    _previousPetState = current;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PetCubit, PetManagerState>(
      listenWhen: (previous, current) =>
          current.petState != previous.petState ||
          (current.justEvolved && current.petState != null),
      listener: (context, state) {
        _refreshOverlayIfNeeded(state.petState);
        if (state.justEvolved && state.petState != null) {
          _showEvolutionDialog(state.petState!.stage);
        }
      },
      child: BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, inventoryState) {
          final equippedItem = inventoryState.items.where((i) => i.isEquipped).firstOrNull;
          final equippedAccessory = equippedItem != null
              ? inventoryState.itemDetails[equippedItem.itemId]?.appearanceUnlock
              : null;

          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[50]!, Colors.white],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildCurrencyBar(),
                    _buildGradeAndStageChip(),
                    _buildStatsBar(),
                    _buildScreenTimeCard(),
                    Expanded(
                      child: _buildPetArea(equippedAccessory ?? ''),
                    ),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '你好，${widget.petState.name ?? '小宠'}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '今天是陪你成长的一天',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOverlayToggle(),
              IconButton(
                icon: const Icon(Icons.backpack, size: 28),
                tooltip: '我的背包',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayToggle() {
    final overlayService = OverlayService();
    if (!overlayService.isSupported) return const SizedBox.shrink();

    return IconButton(
      icon: Icon(
        _overlayEnabled ? Icons.pets : Icons.pets_outlined,
        color: _overlayEnabled ? Colors.blue : Colors.grey,
      ),
      tooltip: _overlayEnabled ? '悬浮宠物已开启' : '开启悬浮宠物',
      onPressed: _toggleOverlay,
    );
  }

  Widget _buildCurrencyBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCurrencyItem('${widget.petState.growthCoins}', '成长币', Icons.monetization_on, Colors.amber),
          _buildCurrencyItem('${widget.petState.humanitiesPoints}', '文科', Icons.menu_book, Colors.purple),
          _buildCurrencyItem('${widget.petState.sciencePoints}', '理科', Icons.calculate, Colors.orange),
          _buildCurrencyItem('${widget.petState.healthPoints}', '健康', Icons.favorite, Colors.red),
        ],
      ),
    );
  }

  Widget _buildScreenTimeCard() {
    return BlocBuilder<MonitorCubit, MonitorState>(
      builder: (context, state) {
        if (state.status != MonitorStatus.loaded) {
          context.read<MonitorCubit>().loadSummary();
          return const SizedBox.shrink();
        }

        final total = state.totalScreenTimeMinutes;
        final overLimit = state.limitStatuses.where((s) => s.isOverLimit).toList();
        final hasWarning = overLimit.isNotEmpty;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasWarning ? Colors.red[50] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
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
                    '今日屏幕时间',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$total 分钟',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasWarning ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              if (overLimit.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '已超时：${overLimit.map((s) => s.appName).join('、')}',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.apps, size: 18),
                    label: const Text('应用限额'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppLimitsScreen()),
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: const Text('时段限制'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TimeSlotsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyItem(String value, String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildGradeAndStageChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Chip(
            avatar: const Icon(Icons.school, size: 18),
            label: Text('${widget.petState.currentGrade} 年级'),
            backgroundColor: Colors.blue[100],
          ),
          const SizedBox(width: 8),
          Chip(
            avatar: const Icon(Icons.auto_awesome, size: 18),
            label: Text(_stageName(widget.petState.stage)),
            backgroundColor: Colors.orange[100],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow('健康', widget.petState.health, Colors.red, Icons.favorite),
          const SizedBox(height: 10),
          _buildStatRow('快乐', widget.petState.happiness, Colors.orange, Icons.emoji_emotions),
          const SizedBox(height: 10),
          _buildStatRow('饥饿', widget.petState.hunger, Colors.green, Icons.restaurant),
          const SizedBox(height: 10),
          _buildStatRow('知识', widget.petState.knowledge % 100, Colors.blue, Icons.lightbulb),
          const SizedBox(height: 10),
          _buildStatRow('纪律', widget.petState.discipline, Colors.purple, Icons.shield),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        SizedBox(width: 45, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildPetArea(String equippedAccessory) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 32, bottom: 8),
      child: Transform.scale(
        scale: 0.85,
        child: AnimatedPetWidget(
          petState: widget.petState,
          isOverLimit: _showOverLimit,
          interactionType: InteractionType.pet,
          equippedAccessory: equippedAccessory.isEmpty ? null : equippedAccessory,
          onTap: () async {
            final petCubit = context.read<PetCubit>();
            final contentCubit = context.read<ContentCubit>();
            final result = await petCubit.petThePet();
            _showInteractionResult(result);
            if (mounted && result.success) {
              contentCubit.showRandomContent(widget.petState.currentGrade);
              _showContentCard(context);
            }
          },
          onDrag: () => context.read<PetCubit>().petThePet(),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.shopping_cart,
                  label: '商店',
                  color: Colors.amber,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.task_alt,
                  label: '每日任务',
                  color: Colors.indigo,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DailyTasksScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.timer_off,
                  label: '模拟超额',
                  color: Colors.orange,
                  onPressed: _simulateOverLimit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.self_improvement,
                  label: '专注模式',
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FocusScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.restaurant,
                  label: '喂食',
                  color: Colors.green,
                  onPressed: _onFeedPressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.sports_esports,
                  label: '玩耍',
                  color: Colors.pink,
                  onPressed: _onPlayPressed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.menu_book,
            label: '学习中心',
            color: Colors.teal,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LearningCenterScreen(
                    grade: widget.petState.currentGrade,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
    );
  }

  void _simulateOverLimit() async {
    setState(() => _showOverLimit = true);
    context.read<PetCubit>().onAppOverLimit();
    context.read<ContentCubit>().showRandomQuote(
      widget.petState.currentGrade,
      scene: 'over_limit',
    );
    OverlayService().showOverlayWithTrigger(OverlayTrigger.overLimit);
    await showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ContentCubit>(),
        child: const QuoteCardDialog(),
      ),
    );
    if (mounted) {
      setState(() => _showOverLimit = false);
    }
  }

  void _showContentCard(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ContentCubit>(),
        child: const ContentCardDialog(),
      ),
    );
  }

  void _onFeedPressed() async {
    final taskCubit = context.read<TaskCubit>();
    final result = await context.read<PetCubit>().feedPet();
    if (result.success) {
      taskCubit.incrementTaskProgress(TaskType.feedPet);
    }
    _showInteractionResult(result);
  }

  void _onPlayPressed() async {
    final taskCubit = context.read<TaskCubit>();
    final result = await context.read<PetCubit>().playWithPet();
    if (result.success) {
      taskCubit.incrementTaskProgress(TaskType.playWithPet);
    }
    _showInteractionResult(result);
  }

  void _showInteractionResult(InteractionResult result) {
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showEvolutionDialog(int newStage) {
    if (!mounted) return;
    const stageNames = ['蛋', '婴儿', '幼儿', '少年', '成年'];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('进化啦！', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              '你的宠物进化到了 ${stageNames[newStage.clamp(0, stageNames.length - 1)]} 阶段！',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('太棒了！'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/app_models.dart';

/// Screen for managing per-app daily usage limits.
class AppLimitsScreen extends StatefulWidget {
  const AppLimitsScreen({super.key});

  @override
  State<AppLimitsScreen> createState() => _AppLimitsScreenState();
}

class _AppLimitsScreenState extends State<AppLimitsScreen> {
  final _db = DatabaseHelper.instance;
  List<AppLimit> _limits = [];
  Map<String, int> _todayUsage = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final limits = await _db.getAppLimits();
    final usage = await _db.getTodayUsageByPackage();
    setState(() {
      _limits = limits;
      _todayUsage = usage;
      _loading = false;
    });
  }

  Future<void> _deleteLimit(String packageName) async {
    final db = await _db.database;
    await db.delete('app_limits', where: 'package_name = ?', whereArgs: [packageName]);
    await _load();
  }

  Future<void> _toggleActive(AppLimit limit) async {
    final updated = AppLimit(
      packageName: limit.packageName,
      appName: limit.appName,
      category: limit.category,
      dailyLimitMinutes: limit.dailyLimitMinutes,
      isActive: !limit.isActive,
    );
    await _db.insertOrUpdateAppLimit(updated);
    await _load();
  }

  Future<void> _showAddEditDialog([AppLimit? existing]) async {
    final packageController = TextEditingController(text: existing?.packageName ?? '');
    final nameController = TextEditingController(text: existing?.appName ?? '');
    int limitMinutes = existing?.dailyLimitMinutes ?? 30;
    bool isEditing = existing != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? '编辑限额' : '添加应用限额'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: packageController,
                enabled: !isEditing,
                decoration: const InputDecoration(
                  labelText: '应用包名',
                  hintText: 'com.tencent.mm',
                ),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '应用名称',
                  hintText: '微信',
                ),
              ),
              const SizedBox(height: 16),
              Text('每日限额：$limitMinutes 分钟'),
              Slider(
                value: limitMinutes.toDouble(),
                min: 5,
                max: 180,
                divisions: 35,
                label: '$limitMinutes 分钟',
                onChanged: (value) => setDialogState(() => limitMinutes = value.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (packageController.text.isEmpty || nameController.text.isEmpty) return;
              final limit = AppLimit(
                packageName: packageController.text.trim(),
                appName: nameController.text.trim(),
                dailyLimitMinutes: limitMinutes,
                isActive: existing?.isActive ?? true,
              );
              await _db.insertOrUpdateAppLimit(limit);
              if (mounted) Navigator.pop(context);
              await _load();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用限额'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _limits.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _limits.length,
                  itemBuilder: (context, index) => _buildLimitTile(_limits[index]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apps, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('还没有设置应用限额'),
          const SizedBox(height: 8),
          const Text(
            '点击右下角添加要限制的应用',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitTile(AppLimit limit) {
    final usedSeconds = _todayUsage[limit.packageName] ?? 0;
    final usedMinutes = usedSeconds ~/ 60;
    final progress = limit.dailyLimitMinutes > 0
        ? usedMinutes / limit.dailyLimitMinutes
        : 0.0;
    final color = progress >= 1.0
        ? Colors.red
        : progress >= 0.8
            ? Colors.orange
            : Colors.green;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(Icons.apps, color: color),
      ),
      title: Text(limit.appName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(limit.packageName),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
          const SizedBox(height: 2),
          Text(
            '$usedMinutes / ${limit.dailyLimitMinutes} 分钟',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: limit.isActive,
            onChanged: (_) => _toggleActive(limit),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showAddEditDialog(limit),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteLimit(limit.packageName),
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

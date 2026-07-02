import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/compliance_models.dart';

/// Screen for managing restricted time slots.
class TimeSlotsScreen extends StatefulWidget {
  const TimeSlotsScreen({super.key});

  @override
  State<TimeSlotsScreen> createState() => _TimeSlotsScreenState();
}

class _TimeSlotsScreenState extends State<TimeSlotsScreen> {
  final _db = DatabaseHelper.instance;
  List<TimeSlot> _slots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final slots = await _db.getTimeSlots();
    setState(() {
      _slots = slots;
      _loading = false;
    });
  }

  Future<void> _deleteSlot(int id) async {
    await _db.deleteTimeSlot(id);
    await _load();
  }

  Future<void> _toggleActive(TimeSlot slot) async {
    await _db.updateTimeSlot(slot.copyWith(isActive: !slot.isActive));
    await _load();
  }

  Future<void> _showAddEditDialog([TimeSlot? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    TimeOfDay startTime = _parseTimeOfDay(existing?.startTime ?? '22:00');
    TimeOfDay endTime = _parseTimeOfDay(existing?.endTime ?? '07:00');
    final days = List<int>.from(existing?.daysOfWeek ?? [1, 2, 3, 4, 5, 6, 7]);
    bool blockEntertainment = existing?.blockEntertainment ?? true;
    bool blockAll = existing?.blockAll ?? false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? '添加时段限制' : '编辑时段限制'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('开始时间'),
                  trailing: Text(startTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (picked != null) {
                      setDialogState(() => startTime = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('结束时间'),
                  trailing: Text(endTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (picked != null) {
                      setDialogState(() => endTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Text('重复'),
                Wrap(
                  spacing: 4,
                  children: [
                    _DayChip(
                      label: '一',
                      selected: days.contains(1),
                      onSelected: (selected) => _toggleDay(days, 1, selected, setDialogState),
                    ),
                    _DayChip(
                      label: '二',
                      selected: days.contains(2),
                      onSelected: (selected) => _toggleDay(days, 2, selected, setDialogState),
                    ),
                    _DayChip(
                      label: '三',
                      selected: days.contains(3),
                      onSelected: (selected) => _toggleDay(days, 3, selected, setDialogState),
                    ),
                    _DayChip(
                      label: '四',
                      selected: days.contains(4),
                      onSelected: (selected) => _toggleDay(days, 4, selected, setDialogState),
                    ),
                    _DayChip(
                      label: '五',
                      selected: days.contains(5),
                      onSelected: (selected) => _toggleDay(days, 5, selected, setDialogState),
                    ),
                    _DayChip(
                      label: '六',
                      selected: days.contains(6),
                      onSelected: (selected) => _toggleDay(days, 6, selected, setDialogState),
                    ),
                    _DayChip(
                      label: '日',
                      selected: days.contains(7),
                      onSelected: (selected) => _toggleDay(days, 7, selected, setDialogState),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('仅限制娱乐应用'),
                  value: blockEntertainment && !blockAll,
                  onChanged: (value) => setDialogState(() {
                    blockEntertainment = value;
                    if (value) blockAll = false;
                  }),
                ),
                SwitchListTile(
                  title: const Text('限制所有应用（白名单除外）'),
                  value: blockAll,
                  onChanged: (value) => setDialogState(() {
                    blockAll = value;
                    if (value) blockEntertainment = false;
                  }),
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
                if (nameController.text.isEmpty || days.isEmpty) return;
                final slot = TimeSlot(
                  id: existing?.id,
                  name: nameController.text.trim(),
                  startTime: _formatTimeOfDay(startTime),
                  endTime: _formatTimeOfDay(endTime),
                  daysOfWeek: List.unmodifiable(days),
                  isActive: existing?.isActive ?? true,
                  blockEntertainment: blockEntertainment,
                  blockAll: blockAll,
                );
                if (existing == null) {
                  await _db.insertTimeSlot(slot);
                } else {
                  await _db.updateTimeSlot(slot);
                }
                if (mounted) Navigator.pop(context);
                await _load();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDay(List<int> days, int day, bool selected, StateSetter setDialogState) {
    setDialogState(() {
      if (selected) {
        if (!days.contains(day)) days.add(day);
      } else {
        days.remove(day);
      }
    });
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDays(List<int> days) {
    const names = ['', '一', '二', '三', '四', '五', '六', '日'];
    return days.map((d) => names[d]).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('时段限制'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _slots.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _slots.length,
                  itemBuilder: (context, index) => _buildSlotTile(_slots[index]),
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
          Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('还没有设置时段限制'),
          const SizedBox(height: 8),
          const Text(
            '例如：22:00-07:00 限制娱乐应用',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotTile(TimeSlot slot) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: slot.isActive ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        child: Icon(Icons.schedule, color: slot.isActive ? Colors.blue : Colors.grey),
      ),
      title: Text(slot.name),
      subtitle: Text('${slot.startTime} - ${slot.endTime}\n每周 ${_formatDays(slot.daysOfWeek)}'),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: slot.isActive,
            onChanged: (_) => _toggleActive(slot),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showAddEditDialog(slot),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => slot.id != null ? _deleteSlot(slot.id!) : null,
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

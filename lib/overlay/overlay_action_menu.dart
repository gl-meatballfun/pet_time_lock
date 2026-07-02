import 'package:flutter/material.dart';

import '../models/overlay_payload.dart';

/// Action menu shown when the floating pet is expanded.
class OverlayActionMenu extends StatelessWidget {
  final ValueChanged<OverlayPayload> onActionSelected;
  final VoidCallback onClose;

  const OverlayActionMenu({
    super.key,
    required this.onActionSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const actions = [
      _Action(
        label: '喂食',
        icon: Icons.restaurant,
        color: Colors.green,
        payload: OverlayPayload.feed,
      ),
      _Action(
        label: '玩耍',
        icon: Icons.sports_esports,
        color: Colors.pink,
        payload: OverlayPayload.play,
      ),
      _Action(
        label: '学习',
        icon: Icons.menu_book,
        color: Colors.teal,
        payload: OverlayPayload.learn,
      ),
      _Action(
        label: '专注',
        icon: Icons.self_improvement,
        color: Colors.blue,
        payload: OverlayPayload.focus,
      ),
      _Action(
        label: '回应用',
        icon: Icons.home,
        color: Colors.orange,
        payload: OverlayPayload.openApp,
      ),
    ];

    return GestureDetector(
      onTap: onClose,
      behavior: HitTestBehavior.translucent,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 86),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: actions.map((action) {
              return _buildActionTile(action);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(_Action action) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onActionSelected(action.payload),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(action.icon, color: action.color, size: 18),
            const SizedBox(width: 10),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final OverlayPayload payload;

  const _Action({
    required this.label,
    required this.icon,
    required this.color,
    required this.payload,
  });
}

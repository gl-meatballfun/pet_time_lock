import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/overlay_constants.dart';
import '../models/app_models.dart';

/// A compact animated pet widget for the floating overlay.
///
/// It mirrors the visual language of [AnimatedPetWidget] but at a smaller
/// size suitable for a system overlay window.
class OverlayPetWidget extends StatefulWidget {
  final PetState petState;
  final bool isOverLimit;
  final bool isTriggered;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDrag;
  final String? triggerMessage;
  final String? equippedAccessory;

  const OverlayPetWidget({
    super.key,
    required this.petState,
    required this.onTap,
    this.onLongPress,
    this.onDrag,
    this.isOverLimit = false,
    this.isTriggered = false,
    this.triggerMessage,
    this.equippedAccessory,
  });

  @override
  State<OverlayPetWidget> createState() => _OverlayPetWidgetState();
}

class _OverlayPetWidgetState extends State<OverlayPetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  double _tapScale = 1.0;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    _bounce();
  }

  void _handleLongPress() {
    widget.onLongPress?.call();
    _bounce();
  }

  void _handleDrag(DragUpdateDetails details) {
    widget.onDrag?.call();
  }

  void _bounce() async {
    setState(() => _tapScale = 0.85);
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) setState(() => _tapScale = 1.0);
  }

  Color _getMoodColor() {
    if (widget.isOverLimit) return Colors.deepOrange;

    final stageColors = [
      Colors.brown,
      Colors.pink,
      Colors.orange,
      Colors.blue,
      Colors.purple,
    ];
    final baseColor = stageColors[widget.petState.stage.clamp(0, 4)];

    if (widget.petState.happiness >= 70 && widget.petState.health >= 70) {
      return baseColor;
    }
    if (widget.petState.happiness >= 40 && widget.petState.health >= 40) {
      return Color.lerp(baseColor, Colors.orange, 0.3)!;
    }
    return Color.lerp(baseColor, Colors.blueGrey, 0.5)!;
  }

  String _getFace() {
    if (widget.isOverLimit) return '😟';
    final facesByStage = [
      ['🥚'],
      ['👶', '🍼'],
      ['🧒', '😊', '🤗'],
      ['🧑', '😄', '🤩'],
      ['🧑‍🎓', '🤴', '👸', '🌟'],
    ];
    final stageFaces = facesByStage[widget.petState.stage.clamp(0, 4)];
    final faceIndex =
        widget.petState.appearance.unlockedFaceIndex % stageFaces.length;
    return stageFaces[faceIndex];
  }

  String _getAccessory() {
    if (widget.equippedAccessory != null && widget.equippedAccessory!.isNotEmpty) {
      return widget.equippedAccessory!;
    }
    final accessories = widget.petState.appearance.unlockedAccessories;
    if (accessories.isEmpty) return '';
    return accessories.last;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isTriggered
        ? OverlayConstants.triggeredPetSize
        : OverlayConstants.collapsedPetSize;
    final fontSize = widget.isTriggered ? 56.0 : 40.0;
    final accessorySize = widget.isTriggered ? 28.0 : 20.0;

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      onPanUpdate: _handleDrag,
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          final idleOffset = sin(_idleController.value * 2 * pi) * 4;
          return Transform.translate(
            offset: Offset(0, idleOffset),
            child: AnimatedScale(
              scale: _tapScale,
              duration: const Duration(milliseconds: 120),
              curve: Curves.elasticOut,
              child: child,
            ),
          );
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getMoodColor().withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: _getMoodColor().withOpacity(0.4),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getFace(),
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ),
              if (_getAccessory().isNotEmpty)
                Positioned(
                  top: -4,
                  right: size * 0.075,
                  child: Text(
                    _getAccessory(),
                    style: TextStyle(fontSize: accessorySize),
                  ),
                ),
              if (widget.triggerMessage != null)
                Positioned(
                  top: -50,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.triggerMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

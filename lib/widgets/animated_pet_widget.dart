import 'dart:math';

import 'package:flutter/material.dart';

import '../models/app_models.dart';

/// A rich animated pet widget with mood-based visuals, idle animation,
/// tap/drag feedback, and floating emotion particles.
class AnimatedPetWidget extends StatefulWidget {
  final PetState petState;
  final VoidCallback? onTap;
  final VoidCallback? onDrag;
  final bool isOverLimit;
  final InteractionType? interactionType;
  final bool showEvolution;
  final String? equippedAccessory;

  const AnimatedPetWidget({
    super.key,
    required this.petState,
    this.onTap,
    this.onDrag,
    this.isOverLimit = false,
    this.interactionType,
    this.showEvolution = false,
    this.equippedAccessory,
  });

  @override
  State<AnimatedPetWidget> createState() => _AnimatedPetWidgetState();
}

class _AnimatedPetWidgetState extends State<AnimatedPetWidget>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _evolutionController;
  late AnimationController _bubbleShakeController;
  final List<_FloatingParticle> _particles = [];
  double _tapScale = 1.0;
  double _bubbleScale = 1.0;
  String _lastMessage = '';
  int _particleKey = 0;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _evolutionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.showEvolution) {
      _evolutionController.forward(from: 0);
    }

    _bubbleShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _lastMessage = _getPetMessage();
  }

  @override
  void didUpdateWidget(covariant AnimatedPetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showEvolution && !oldWidget.showEvolution) {
      _evolutionController.forward(from: 0);
    }

    final currentMessage = _getPetMessage();
    if (currentMessage != _lastMessage) {
      _lastMessage = currentMessage;
      _pulseBubble();
    }
  }

  void _pulseBubble() async {
    setState(() => _bubbleScale = 1.15);
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) setState(() => _bubbleScale = 1.0);
  }

  @override
  void dispose() {
    _idleController.dispose();
    _evolutionController.dispose();
    _bubbleShakeController.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap?.call();
    _spawnParticles(type: widget.interactionType);
    _bounce();
    _shakeBubble();
  }

  void _handleDrag(DragUpdateDetails details) {
    widget.onDrag?.call();
    if (details.delta.distance > 2) {
      _spawnParticles(type: widget.interactionType);
    }
  }

  void _shakeBubble() {
    _bubbleShakeController.forward(from: 0);
  }

  void _bounce() async {
    setState(() => _tapScale = 0.85);
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) setState(() => _tapScale = 1.0);
  }

  void _spawnParticles({InteractionType? type}) {
    final emojiSet = switch (type) {
      InteractionType.feed => ['🍎', '🍌', '🥕', '🍖', '❤️'],
      InteractionType.play => ['🎾', '🎉', '🌟', '✨', '😄'],
      InteractionType.pet => ['❤️', '💕', '✨', '⭐'],
      InteractionType.focus => ['🔥', '⭐', '✨', '💪'],
      InteractionType.learn => ['📚', '💡', '✨', '⭐'],
      _ => ['❤️', '⭐', '✨'],
    };
    setState(() {
      for (int i = 0; i < 5; i++) {
        _particles.add(_FloatingParticle(
          key: ValueKey(_particleKey++),
          offset: Offset(
            Random().nextDouble() * 80 - 40,
            Random().nextDouble() * 40 - 80,
          ),
          emoji: emojiSet[Random().nextInt(emojiSet.length)],
          onComplete: () {
            setState(() {
              _particles.removeWhere((p) => p.key == ValueKey(_particleKey - 1));
            });
          },
        ));
      }
    });
  }

  Color _getMoodColor() {
    if (widget.isOverLimit) return Colors.deepOrange;

    final stageColors = [
      Colors.brown, // 蛋
      Colors.pink, // 婴儿
      Colors.orange, // 幼儿
      Colors.blue, // 少年
      Colors.purple, // 成年
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

  String _getPetMessage() {
    if (widget.isOverLimit) {
      return '你用手机有点久啦，休息一下吧~';
    }
    if (widget.petState.hunger < 20) return '我好饿呀，快给我吃点东西吧！';
    if (widget.petState.hunger < 40) return '我有点饿了，来学道题充充饥吧~';
    if (widget.petState.happiness < 30) return '我好无聊，陪我玩一会儿好吗？';
    if (widget.petState.happiness < 50) return '陪我玩一会儿好吗？';
    if (widget.petState.health < 30) return '我感觉不太舒服...';
    if (widget.petState.health < 50) return '该休息一下眼睛啦';
    if (widget.petState.discipline < 40) return '今天你用手机有点多哦';
    return '今天也要加油哦！';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onPanUpdate: _handleDrag,
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          final idleOffset = sin(_idleController.value * 2 * pi) * 6;
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
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Glow effect
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getMoodColor().withOpacity(0.15),
              ),
            ),
            // Pet body
            AnimatedBuilder(
              animation: _evolutionController,
              builder: (context, child) {
                final value = _evolutionController.value;
                if (value == 0) return child!;
                final scale = 1.0 + sin(value * pi * 2) * 0.2 * (1 - value);
                final rotation = sin(value * pi * 4) * 0.3 * (1 - value);
                return Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getMoodColor().withOpacity(0.9),
                      _getMoodColor().withOpacity(0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getMoodColor().withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getFace(),
                    style: const TextStyle(fontSize: 90),
                  ),
                ),
              ),
            ),
            // Accessory
            if (_getAccessory().isNotEmpty)
              Positioned(
                top: -10,
                right: 20,
                child: Text(
                  _getAccessory(),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            // Floating particles
            ..._particles,
            // Speech bubble
            Positioned(
              top: -70,
              child: AnimatedBuilder(
                animation: _bubbleShakeController,
                builder: (context, child) {
                  final shake = sin(_bubbleShakeController.value * pi * 8) * 4 * (1 - _bubbleShakeController.value);
                  return Transform.translate(
                    offset: Offset(shake, 0),
                    child: child,
                  );
                },
                child: AnimatedScale(
                  scale: _bubbleScale,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.elasticOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getMoodColor().withOpacity(0.15),
                          Colors.white.withOpacity(0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getMoodColor().withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getMoodColor().withOpacity(0.25),
                          blurRadius: 14,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _getPetMessage(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingParticle extends StatefulWidget {
  final Offset offset;
  final String emoji;
  final VoidCallback onComplete;

  const _FloatingParticle({
    required super.key,
    required this.offset,
    required this.emoji,
    required this.onComplete,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
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
        final progress = _controller.value;
        return Positioned(
          top: -60 - progress * 80,
          left: widget.offset.dx + progress * widget.offset.dx * 0.5,
          child: Opacity(
            opacity: 1 - progress,
            child: Transform.scale(
              scale: 1 - progress * 0.3,
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      },
    );
  }
}

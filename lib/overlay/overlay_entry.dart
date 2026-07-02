import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../constants/overlay_constants.dart';
import '../data/database_helper.dart';
import '../models/app_models.dart';
import '../models/currency_models.dart';
import '../models/overlay_payload.dart';
import '../services/overlay_service.dart';
import 'overlay_action_menu.dart';
import 'overlay_pet_widget.dart';

/// Entry point for the floating overlay Flutter engine.
///
/// This function is invoked by the native side when the overlay window is
/// shown. It must be annotated with `@pragma('vm:entry-point')` so that the
/// Dart compiler does not tree-shake it.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key});

  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> {
  PetState? _petState;
  String? _equippedAccessory;
  bool _isExpanded = false;
  String? _triggerMessage;
  Timer? _triggerTimer;
  Timer? _autoCollapseTimer;
  Timer? _refreshTimer;
  int _knownVersion = -1;
  double _opacity = OverlayConstants.defaultOpacity;

  @override
  void initState() {
    super.initState();
    _loadOpacity();
    _loadPetState(force: true);
    _setupOverlayListeners();

    // Refresh from the database periodically while the overlay is visible.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: OverlayConstants.refreshIntervalSeconds),
      (_) => _loadPetState(),
    );
  }

  DateTime? _lastToggleTime;

  @override
  void dispose() {
    _triggerTimer?.cancel();
    _autoCollapseTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOpacity() async {
    _opacity = await OverlayService().opacity();
    if (mounted) setState(() {});
  }

  Future<void> _loadPetState({bool force = false}) async {
    try {
      final pet = await DatabaseHelper.instance.getPetState();
      if (pet == null) return;

      if (!force && pet.version == _knownVersion) {
        // Nothing changed since the last successful load.
        return;
      }

      final inventory = await DatabaseHelper.instance.getAllInventory();
      String? equipped;
      for (final item in inventory) {
        if (item.isEquipped) {
          final ShopItem? shopItem = await DatabaseHelper.instance.getShopItem(item.itemId);
          if (shopItem != null) {
            equipped = shopItem.appearanceUnlock;
            break;
          }
        }
      }
      if (mounted) {
        setState(() {
          _petState = pet;
          _equippedAccessory = equipped;
        });
        _knownVersion = pet.version;
        _sendRefreshAck(pet.version);
      }
    } catch (e) {
      debugPrint('Overlay failed to load pet state: $e');
    }
  }

  void _sendRefreshAck(int version) {
    FlutterOverlayWindow.shareData({
      OverlayConstants.fieldAction: OverlayConstants.actionAckRefresh,
      OverlayConstants.fieldVersion: version,
    });
  }

  void _setupOverlayListeners() {
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is! Map) return;

      final action = event[OverlayConstants.fieldAction] as String?;
      switch (action) {
        case OverlayConstants.actionRefreshPet:
          final version = event[OverlayConstants.fieldVersion] as int?;
          if (version != null && version == _knownVersion) {
            // Already up to date; acknowledge without re-reading.
            _sendRefreshAck(version);
          } else {
            _loadPetState();
          }
          break;
        case OverlayConstants.actionShowTrigger:
          _handleTriggerEvent(event);
          break;
        case OverlayConstants.actionCollapse:
          _collapse();
          break;
      }
    });
  }

  void _handleTriggerEvent(Map<dynamic, dynamic> event) {
    final triggerName = event[OverlayConstants.fieldTrigger] as String?;
    final message = event[OverlayConstants.fieldMessage] as String?;
    final durationMs = event[OverlayConstants.fieldDuration] as int? ??
        OverlayConstants.defaultTriggerDurationMs;
    final trigger = OverlayTrigger.values.firstWhere(
      (t) => t.name == triggerName,
      orElse: () => OverlayTrigger.focusComplete,
    );

    _triggerTimer?.cancel();
    _autoCollapseTimer?.cancel();

    setState(() {
      _triggerMessage = message ?? trigger.message;
      _isExpanded = false;
    });

    // Return to the normal collapsed state after the configured duration.
    _triggerTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) {
        setState(() {
          _triggerMessage = null;
        });
      }
    });
  }

  void _toggleExpanded() {
    final now = DateTime.now();
    if (_lastToggleTime != null &&
        now.difference(_lastToggleTime!) < const Duration(milliseconds: 300)) {
      return;
    }
    _lastToggleTime = now;

    setState(() => _isExpanded = !_isExpanded);

    _autoCollapseTimer?.cancel();
    if (_isExpanded) {
      _autoCollapseTimer = Timer(
        const Duration(milliseconds: OverlayConstants.autoCollapseDelayMs),
        () {
          if (mounted) _collapse();
        },
      );
    }
  }

  void _collapse() {
    if (mounted) {
      setState(() => _isExpanded = false);
    }
  }

  Future<void> _onActionSelected(OverlayPayload payload) async {
    _collapse();

    // For simple interactions we can just animate; everything else launches
    // the main app so that state mutations happen in a single place.
    if (payload == OverlayPayload.pet) {
      return;
    }

    await OverlayService().bringAppToForeground(payload);
  }

  @override
  Widget build(BuildContext context) {
    final pet = _petState;
    if (pet == null) {
      return const SizedBox.shrink();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: _opacity,
                child: OverlayPetWidget(
                  petState: pet,
                  equippedAccessory: _equippedAccessory,
                  triggerMessage: _triggerMessage,
                  isTriggered: _triggerMessage != null,
                  onTap: _toggleExpanded,
                  onLongPress: _toggleExpanded,
                ),
              ),
            ),
            if (_isExpanded)
              OverlayActionMenu(
                onActionSelected: _onActionSelected,
                onClose: _collapse,
              ),
          ],
        ),
      ),
    );
  }
}

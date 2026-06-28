import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../data/database_helper.dart';
import '../models/app_models.dart';
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
  bool _isExpanded = false;
  String? _triggerMessage;
  Timer? _triggerTimer;
  Timer? _autoCollapseTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPetState();
    _setupOverlayListeners();

    // Refresh from the database periodically while the overlay is visible.
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadPetState();
    });
  }

  @override
  void dispose() {
    _triggerTimer?.cancel();
    _autoCollapseTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPetState() async {
    try {
      final pet = await DatabaseHelper.instance.getPetState();
      if (mounted) {
        setState(() => _petState = pet);
      }
    } catch (e) {
      debugPrint('Overlay failed to load pet state: $e');
    }
  }

  void _setupOverlayListeners() {
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is! Map) return;

      final action = event['action'] as String?;
      switch (action) {
        case 'refresh_pet':
          _loadPetState();
          break;
        case 'show_trigger':
          _handleTriggerEvent(event);
          break;
        case 'collapse':
          _collapse();
          break;
      }
    });
  }

  void _handleTriggerEvent(Map<dynamic, dynamic> event) {
    final triggerName = event['trigger'] as String?;
    final message = event['message'] as String?;
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

    // Return to the normal collapsed state after 8 seconds.
    _triggerTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _triggerMessage = null;
        });
      }
    });
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);

    _autoCollapseTimer?.cancel();
    if (_isExpanded) {
      _autoCollapseTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) _collapse();
      });
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
            if (_isExpanded)
              OverlayActionMenu(
                onActionSelected: _onActionSelected,
                onClose: _collapse,
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: OverlayPetWidget(
                petState: pet,
                triggerMessage: _triggerMessage,
                onTap: _toggleExpanded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/content_cubit.dart';
import 'bloc/inventory_cubit.dart';
import 'bloc/monitor_cubit.dart';
import 'bloc/pet_cubit.dart';
import 'bloc/shop_cubit.dart';
import 'bloc/task_cubit.dart';
import 'data/database_helper.dart';
import 'models/app_models.dart';
import 'models/overlay_payload.dart';
import 'models/task_models.dart';
import 'overlay/overlay_entry.dart' as overlay;
import 'screens/focus_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learning_center_screen.dart';
import 'services/app_monitor_service.dart';
import 'services/overlay_service.dart';
import 'services/screen_time_service.dart';

/// Overlay engine entry point required by flutter_overlay_window.
///
/// The native side looks up a top-level Dart function named `overlayMain` in
/// the main library. This wrapper keeps the real implementation in its own
/// file while ensuring the entry point survives tree-shaking.
@pragma('vm:entry-point')
void overlayMain() => overlay.overlayMain();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final db = DatabaseHelper.instance;
  final screenTimeService = createScreenTimeService();
  final appMonitor = AppMonitorService(
    prefs: prefs,
    db: db,
    screenTimeService: screenTimeService,
  );
  await appMonitor.initialize();

  runApp(PetTimeLockApp(
    prefs: prefs,
    db: db,
    screenTimeService: screenTimeService,
    appMonitor: appMonitor,
  ));
}

class PetTimeLockApp extends StatefulWidget {
  final SharedPreferences prefs;
  final DatabaseHelper db;
  final ScreenTimeService screenTimeService;
  final AppMonitorService appMonitor;

  const PetTimeLockApp({
    super.key,
    required this.prefs,
    required this.db,
    required this.screenTimeService,
    required this.appMonitor,
  });

  @override
  State<PetTimeLockApp> createState() => _PetTimeLockAppState();
}

class _PetTimeLockAppState extends State<PetTimeLockApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleOverlayPendingAction();
      if (widget.appMonitor.isEnabled) {
        widget.appMonitor.startForegroundMonitoring();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.appMonitor.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.appMonitor.startForegroundMonitoring();
      _handleOverlayPendingAction();
    } else if (state == AppLifecycleState.paused) {
      widget.appMonitor.stopForegroundMonitoring();
    }
  }

  Future<void> _handleOverlayPendingAction() async {
    final payload = await OverlayService().takePendingAction();
    if (payload == null || !mounted) return;

    switch (payload) {
      case OverlayPayload.feed:
        _navigateAndExecute(
          (context) => context.read<PetCubit>().feedPet(),
          '喂食成功！',
          taskType: TaskType.feedPet,
        );
      case OverlayPayload.play:
        _navigateAndExecute(
          (context) => context.read<PetCubit>().playWithPet(),
          '玩耍很开心！',
          taskType: TaskType.playWithPet,
        );
      case OverlayPayload.pet:
        _navigateAndExecute(
          (context) => context.read<PetCubit>().petThePet(),
          '宠物感受到了你的关爱~',
        );
      case OverlayPayload.focus:
        _navigateTo(const FocusScreen());
      case OverlayPayload.learn:
        final pet = await widget.db.getPetState();
        if (pet != null) {
          _navigateTo(LearningCenterScreen(grade: pet.currentGrade));
        }
      case OverlayPayload.openApp:
      case OverlayPayload.overLimit:
      case OverlayPayload.focusComplete:
      case OverlayPayload.evolution:
      case OverlayPayload.openAppLimits:
      case OverlayPayload.openTimeSlots:
        // No special navigation; returning to home is enough.
        break;
    }
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  void _navigateAndExecute(
    Future<InteractionResult> Function(BuildContext context) action,
    String fallbackMessage, {
    TaskType? taskType,
  }) async {
    if (!mounted) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigator.context;
      if (context.mounted) {
        final taskCubit = taskType != null ? context.read<TaskCubit>() : null;
        final result = await action(context);
        if (taskType != null && result.success) {
          taskCubit?.incrementTaskProgress(taskType);
        }
        final message = result.message.isNotEmpty ? result.message : fallbackMessage;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: result.success ? Colors.green : Colors.orange,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DatabaseHelper>.value(value: widget.db),
        RepositoryProvider<ScreenTimeService>.value(value: widget.screenTimeService),
        RepositoryProvider<AppMonitorService>.value(value: widget.appMonitor),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => PetCubit(widget.db, widget.prefs),
          ),
          BlocProvider(
            create: (_) => ContentCubit(widget.db),
          ),
          BlocProvider(
            create: (_) => ShopCubit(widget.db),
          ),
          BlocProvider(
            create: (_) => InventoryCubit(widget.db),
          ),
          BlocProvider(
            create: (_) => TaskCubit(widget.db),
          ),
          BlocProvider(
            create: (_) => MonitorCubit(widget.db, widget.screenTimeService),
          ),
        ],
        child: Builder(
          builder: (context) {
            widget.appMonitor.setPetCubit(context.read<PetCubit>());
            return MaterialApp(
              title: '宠物时间锁',
              debugShowCheckedModeBanner: false,
              navigatorKey: _navigatorKey,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
                fontFamily: 'NotoSansSC',
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
                fontFamily: 'NotoSansSC',
              ),
              home: const HomeScreen(),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/content_cubit.dart';
import 'bloc/pet_cubit.dart';
import 'data/database_helper.dart';
import 'models/app_models.dart';
import 'models/overlay_payload.dart';
import 'overlay/overlay_entry.dart' as overlay;
import 'screens/focus_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learning_center_screen.dart';
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

  runApp(PetTimeLockApp(
    prefs: prefs,
    db: db,
    screenTimeService: screenTimeService,
  ));
}

class PetTimeLockApp extends StatefulWidget {
  final SharedPreferences prefs;
  final DatabaseHelper db;
  final ScreenTimeService screenTimeService;

  const PetTimeLockApp({
    super.key,
    required this.prefs,
    required this.db,
    required this.screenTimeService,
  });

  @override
  State<PetTimeLockApp> createState() => _PetTimeLockAppState();
}

class _PetTimeLockAppState extends State<PetTimeLockApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleOverlayPendingAction();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleOverlayPendingAction();
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
        );
      case OverlayPayload.play:
        _navigateAndExecute(
          (context) => context.read<PetCubit>().playWithPet(),
          '玩耍很开心！',
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
        // No special navigation; returning to home is enough.
        break;
    }
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  void _navigateAndExecute(
    Future<InteractionResult> Function(BuildContext context) action,
    String fallbackMessage,
  ) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigator.context;
      if (context.mounted) {
        final result = await action(context);
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => PetCubit(widget.db, widget.prefs),
          ),
          BlocProvider(
            create: (_) => ContentCubit(widget.db),
          ),
        ],
        child: MaterialApp(
          title: '宠物时间锁',
          debugShowCheckedModeBanner: false,
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
        ),
      ),
    );
  }
}

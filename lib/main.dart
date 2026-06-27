import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/content_cubit.dart';
import 'bloc/pet_cubit.dart';
import 'data/database_helper.dart';
import 'screens/home_screen.dart';
import 'services/screen_time_service.dart';

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

class PetTimeLockApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DatabaseHelper>.value(value: db),
        RepositoryProvider<ScreenTimeService>.value(value: screenTimeService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => PetCubit(db, prefs),
          ),
          BlocProvider(
            create: (_) => ContentCubit(db),
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

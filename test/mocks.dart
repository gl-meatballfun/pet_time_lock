import 'package:mocktail/mocktail.dart';
import 'package:pet_time_lock/data/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

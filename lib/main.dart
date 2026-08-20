import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_preferences.dart';
import 'core/services/sms_sync_service.dart';
import 'data/datasources/transaction_local_datasource.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final appPreferences = AppPreferences(prefs);
  final localDataSource = TransactionLocalDataSourceImpl(prefs);
  final repository = TransactionRepositoryImpl(localDataSource);
  final syncService = SmsSyncService(
    repository: repository,
    preferences: appPreferences,
  );

  runApp(
    MyApp(
      preferences: appPreferences,
      repository: repository,
      syncService: syncService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppPreferences preferences;
  final TransactionRepositoryImpl repository;
  final SmsSyncService syncService;

  const MyApp({
    super.key,
    required this.preferences,
    required this.repository,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'xBudget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: HomeScreen(
        preferences: preferences,
        repository: repository,
        syncService: syncService,
      ),
    );
  }
}

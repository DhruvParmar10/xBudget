import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/services/google_sheets_service.dart';
import 'package:xbudget/core/services/sms_sync_service.dart';
import 'package:xbudget/features/balance/domain/usecases/clear_balance_usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/get_balance_usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/set_balance_usecase.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_bloc.dart';
import 'package:xbudget/features/sync/domain/usecases/clear_all_data_usecase.dart';
import 'package:xbudget/features/sync/domain/usecases/google_auth_usecases.dart';
import 'package:xbudget/features/sync/domain/usecases/inject_sample_sms_usecase.dart';
import 'package:xbudget/features/sync/domain/usecases/sync_sms_usecase.dart';
import 'package:xbudget/features/sync/domain/usecases/sync_to_google_sheets_usecase.dart';
import 'package:xbudget/features/sync/presentation/bloc/google_sheets_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:xbudget/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:xbudget/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:xbudget/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/get_spend_breakdown_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/get_total_income_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/get_total_spend_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/manage_category_rules_usecase.dart';
import 'package:xbudget/features/transactions/domain/usecases/update_transaction_category_usecase.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies({SharedPreferences? mockPrefs}) async {
  // Clear any existing registrations (useful for tests)
  if (sl.isRegistered<SharedPreferences>()) {
    await sl.reset();
  }

  // ---------------------------------------------------------------------------
  // External & Core
  // ---------------------------------------------------------------------------
  final sharedPreferences = mockPrefs ?? await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<AppPreferences>(() => AppPreferences(sl()));

  // ---------------------------------------------------------------------------
  // Data Sources & Repositories
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl()),
  );

  // ---------------------------------------------------------------------------
  // Services
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton<SmsSyncService>(
    () => SmsSyncService(
      repository: sl(),
      preferences: sl(),
    ),
  );

  sl.registerLazySingleton<GoogleSheetsService>(
    () => GoogleSheetsService(
      initialSpreadsheetId: sl<AppPreferences>().googleSheetId,
    ),
  );

  // ---------------------------------------------------------------------------
  // Use Cases - Transactions
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetSpendBreakdownUseCase(sl()));
  sl.registerLazySingleton(() => GetTotalSpendUseCase(sl()));
  sl.registerLazySingleton(() => GetTotalIncomeUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionCategoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => SaveCategoryRuleUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoryRulesUseCase(sl()));

  // ---------------------------------------------------------------------------
  // Use Cases - Balance
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton(
    () => GetBalanceUseCase(
      preferences: sl(),
      repository: sl(),
    ),
  );
  sl.registerLazySingleton(() => SetBalanceUseCase(sl()));
  sl.registerLazySingleton(() => ClearBalanceUseCase(sl()));

  // ---------------------------------------------------------------------------
  // Use Cases - Sync & Google Sheets
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton(() => SyncSmsUseCase(sl()));
  sl.registerLazySingleton(() => InjectSampleSmsUseCase(sl()));
  sl.registerLazySingleton(
    () => ClearAllDataUseCase(preferences: sl(), repository: sl()),
  );
  sl.registerLazySingleton(
    () => SignInGoogleUseCase(
      googleSheetsService: sl(),
      preferences: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => SignOutGoogleUseCase(
      googleSheetsService: sl(),
      preferences: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => GetGoogleAuthStatusUseCase(
      googleSheetsService: sl(),
      preferences: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => SyncToGoogleSheetsUseCase(
      googleSheetsService: sl(),
      repository: sl(),
      preferences: sl(),
    ),
  );

  // ---------------------------------------------------------------------------
  // Blocs
  // ---------------------------------------------------------------------------
  sl.registerFactory(
    () => TransactionBloc(
      getTransactionsUseCase: sl<GetTransactionsUseCase>(),
      getSpendBreakdownUseCase: sl<GetSpendBreakdownUseCase>(),
      getTotalSpendUseCase: sl<GetTotalSpendUseCase>(),
      getTotalIncomeUseCase: sl<GetTotalIncomeUseCase>(),
      updateTransactionCategoryUseCase: sl<UpdateTransactionCategoryUseCase>(),
      deleteTransactionUseCase: sl<DeleteTransactionUseCase>(),
      addTransactionUseCase: sl<AddTransactionUseCase>(),
      preferences: sl.isRegistered<AppPreferences>() ? sl<AppPreferences>() : null,
    ),
  );

  sl.registerFactory(
    () => BalanceBloc(
      getBalanceUseCase: sl(),
      setBalanceUseCase: sl(),
      clearBalanceUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => SyncBloc(
      syncSmsUseCase: sl(),
      injectSampleSmsUseCase: sl(),
      clearAllDataUseCase: sl(),
      preferences: sl(),
    ),
  );

  sl.registerFactory(
    () => GoogleSheetsBloc(
      signInGoogleUseCase: sl(),
      signOutGoogleUseCase: sl(),
      getGoogleAuthStatusUseCase: sl(),
      syncToGoogleSheetsUseCase: sl(),
      preferences: sl(),
    ),
  );
}

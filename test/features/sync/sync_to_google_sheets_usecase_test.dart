import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/services/google_sheets_service.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/sync/domain/usecases/sync_to_google_sheets_usecase.dart';
import 'package:xbudget/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:xbudget/features/transactions/data/models/transaction_model.dart';
import 'package:xbudget/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';

class FakeGoogleSheetsService extends GoogleSheetsService {
  bool syncCalled = false;
  GoogleSheetsSyncSummary? summaryToReturn;

  @override
  String? get currentEmail => 'testuser@gmail.com';

  @override
  Future<GoogleSheetsSyncSummary> syncTransactions(
    List<TransactionEntity> transactions,
  ) async {
    syncCalled = true;
    return summaryToReturn ??
        GoogleSheetsSyncSummary(
          totalLocalTransactions: transactions.length,
          newRowsAppended: transactions.length,
          spreadsheetId: 'test-sheet-id-123',
          syncTimestamp: DateTime(2026, 8, 21, 10, 0),
        );
  }
}

void main() {
  group('SyncToGoogleSheetsUseCase Tests', () {
    late AppPreferences preferences;
    late TransactionRepositoryImpl repository;
    late FakeGoogleSheetsService fakeService;
    late SyncToGoogleSheetsUseCase useCase;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      preferences = AppPreferences(prefs);
      final dataSource = TransactionLocalDataSourceImpl(prefs);
      repository = TransactionRepositoryImpl(dataSource);
      fakeService = FakeGoogleSheetsService();

      useCase = SyncToGoogleSheetsUseCase(
        googleSheetsService: fakeService,
        repository: repository,
        preferences: preferences,
      );
    });

    test('successfully syncs transactions and updates preferences', () async {
      // Add sample transactions
      final txn = TransactionModel(
        id: 'txn-1',
        amount: 250.0,
        merchant: 'Cafe Coffee Day',
        transactionType: 'expense',
        category: BudgetCategory.food,
        isP2P: false,
        date: DateTime(2026, 8, 20),
        rawMessage: 'Rs 250 debited',
        createdAt: DateTime(2026, 8, 20),
      );
      await repository.saveTransactions([txn]);

      final result = await useCase(const NoParams());

      expect(fakeService.syncCalled, isTrue);
      expect(result.isSuccess, isTrue);
      expect(result.totalLocalTransactions, equals(1));
      expect(result.spreadsheetId, equals('test-sheet-id-123'));

      // Verify preferences updated
      expect(preferences.googleSheetId, equals('test-sheet-id-123'));
      expect(preferences.lastGoogleSheetSyncTimestamp, isNotNull);
      expect(preferences.googleAccountEmail, equals('testuser@gmail.com'));
    });

    test('handles failure without updating invalid preferences', () async {
      fakeService.summaryToReturn = GoogleSheetsSyncSummary(
        totalLocalTransactions: 0,
        newRowsAppended: 0,
        spreadsheetId: '',
        syncTimestamp: DateTime(2026, 8, 21),
        errorMessage: 'Authentication expired',
      );

      final result = await useCase(const NoParams());

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, equals('Authentication expired'));
      expect(preferences.googleSheetId, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/balance/data/datasources/balance_log_local_datasource.dart';
import 'package:xbudget/features/balance/data/repositories/balance_log_repository_impl.dart';
import 'package:xbudget/features/balance/domain/entities/balance_log_entity.dart';
import 'package:xbudget/features/balance/domain/repositories/balance_log_repository.dart';
import 'package:xbudget/features/balance/domain/usecases/get_balance_usecase.dart';
import 'package:xbudget/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:xbudget/features/transactions/data/models/transaction_model.dart';
import 'package:xbudget/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

void main() {
  late AppPreferences preferences;
  late TransactionRepository repository;
  late BalanceLogRepository balanceLogRepository;
  late GetBalanceUseCase getBalanceUseCase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    preferences = AppPreferences(prefs);
    final dataSource = TransactionLocalDataSourceImpl(prefs);
    repository = TransactionRepositoryImpl(dataSource);
    balanceLogRepository = BalanceLogRepositoryImpl(
      localDataSource: BalanceLogLocalDataSourceImpl(prefs),
    );
    getBalanceUseCase = GetBalanceUseCase(
      preferences: preferences,
      repository: repository,
      balanceLogRepository: balanceLogRepository,
    );
  });

  group('GetBalanceUseCase Calculated Balance & Logs Tests', () {
    test('returns null balance if no balance was ever recorded', () async {
      final result = await getBalanceUseCase(const NoParams());
      expect(result.currentBalance, isNull);
      expect(result.balanceUpdatedAt, isNull);
      expect(result.balanceLogs, isEmpty);
    });

    test('migrates existing legacy preferences balance to opening balance log', () async {
      final now = DateTime(2026, 8, 24, 10, 0);
      await preferences.setCurrentBalance(10000.0, source: 'manual', updatedAt: now);

      final result = await getBalanceUseCase(const NoParams());
      expect(result.currentBalance, equals(10000.0));
      expect(result.balanceSource, equals('manual'));
      expect(result.balanceLogs.length, equals(1));
      expect(result.balanceLogs.first.adjustmentAmount, equals(10000.0));
      expect(result.balanceLogs.first.source, equals('manual'));
    });

    test('deducts expenses occurring after opening balance', () async {
      final baseTime = DateTime(2026, 8, 24, 10, 0);
      final openingLog = BalanceLogEntity(
        id: 'opening_1',
        timestamp: baseTime,
        previousBalance: 0.0,
        adjustmentAmount: 20000.0,
        resultingBalance: 20000.0,
        source: 'opening',
        note: 'Opening Balance',
        createdAt: baseTime,
      );
      await balanceLogRepository.addBalanceLog(openingLog);

      // Add transaction BEFORE baseTime (should NOT deduct)
      final priorTxn = TransactionModel(
        id: 'txn_prior',
        amount: 500.0,
        merchant: 'Old Grocery',
        transactionType: 'expense',
        category: BudgetCategory.groceries,
        isP2P: false,
        date: DateTime(2026, 8, 24, 9, 0),
        rawMessage: 'old message',
        createdAt: baseTime,
      );
      await repository.saveTransaction(priorTxn);

      // Add expense AFTER baseTime (SHOULD deduct)
      final afterTxn = TransactionModel(
        id: 'txn_after_expense',
        amount: 1500.0,
        merchant: 'Swiggy',
        transactionType: 'expense',
        category: BudgetCategory.food,
        isP2P: false,
        date: DateTime(2026, 8, 24, 12, 0),
        rawMessage: 'swiggy message',
        createdAt: baseTime,
      );
      await repository.saveTransaction(afterTxn);

      final result = await getBalanceUseCase(const NoParams());
      // 20000 - 1500 = 18500 (prior 500 not deducted)
      expect(result.currentBalance, equals(18500.0));
    });

    test('applies manual adjustment log: Balance - 5000 = Balance', () async {
      final baseTime = DateTime(2026, 8, 24, 10, 0);
      final openingLog = BalanceLogEntity(
        id: 'opening_1',
        timestamp: baseTime,
        previousBalance: 0.0,
        adjustmentAmount: 25000.0,
        resultingBalance: 25000.0,
        source: 'opening',
        note: 'Opening Balance',
        createdAt: baseTime,
      );
      await balanceLogRepository.addBalanceLog(openingLog);

      // Add adjustment: -5000
      final adjTime = DateTime(2026, 8, 24, 11, 0);
      final adjustmentLog = BalanceLogEntity(
        id: 'adj_1',
        timestamp: adjTime,
        previousBalance: 25000.0,
        adjustmentAmount: -5000.0,
        resultingBalance: 20000.0,
        source: 'manual',
        note: 'Cash expense correction',
        createdAt: adjTime,
      );
      await balanceLogRepository.addBalanceLog(adjustmentLog);

      final result = await getBalanceUseCase(const NoParams());
      // 25000 - 5000 = 20000
      expect(result.currentBalance, equals(20000.0));
      expect(result.balanceLogs.length, equals(2));
    });

    test('deleting a wrongly subtracted log instantly rolls back the balance', () async {
      final baseTime = DateTime(2026, 8, 24, 10, 0);
      final openingLog = BalanceLogEntity(
        id: 'opening_1',
        timestamp: baseTime,
        previousBalance: 0.0,
        adjustmentAmount: 25000.0,
        resultingBalance: 25000.0,
        source: 'opening',
        note: 'Opening Balance',
        createdAt: baseTime,
      );
      await balanceLogRepository.addBalanceLog(openingLog);

      final adjTime = DateTime(2026, 8, 24, 11, 0);
      final wrongLog = BalanceLogEntity(
        id: 'wrong_sub_1',
        timestamp: adjTime,
        previousBalance: 25000.0,
        adjustmentAmount: -5000.0,
        resultingBalance: 20000.0,
        source: 'manual',
        note: 'Wrongly subtracted',
        createdAt: adjTime,
      );
      await balanceLogRepository.addBalanceLog(wrongLog);

      // Verify balance is 20000
      var result = await getBalanceUseCase(const NoParams());
      expect(result.currentBalance, equals(20000.0));

      // Delete the wrongly subtracted log
      await balanceLogRepository.deleteBalanceLog('wrong_sub_1');

      // Balance immediately rolls back to 25000
      result = await getBalanceUseCase(const NoParams());
      expect(result.currentBalance, equals(25000.0));
      expect(result.balanceLogs.length, equals(1));
    });

    test('updating an adjustment log recalculates the calculated balance', () async {
      final baseTime = DateTime(2026, 8, 24, 10, 0);
      final openingLog = BalanceLogEntity(
        id: 'opening_1',
        timestamp: baseTime,
        previousBalance: 0.0,
        adjustmentAmount: 25000.0,
        resultingBalance: 25000.0,
        source: 'opening',
        note: 'Opening Balance',
        createdAt: baseTime,
      );
      await balanceLogRepository.addBalanceLog(openingLog);

      final adjTime = DateTime(2026, 8, 24, 11, 0);
      final log = BalanceLogEntity(
        id: 'adj_edit',
        timestamp: adjTime,
        previousBalance: 25000.0,
        adjustmentAmount: -5000.0,
        resultingBalance: 20000.0,
        source: 'manual',
        note: 'Initial mistake',
        createdAt: adjTime,
      );
      await balanceLogRepository.addBalanceLog(log);

      // Correct the adjustment from -5000 to -2000
      final updatedLog = log.copyWith(
        adjustmentAmount: -2000.0,
        resultingBalance: 23000.0,
        note: 'Corrected amount',
      );
      await balanceLogRepository.updateBalanceLog(updatedLog);

      final result = await getBalanceUseCase(const NoParams());
      // 25000 - 2000 = 23000
      expect(result.currentBalance, equals(23000.0));
    });
  });
}

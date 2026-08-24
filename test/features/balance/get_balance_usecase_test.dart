import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/get_balance_usecase.dart';
import 'package:xbudget/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:xbudget/features/transactions/data/models/transaction_model.dart';
import 'package:xbudget/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

void main() {
  late AppPreferences preferences;
  late TransactionRepository repository;
  late GetBalanceUseCase getBalanceUseCase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    preferences = AppPreferences(prefs);
    final dataSource = TransactionLocalDataSourceImpl(prefs);
    repository = TransactionRepositoryImpl(dataSource);
    getBalanceUseCase = GetBalanceUseCase(
      preferences: preferences,
      repository: repository,
    );
  });

  group('GetBalanceUseCase Dynamic Balance Tests', () {
    test('returns null balance if no balance was ever recorded', () async {
      final result = await getBalanceUseCase(const NoParams());
      expect(result.currentBalance, isNull);
      expect(result.balanceUpdatedAt, isNull);
    });

    test('returns recorded base balance when no subsequent transactions exist', () async {
      final now = DateTime.now();
      await preferences.setCurrentBalance(10000.0, source: 'manual', updatedAt: now);

      final result = await getBalanceUseCase(const NoParams());
      expect(result.currentBalance, equals(10000.0));
      expect(result.balanceSource, equals('manual'));
    });

    test('deducts expenses occurring after balanceUpdatedAt', () async {
      final baseTime = DateTime(2026, 8, 24, 10, 0);
      await preferences.setCurrentBalance(20000.0, source: 'manual', updatedAt: baseTime);

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

    test('adds income occurring after balanceUpdatedAt', () async {
      final baseTime = DateTime(2026, 8, 24, 10, 0);
      await preferences.setCurrentBalance(10000.0, source: 'manual', updatedAt: baseTime);

      final incomeTxn = TransactionModel(
        id: 'txn_income',
        amount: 3000.0,
        merchant: 'Freelance Client',
        transactionType: 'income',
        category: BudgetCategory.salary,
        isP2P: false,
        date: DateTime(2026, 8, 24, 14, 0),
        rawMessage: 'credited message',
        createdAt: baseTime,
      );
      await repository.saveTransaction(incomeTxn);

      final result = await getBalanceUseCase(const NoParams());
      // 10000 + 3000 = 13000
      expect(result.currentBalance, equals(13000.0));
    });

    test('correctly handles mixed expenses and incomes after balanceUpdatedAt', () async {
      final baseTime = DateTime(2026, 8, 24, 10, 0);
      await preferences.setCurrentBalance(50000.0, source: 'manual', updatedAt: baseTime);

      final expense1 = TransactionModel(
        id: 'txn_exp1',
        amount: 2500.0,
        merchant: 'Blinkit',
        transactionType: 'expense',
        category: BudgetCategory.groceries,
        isP2P: false,
        date: DateTime(2026, 8, 24, 11, 0),
        rawMessage: 'msg1',
        createdAt: baseTime,
      );

      final income1 = TransactionModel(
        id: 'txn_inc1',
        amount: 10000.0,
        merchant: 'Bonus',
        transactionType: 'income',
        category: BudgetCategory.salary,
        isP2P: false,
        date: DateTime(2026, 8, 24, 13, 0),
        rawMessage: 'msg2',
        createdAt: baseTime,
      );

      final expense2 = TransactionModel(
        id: 'txn_exp2',
        amount: 750.0,
        merchant: 'Uber',
        transactionType: 'expense',
        category: BudgetCategory.transport,
        isP2P: false,
        date: DateTime(2026, 8, 24, 15, 0),
        rawMessage: 'msg3',
        createdAt: baseTime,
      );

      await repository.saveTransactions([expense1, income1, expense2]);

      final result = await getBalanceUseCase(const NoParams());
      // 50000 - 2500 + 10000 - 750 = 56750
      expect(result.currentBalance, equals(56750.0));
    });
  });
}

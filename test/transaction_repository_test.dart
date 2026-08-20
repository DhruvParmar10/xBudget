import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:xbudget/features/transactions/data/models/transaction_model.dart';
import 'package:xbudget/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

void main() {
  group('TransactionRepository & LocalDataSource Tests', () {
    late TransactionRepository repository;
    late TransactionLocalDataSource localDataSource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      localDataSource = TransactionLocalDataSourceImpl(prefs);
      repository = TransactionRepositoryImpl(localDataSource);
    });

    TransactionEntity createTxn({
      required String merchant,
      required double amount,
      required DateTime date,
      BudgetCategory category = BudgetCategory.food,
      String transactionType = 'expense',
      bool isP2P = false,
      String rawMessage = 'Test SMS',
    }) {
      final id = TransactionModel.generateId(
        amount: amount,
        merchant: merchant,
        date: date,
        rawMessage: rawMessage,
      );

      return TransactionEntity(
        id: id,
        amount: amount,
        merchant: merchant,
        transactionType: transactionType,
        category: category,
        isP2P: isP2P,
        date: date,
        rawMessage: rawMessage,
        createdAt: DateTime.now(),
      );
    }

    test('should save a transaction and retrieve it successfully', () async {
      final txn = createTxn(
        merchant: 'Swiggy',
        amount: 250.0,
        date: DateTime(2026, 8, 20, 12, 0),
        category: BudgetCategory.food,
      );

      final saved = await repository.saveTransaction(txn);
      expect(saved, isTrue);

      final retrieved = await repository.getTransactionById(txn.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.merchant, equals('Swiggy'));
      expect(retrieved.amount, equals(250.0));
      expect(retrieved.category, equals(BudgetCategory.food));
    });

    test('should deduplicate identical transactions on saveTransaction', () async {
      final txn = createTxn(
        merchant: 'Zomato',
        amount: 400.0,
        date: DateTime(2026, 8, 20, 13, 0),
      );

      final firstSave = await repository.saveTransaction(txn);
      expect(firstSave, isTrue);

      // Attempting to save exact same transaction again
      final secondSave = await repository.saveTransaction(txn);
      expect(secondSave, isFalse); // Rejected as duplicate

      final all = await repository.getTransactions();
      expect(all.length, equals(1));
    });

    test('should deduplicate batch insertions in saveTransactions', () async {
      final txn1 = createTxn(
        merchant: 'Uber',
        amount: 150.0,
        date: DateTime(2026, 8, 20, 9, 0),
        category: BudgetCategory.transport,
      );
      final txn2 = createTxn(
        merchant: 'Blinkit',
        amount: 520.0,
        date: DateTime(2026, 8, 20, 10, 0),
        category: BudgetCategory.groceries,
      );

      // First batch: saves 2
      final addedCount1 = await repository.saveTransactions([txn1, txn2]);
      expect(addedCount1, equals(2));

      final txn3 = createTxn(
        merchant: 'Amazon',
        amount: 1200.0,
        date: DateTime(2026, 8, 20, 11, 0),
        category: BudgetCategory.shopping,
      );

      // Second batch includes duplicate txn1 and new txn3
      final addedCount2 = await repository.saveTransactions([txn1, txn3]);
      expect(addedCount2, equals(1)); // Only txn3 is added

      final all = await repository.getTransactions();
      expect(all.length, equals(3));
    });

    test('should filter transactions by category and date range', () async {
      final txnAug10 = createTxn(
        merchant: 'Swiggy',
        amount: 300.0,
        date: DateTime(2026, 8, 10),
        category: BudgetCategory.food,
      );
      final txnAug20Food = createTxn(
        merchant: 'Zomato',
        amount: 450.0,
        date: DateTime(2026, 8, 20),
        category: BudgetCategory.food,
      );
      final txnAug20Transport = createTxn(
        merchant: 'Uber',
        amount: 200.0,
        date: DateTime(2026, 8, 20),
        category: BudgetCategory.transport,
      );

      await repository.saveTransactions([
        txnAug10,
        txnAug20Food,
        txnAug20Transport,
      ]);

      // Filter by category
      final foodTxns = await repository.getTransactions(
        category: BudgetCategory.food,
      );
      expect(foodTxns.length, equals(2));

      // Filter by date range
      final rangeTxns = await repository.getTransactions(
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 8, 25),
      );
      expect(rangeTxns.length, equals(2));

      // Filter by both
      final combined = await repository.getTransactions(
        startDate: DateTime(2026, 8, 15),
        category: BudgetCategory.food,
      );
      expect(combined.length, equals(1));
      expect(combined.first.merchant, equals('Zomato'));
    });

    test('should update transaction category and mark as user-categorized', () async {
      final txn = createTxn(
        merchant: 'Local Mart',
        amount: 100.0,
        date: DateTime(2026, 8, 20),
        category: BudgetCategory.uncategorized,
      );
      await repository.saveTransaction(txn);

      final updated = await repository.updateTransactionCategory(
        txn.id,
        BudgetCategory.groceries,
      );
      expect(updated, isTrue);

      final retrieved = await repository.getTransactionById(txn.id);
      expect(retrieved!.category, equals(BudgetCategory.groceries));
      expect(retrieved.isUserCategorized, isTrue);
    });

    test('should manage user custom category mapping rules', () async {
      await repository.saveUserCategoryRule('ramesh', BudgetCategory.rent);
      await repository.saveUserCategoryRule(
        'chai point',
        BudgetCategory.food,
      );

      var rules = await repository.getUserCategoryRules();
      expect(rules.length, equals(2));
      expect(rules['ramesh'], equals(BudgetCategory.rent));
      expect(rules['chai point'], equals(BudgetCategory.food));

      await repository.deleteUserCategoryRule('chai point');
      rules = await repository.getUserCategoryRules();
      expect(rules.length, equals(1));
      expect(rules.containsKey('chai point'), isFalse);
    });

    test('should compute total spend and spend by category correctly', () async {
      final txn1 = createTxn(
        merchant: 'Swiggy',
        amount: 500.0,
        date: DateTime(2026, 8, 20),
        category: BudgetCategory.food,
      );
      final txn2 = createTxn(
        merchant: 'Zomato',
        amount: 300.0,
        date: DateTime(2026, 8, 20),
        category: BudgetCategory.food,
      );
      final txn3 = createTxn(
        merchant: 'Uber',
        amount: 200.0,
        date: DateTime(2026, 8, 20),
        category: BudgetCategory.transport,
      );
      final salary = createTxn(
        merchant: 'Employer',
        amount: 50000.0,
        date: DateTime(2026, 8, 20),
        transactionType: 'income',
        category: BudgetCategory.salary,
      );

      await repository.saveTransactions([txn1, txn2, txn3, salary]);

      final totalSpend = await repository.getTotalSpend();
      expect(totalSpend, equals(1000.0)); // 500 + 300 + 200 (excludes salary income)

      final totalIncome = await repository.getTotalIncome();
      expect(totalIncome, equals(50000.0)); // Salary income

      final breakdown = await repository.getSpendByCategory();
      expect(breakdown[BudgetCategory.food], equals(800.0));
      expect(breakdown[BudgetCategory.transport], equals(200.0));
    });
  });


  group('AppPreferences Current Balance Tests', () {
    late AppPreferences preferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      preferences = AppPreferences(prefs);
    });

    test('should start with null current balance', () {
      expect(preferences.currentBalance, isNull);
      expect(preferences.balanceUpdatedAt, isNull);
      expect(preferences.balanceSource, equals('manual'));
    });

    test('should set and get current balance with timestamp and source', () async {
      final now = DateTime(2026, 8, 20, 16, 0);
      await preferences.setCurrentBalance(
        45250.75,
        source: 'manual',
        updatedAt: now,
      );

      expect(preferences.currentBalance, equals(45250.75));
      expect(preferences.balanceSource, equals('manual'));
      expect(preferences.balanceUpdatedAt, equals(now));
    });

    test('should clear current balance', () async {
      await preferences.setCurrentBalance(15000.0, source: 'sms');
      expect(preferences.currentBalance, equals(15000.0));

      await preferences.clearCurrentBalance();
      expect(preferences.currentBalance, isNull);
      expect(preferences.balanceUpdatedAt, isNull);
    });
  });
}

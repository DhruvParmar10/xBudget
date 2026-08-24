import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:xbudget/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:xbudget/features/transactions/domain/usecases/add_transaction_usecase.dart';

void main() {
  late TransactionRepository repository;
  late AddTransactionUseCase addTransactionUseCase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dataSource = TransactionLocalDataSourceImpl(prefs);
    repository = TransactionRepositoryImpl(dataSource);
    addTransactionUseCase = AddTransactionUseCase(repository);
  });

  group('AddTransactionUseCase Tests', () {
    test('adds an expense transaction successfully', () async {
      final now = DateTime.now();
      final success = await addTransactionUseCase(
        AddTransactionParams(
          amount: 450.0,
          merchant: 'Starbucks',
          transactionType: 'expense',
          category: BudgetCategory.food,
          date: now,
          note: 'Morning latte',
        ),
      );

      expect(success, isTrue);

      final txns = await repository.getTransactions();
      expect(txns.length, equals(1));
      expect(txns.first.merchant, equals('Starbucks'));
      expect(txns.first.amount, equals(450.0));
      expect(txns.first.isExpense, isTrue);
      expect(txns.first.category, equals(BudgetCategory.food));
      expect(txns.first.note, equals('Morning latte'));
    });

    test('adds an income transaction successfully', () async {
      final now = DateTime.now();
      final success = await addTransactionUseCase(
        AddTransactionParams(
          amount: 50000.0,
          merchant: 'Monthly Salary',
          transactionType: 'income',
          category: BudgetCategory.salary,
          date: now,
        ),
      );

      expect(success, isTrue);

      final txns = await repository.getTransactions();
      expect(txns.length, equals(1));
      expect(txns.first.merchant, equals('Monthly Salary'));
      expect(txns.first.amount, equals(50000.0));
      expect(txns.first.isIncome, isTrue);
    });
  });
}

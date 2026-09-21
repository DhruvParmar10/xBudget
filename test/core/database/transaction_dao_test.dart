import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:xbudget/core/database/app_database.dart';
import 'package:xbudget/core/database/daos/transaction_dao.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';

void main() {
  group('TransactionDao Tests', () {
    late AppDatabase db;
    late TransactionDao dao;

    setUp(() {
      db = AppDatabase.inMemory();
      dao = db.transactionDao;
    });

    tearDown(() async {
      await db.close();
    });

    TransactionsCompanion createCompanion({
      required String id,
      required double amount,
      required String merchant,
      required DateTime date,
      BudgetCategory category = BudgetCategory.food,
      String transactionType = 'expense',
      String rawMessage = 'Test SMS',
      String? note,
    }) {
      return TransactionsCompanion(
        id: Value(id),
        amount: Value(amount),
        merchant: Value(merchant),
        transactionType: Value(transactionType),
        category: Value(category),
        isP2P: const Value(false),
        date: Value(date),
        rawMessage: Value(rawMessage),
        isUserCategorized: const Value(false),
        note: Value(note),
        createdAt: Value(DateTime.now()),
      );
    }

    test('inserts and retrieves all transactions sorted descending by date', () async {
      final t1 = createCompanion(
        id: '1',
        amount: 100.0,
        merchant: 'Swiggy',
        date: DateTime(2026, 8, 10),
      );
      final t2 = createCompanion(
        id: '2',
        amount: 200.0,
        merchant: 'Zomato',
        date: DateTime(2026, 8, 20),
      );

      await dao.insertTransaction(t1);
      await dao.insertTransaction(t2);

      final all = await dao.getAllTransactions();
      expect(all.length, equals(2));
      expect(all.first.id, equals('2')); // Newest first
      expect(all.last.id, equals('1'));
    });

    test('deduplicates transaction by primary key on insertTransaction', () async {
      final t1 = createCompanion(
        id: 'unique_id_1',
        amount: 100.0,
        merchant: 'Uber',
        date: DateTime(2026, 8, 10),
      );

      final first = await dao.insertTransaction(t1);
      expect(first, isTrue);

      final second = await dao.insertTransaction(t1);
      expect(second, isFalse);

      final all = await dao.getAllTransactions();
      expect(all.length, equals(1));
    });

    test('batch inserts transactions and deduplicates', () async {
      final t1 = createCompanion(
        id: 'batch_1',
        amount: 50.0,
        merchant: 'Chai Point',
        date: DateTime(2026, 8, 1),
      );
      final t2 = createCompanion(
        id: 'batch_2',
        amount: 75.0,
        merchant: 'Starbucks',
        date: DateTime(2026, 8, 2),
      );

      final added1 = await dao.insertTransactions([t1, t2]);
      expect(added1, equals(2));

      final t3 = createCompanion(
        id: 'batch_3',
        amount: 120.0,
        merchant: 'Costa',
        date: DateTime(2026, 8, 3),
      );

      // Batch with existing t1 and new t3
      final added2 = await dao.insertTransactions([t1, t3]);
      expect(added2, equals(1));

      final all = await dao.getAllTransactions();
      expect(all.length, equals(3));
    });

    test('filters transactions by date range, category, and text query', () async {
      final t1 = createCompanion(
        id: '1',
        amount: 150.0,
        merchant: 'Swiggy',
        category: BudgetCategory.food,
        date: DateTime(2026, 8, 10),
      );
      final t2 = createCompanion(
        id: '2',
        amount: 400.0,
        merchant: 'Uber',
        category: BudgetCategory.transport,
        date: DateTime(2026, 8, 15),
      );
      final t3 = createCompanion(
        id: '3',
        amount: 600.0,
        merchant: 'Amazon',
        category: BudgetCategory.shopping,
        date: DateTime(2026, 8, 20),
        note: 'Electronics purchase',
      );

      await dao.insertTransactions([t1, t2, t3]);

      // Filter by category
      final foodOnly = await dao.getFilteredTransactions(category: BudgetCategory.food);
      expect(foodOnly.length, equals(1));
      expect(foodOnly.first.id, equals('1'));

      // Filter by date range
      final range = await dao.getFilteredTransactions(
        startDate: DateTime(2026, 8, 12),
        endDate: DateTime(2026, 8, 22),
      );
      expect(range.length, equals(2));

      // Filter by query in note
      final search = await dao.getFilteredTransactions(query: 'electronics');
      expect(search.length, equals(1));
      expect(search.first.id, equals('3'));
    });

    test('computes total spend, total income, and spend by category via SQL aggregations', () async {
      final e1 = createCompanion(
        id: '1',
        amount: 300.0,
        merchant: 'Swiggy',
        category: BudgetCategory.food,
        transactionType: 'expense',
        date: DateTime(2026, 8, 10),
      );
      final e2 = createCompanion(
        id: '2',
        amount: 200.0,
        merchant: 'Zomato',
        category: BudgetCategory.food,
        transactionType: 'expense',
        date: DateTime(2026, 8, 12),
      );
      final e3 = createCompanion(
        id: '3',
        amount: 500.0,
        merchant: 'Uber',
        category: BudgetCategory.transport,
        transactionType: 'expense',
        date: DateTime(2026, 8, 15),
      );
      final income = createCompanion(
        id: '4',
        amount: 50000.0,
        merchant: 'Employer',
        category: BudgetCategory.salary,
        transactionType: 'income',
        date: DateTime(2026, 8, 1),
      );

      await dao.insertTransactions([e1, e2, e3, income]);

      final totalSpend = await dao.getTotalSpend();
      expect(totalSpend, equals(1000.0)); // 300 + 200 + 500

      final totalIncome = await dao.getTotalIncome();
      expect(totalIncome, equals(50000.0));

      final breakdown = await dao.getSpendByCategory();
      expect(breakdown[BudgetCategory.food], equals(500.0));
      expect(breakdown[BudgetCategory.transport], equals(500.0));
      expect(breakdown.containsKey(BudgetCategory.salary), isFalse);
    });

    test('updates category and deletes transaction', () async {
      final t = createCompanion(
        id: 't_update',
        amount: 100.0,
        merchant: 'Vendor',
        category: BudgetCategory.uncategorized,
        date: DateTime(2026, 8, 10),
      );
      await dao.insertTransaction(t);

      final updated = await dao.updateCategory('t_update', BudgetCategory.groceries);
      expect(updated, isTrue);

      final retrieved = await dao.getTransactionById('t_update');
      expect(retrieved!.category, equals(BudgetCategory.groceries));
      expect(retrieved.isUserCategorized, isTrue);

      final deleted = await dao.deleteTransaction('t_update');
      expect(deleted, isTrue);
      expect(await dao.getTransactionById('t_update'), isNull);
    });
  });
}

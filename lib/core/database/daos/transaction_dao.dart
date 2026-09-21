import 'package:drift/drift.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import '../app_database.dart';
import '../tables.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// Retrieves all transactions sorted descending by date.
  Future<List<Transaction>> getAllTransactions() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Retrieves filtered transactions with optional date range, category, query, and type.
  Future<List<Transaction>> getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    BudgetCategory? category,
    String? query,
    String? transactionType,
  }) {
    return (select(transactions)
          ..where((t) {
            final List<Expression<bool>> predicates = [];
            if (startDate != null) {
              predicates.add(t.date.isBiggerOrEqualValue(startDate));
            }
            if (endDate != null) {
              predicates.add(t.date.isSmallerOrEqualValue(endDate));
            }
            if (category != null) {
              predicates.add(t.category.equals(category.name));
            }
            if (transactionType != null) {
              predicates.add(
                t.transactionType.lower().equals(transactionType.toLowerCase()),
              );
            }
            if (query != null && query.trim().isNotEmpty) {
              final q = '%${query.trim().toLowerCase()}%';
              predicates.add(
                t.merchant.lower().like(q) |
                    t.note.lower().like(q) |
                    t.rawMessage.lower().like(q),
              );
            }
            return predicates.isEmpty
                ? const Constant(true)
                : Expression.and(predicates);
          })
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Finds a single transaction by ID.
  Future<Transaction?> getTransactionById(String id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Checks if a transaction with the given ID exists.
  Future<bool> hasTransaction(String id) async {
    final item = await getTransactionById(id);
    return item != null;
  }

  /// Saves a single transaction. Deduplicates: returns false if already exists.
  Future<bool> insertTransaction(TransactionsCompanion entry) async {
    final existing = await hasTransaction(entry.id.value);
    if (existing) {
      return false;
    }
    await into(transactions).insert(entry);
    return true;
  }

  /// Batch inserts transactions. Returns count of newly inserted rows.
  Future<int> insertTransactions(List<TransactionsCompanion> entries) async {
    return await transaction(() async {
      int addedCount = 0;
      for (final entry in entries) {
        final existing = await hasTransaction(entry.id.value);
        if (!existing) {
          await into(transactions).insert(entry);
          addedCount++;
        }
      }
      return addedCount;
    });
  }

  /// Updates an existing transaction. Returns true if updated.
  Future<bool> updateTransaction(TransactionsCompanion entry) async {
    final count = await (update(transactions)
          ..where((t) => t.id.equals(entry.id.value)))
        .write(entry);
    return count > 0;
  }

  /// Updates a transaction's category.
  Future<bool> updateCategory(
    String id,
    BudgetCategory category, {
    bool isUserCategorized = true,
  }) async {
    final count = await (update(transactions)..where((t) => t.id.equals(id)))
        .write(
      TransactionsCompanion(
        category: Value(category),
        isUserCategorized: Value(isUserCategorized),
      ),
    );
    return count > 0;
  }

  /// Deletes a transaction by ID.
  Future<bool> deleteTransaction(String id) async {
    final count =
        await (delete(transactions)..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  /// Computes total spend using SQL SUM aggregation for expense transactions.
  Future<double> getTotalSpend({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([amountSum])
      ..where(transactions.transactionType.lower().equals('expense'));

    if (startDate != null) {
      query.where(transactions.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(transactions.date.isSmallerOrEqualValue(endDate));
    }

    final row = await query.getSingle();
    return row.read(amountSum) ?? 0.0;
  }

  /// Computes total income using SQL SUM aggregation for income transactions.
  Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([amountSum])
      ..where(transactions.transactionType.lower().equals('income'));

    if (startDate != null) {
      query.where(transactions.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(transactions.date.isSmallerOrEqualValue(endDate));
    }

    final row = await query.getSingle();
    return row.read(amountSum) ?? 0.0;
  }

  /// Computes spend breakdown by category using SQL GROUP BY aggregation.
  Future<Map<BudgetCategory, double>> getSpendByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.category, amountSum])
      ..where(transactions.transactionType.lower().equals('expense'))
      ..groupBy([transactions.category]);

    if (startDate != null) {
      query.where(transactions.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(transactions.date.isSmallerOrEqualValue(endDate));
    }

    final rows = await query.get();
    final Map<BudgetCategory, double> breakdown = {};
    for (final row in rows) {
      final catStr = row.read(transactions.category);
      final sum = row.read(amountSum) ?? 0.0;
      if (catStr != null) {
        final cat = BudgetCategory.fromString(catStr);
        breakdown[cat] = sum;
      }
    }
    return breakdown;
  }

  /// Clears all transactions.
  Future<void> clearAll() async {
    await delete(transactions).go();
  }
}

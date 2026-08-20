import '../entities/budget_category.dart';
import '../entities/transaction_entity.dart';

/// Contract for transaction persistence and local queries.
abstract class TransactionRepository {
  /// Fetches stored transactions with optional filters.
  Future<List<TransactionEntity>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    BudgetCategory? category,
    String? query,
    String? transactionType,
  });

  /// Retrieves a single transaction by its unique deterministic ID.
  Future<TransactionEntity?> getTransactionById(String id);

  /// Saves a single transaction. Returns `true` if saved, `false` if already existed (duplicate).
  Future<bool> saveTransaction(TransactionEntity transaction);

  /// Saves a batch of transactions with automatic deduplication.
  /// Returns the count of newly added non-duplicate transactions.
  Future<int> saveTransactions(List<TransactionEntity> transactions);

  /// Updates an existing transaction.
  Future<bool> updateTransaction(TransactionEntity transaction);

  /// Updates the category of a transaction and marks it as user-categorized.
  Future<bool> updateTransactionCategory(
    String id,
    BudgetCategory category, {
    bool isUserCategorized = true,
  });

  /// Deletes a transaction by ID.
  Future<bool> deleteTransaction(String id);

  /// Checks if a transaction with the given ID already exists in storage.
  Future<bool> exists(String id);

  /// Retrieves user-defined custom category mapping rules.
  Future<Map<String, BudgetCategory>> getUserCategoryRules();

  /// Saves or updates a user-defined category mapping rule.
  Future<void> saveUserCategoryRule(
    String merchantKeyword,
    BudgetCategory category,
  );

  /// Deletes a user-defined category mapping rule.
  Future<void> deleteUserCategoryRule(String merchantKeyword);

  /// Computes total spend (expenses) for a given date range.
  Future<double> getTotalSpend({DateTime? startDate, DateTime? endDate});

  /// Computes spend breakdown grouped by category for a given date range.
  Future<Map<BudgetCategory, double>> getSpendByCategory({
    DateTime? startDate,
    DateTime? endDate,
  });
}

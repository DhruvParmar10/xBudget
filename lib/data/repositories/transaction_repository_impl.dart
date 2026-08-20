import '../../domain/entities/budget_category.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../models/transaction_model.dart';

/// Implementation of [TransactionRepository] using [TransactionLocalDataSource].
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource _localDataSource;

  TransactionRepositoryImpl(this._localDataSource);

  @override
  Future<List<TransactionEntity>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    BudgetCategory? category,
    String? query,
    String? transactionType,
  }) async {
    final models = await _localDataSource.getAllTransactions();

    return models.where((txn) {
      if (startDate != null && txn.date.isBefore(startDate)) return false;
      if (endDate != null && txn.date.isAfter(endDate)) return false;
      if (category != null && txn.category != category) return false;
      if (transactionType != null &&
          txn.transactionType.toLowerCase() != transactionType.toLowerCase()) {
        return false;
      }
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchMerchant = txn.merchant.toLowerCase().contains(q);
        final matchNote = txn.note?.toLowerCase().contains(q) ?? false;
        final matchRaw = txn.rawMessage.toLowerCase().contains(q);
        if (!matchMerchant && !matchNote && !matchRaw) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    return await _localDataSource.getTransactionById(id);
  }

  @override
  Future<bool> saveTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    return await _localDataSource.saveTransaction(model);
  }

  @override
  Future<int> saveTransactions(List<TransactionEntity> transactions) async {
    final models = transactions.map(TransactionModel.fromEntity).toList();
    return await _localDataSource.saveTransactions(models);
  }

  @override
  Future<bool> updateTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    return await _localDataSource.updateTransaction(model);
  }

  @override
  Future<bool> updateTransactionCategory(
    String id,
    BudgetCategory category, {
    bool isUserCategorized = true,
  }) async {
    final existing = await _localDataSource.getTransactionById(id);
    if (existing == null) return false;

    final updated = existing.copyWith(
      category: category,
      isUserCategorized: isUserCategorized,
    );
    return await _localDataSource.updateTransaction(
      TransactionModel.fromEntity(updated),
    );
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    return await _localDataSource.deleteTransaction(id);
  }

  @override
  Future<bool> exists(String id) async {
    return await _localDataSource.hasTransaction(id);
  }

  @override
  Future<Map<String, BudgetCategory>> getUserCategoryRules() async {
    return await _localDataSource.getUserCategoryRules();
  }

  @override
  Future<void> saveUserCategoryRule(
    String merchantKeyword,
    BudgetCategory category,
  ) async {
    await _localDataSource.saveUserCategoryRule(merchantKeyword, category);
  }

  @override
  Future<void> deleteUserCategoryRule(String merchantKeyword) async {
    await _localDataSource.deleteUserCategoryRule(merchantKeyword);
  }

  @override
  Future<double> getTotalSpend({DateTime? startDate, DateTime? endDate}) async {
    final txns = await getTransactions(
      startDate: startDate,
      endDate: endDate,
      transactionType: 'expense',
    );
    return txns.fold<double>(0.0, (sum, txn) => sum + txn.amount);
  }

  @override
  Future<Map<BudgetCategory, double>> getSpendByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final txns = await getTransactions(
      startDate: startDate,
      endDate: endDate,
      transactionType: 'expense',
    );

    final Map<BudgetCategory, double> breakdown = {};
    for (final txn in txns) {
      breakdown[txn.category] = (breakdown[txn.category] ?? 0.0) + txn.amount;
    }
    return breakdown;
  }
}

import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';
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
    return await _localDataSource.getFilteredTransactions(
      startDate: startDate,
      endDate: endDate,
      category: category,
      query: query,
      transactionType: transactionType,
    );
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

    if (isUserCategorized && existing.merchant.trim().isNotEmpty) {
      await _localDataSource.saveUserCategoryRule(
        existing.merchant.trim(),
        category,
      );
    }
    return await _localDataSource.updateCategory(
      id,
      category,
      isUserCategorized: isUserCategorized,
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
    return await _localDataSource.getTotalSpend(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _localDataSource.getTotalIncome(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<Map<BudgetCategory, double>> getSpendByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _localDataSource.getSpendByCategory(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

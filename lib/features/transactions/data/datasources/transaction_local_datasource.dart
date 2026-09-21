import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/database/app_database.dart';
import 'package:xbudget/core/database/daos/transaction_dao.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import '../models/transaction_model.dart';

/// Local data source interface for storing and querying transactions via SQLite.
abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getAllTransactions();
  Future<List<TransactionModel>> getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    BudgetCategory? category,
    String? query,
    String? transactionType,
  });
  Future<TransactionModel?> getTransactionById(String id);
  Future<bool> saveTransaction(TransactionModel transaction);
  Future<int> saveTransactions(List<TransactionModel> transactions);
  Future<bool> updateTransaction(TransactionModel transaction);
  Future<bool> updateCategory(
    String id,
    BudgetCategory category, {
    bool isUserCategorized = true,
  });
  Future<bool> deleteTransaction(String id);
  Future<bool> hasTransaction(String id);
  Future<double> getTotalSpend({DateTime? startDate, DateTime? endDate});
  Future<double> getTotalIncome({DateTime? startDate, DateTime? endDate});
  Future<Map<BudgetCategory, double>> getSpendByCategory({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Map<String, BudgetCategory>> getUserCategoryRules();
  Future<void> saveUserCategoryRule(String keyword, BudgetCategory category);
  Future<void> deleteUserCategoryRule(String keyword);
  Future<void> clearAll();
}

/// Drift SQLite-backed implementation of [TransactionLocalDataSource].
class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final TransactionDao _dao;
  final SharedPreferences _prefs;

  static const String _keyUserRules = 'xbudget_user_category_rules_v1';

  TransactionLocalDataSourceImpl(
    this._prefs, {
    TransactionDao? dao,
    AppDatabase? db,
  }) : _dao = dao ??
            (db?.transactionDao ?? AppDatabase.inMemory().transactionDao);

  /// Convenience constructor when passing AppDatabase (defaults to inMemory for testing)
  factory TransactionLocalDataSourceImpl.fromDb({
    AppDatabase? db,
    required SharedPreferences prefs,
  }) {
    final database = db ?? AppDatabase.inMemory();
    return TransactionLocalDataSourceImpl(
      prefs,
      dao: database.transactionDao,
    );
  }

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final rows = await _dao.getAllTransactions();
    return rows.map(_fromDrift).toList();
  }

  @override
  Future<List<TransactionModel>> getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    BudgetCategory? category,
    String? query,
    String? transactionType,
  }) async {
    final rows = await _dao.getFilteredTransactions(
      startDate: startDate,
      endDate: endDate,
      category: category,
      query: query,
      transactionType: transactionType,
    );
    return rows.map(_fromDrift).toList();
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    final row = await _dao.getTransactionById(id);
    return row != null ? _fromDrift(row) : null;
  }

  @override
  Future<bool> hasTransaction(String id) async {
    return await _dao.hasTransaction(id);
  }

  @override
  Future<bool> saveTransaction(TransactionModel transaction) async {
    return await _dao.insertTransaction(_toCompanion(transaction));
  }

  @override
  Future<int> saveTransactions(List<TransactionModel> transactions) async {
    final companions = transactions.map(_toCompanion).toList();
    return await _dao.insertTransactions(companions);
  }

  @override
  Future<bool> updateTransaction(TransactionModel transaction) async {
    return await _dao.updateTransaction(_toCompanion(transaction));
  }

  @override
  Future<bool> updateCategory(
    String id,
    BudgetCategory category, {
    bool isUserCategorized = true,
  }) async {
    return await _dao.updateCategory(
      id,
      category,
      isUserCategorized: isUserCategorized,
    );
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    return await _dao.deleteTransaction(id);
  }

  @override
  Future<double> getTotalSpend({DateTime? startDate, DateTime? endDate}) async {
    return await _dao.getTotalSpend(startDate: startDate, endDate: endDate);
  }

  @override
  Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _dao.getTotalIncome(startDate: startDate, endDate: endDate);
  }

  @override
  Future<Map<BudgetCategory, double>> getSpendByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _dao.getSpendByCategory(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<Map<String, BudgetCategory>> getUserCategoryRules() async {
    final rawRulesStr = _prefs.getString(_keyUserRules);
    if (rawRulesStr == null) return {};
    try {
      final Map<String, dynamic> rawRules =
          jsonDecode(rawRulesStr) as Map<String, dynamic>;
      final Map<String, BudgetCategory> rules = {};
      rawRules.forEach((key, value) {
        rules[key] = BudgetCategory.fromString(value as String?);
      });
      return rules;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveUserCategoryRule(
    String keyword,
    BudgetCategory category,
  ) async {
    final currentRules = await getUserCategoryRules();
    final updated = Map<String, BudgetCategory>.from(currentRules);
    updated[keyword.toLowerCase().trim()] = category;
    final map = updated.map((k, v) => MapEntry(k, v.name));
    await _prefs.setString(_keyUserRules, jsonEncode(map));
  }

  @override
  Future<void> deleteUserCategoryRule(String keyword) async {
    final currentRules = await getUserCategoryRules();
    final updated = Map<String, BudgetCategory>.from(currentRules);
    if (updated.remove(keyword.toLowerCase().trim()) != null) {
      final map = updated.map((k, v) => MapEntry(k, v.name));
      await _prefs.setString(_keyUserRules, jsonEncode(map));
    }
  }

  @override
  Future<void> clearAll() async {
    await _dao.clearAll();
    await _prefs.remove(_keyUserRules);
  }

  TransactionsCompanion _toCompanion(TransactionModel m) {
    return TransactionsCompanion(
      id: Value(m.id),
      amount: Value(m.amount),
      merchant: Value(m.merchant),
      transactionType: Value(m.transactionType),
      category: Value(m.category),
      isP2P: Value(m.isP2P),
      date: Value(m.date),
      rawMessage: Value(m.rawMessage),
      isUserCategorized: Value(m.isUserCategorized),
      note: Value(m.note),
      createdAt: Value(m.createdAt),
    );
  }

  TransactionModel _fromDrift(Transaction row) {
    return TransactionModel(
      id: row.id,
      amount: row.amount,
      merchant: row.merchant,
      transactionType: row.transactionType,
      category: row.category,
      isP2P: row.isP2P,
      date: row.date,
      rawMessage: row.rawMessage,
      isUserCategorized: row.isUserCategorized,
      note: row.note,
      createdAt: row.createdAt,
    );
  }
}

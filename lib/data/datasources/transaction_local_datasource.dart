import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/budget_category.dart';
import '../models/transaction_model.dart';

/// Local data source interface for storing and retrieving transactions.
abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getAllTransactions();
  Future<TransactionModel?> getTransactionById(String id);
  Future<bool> saveTransaction(TransactionModel transaction);
  Future<int> saveTransactions(List<TransactionModel> transactions);
  Future<bool> updateTransaction(TransactionModel transaction);
  Future<bool> deleteTransaction(String id);
  Future<bool> hasTransaction(String id);
  Future<Map<String, BudgetCategory>> getUserCategoryRules();
  Future<void> saveUserCategoryRule(String keyword, BudgetCategory category);
  Future<void> deleteUserCategoryRule(String keyword);
  Future<void> clearAll();
}

/// SharedPreferences-backed implementation of [TransactionLocalDataSource].
class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final SharedPreferences _prefs;

  static const String _keyTransactions = 'xbudget_transactions_store_v1';
  static const String _keyUserRules = 'xbudget_user_category_rules_v1';

  // In-memory cache for fast O(1) deduplication and querying
  Map<String, TransactionModel>? _cache;
  Map<String, BudgetCategory>? _rulesCache;

  TransactionLocalDataSourceImpl(this._prefs);

  Future<void> _ensureLoaded() async {
    if (_cache != null && _rulesCache != null) return;

    // Load transactions
    _cache = {};
    final rawList = _prefs.getStringList(_keyTransactions);
    if (rawList != null) {
      for (final jsonStr in rawList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final model = TransactionModel.fromJson(map);
          _cache![model.id] = model;
        } catch (_) {
          // Ignore corrupted single entries
        }
      }
    }

    // Load user category rules
    _rulesCache = {};
    final rawRulesStr = _prefs.getString(_keyUserRules);
    if (rawRulesStr != null) {
      try {
        final Map<String, dynamic> rawRules =
            jsonDecode(rawRulesStr) as Map<String, dynamic>;
        rawRules.forEach((key, value) {
          _rulesCache![key] = BudgetCategory.fromString(value as String?);
        });
      } catch (_) {}
    }
  }

  Future<void> _persistTransactions() async {
    final list = _cache!.values.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList(_keyTransactions, list);
  }

  Future<void> _persistRules() async {
    final map = _rulesCache!.map((k, v) => MapEntry(k, v.name));
    await _prefs.setString(_keyUserRules, jsonEncode(map));
  }

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    await _ensureLoaded();
    final list = _cache!.values.toList();
    // Sort chronologically descending (newest first)
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    await _ensureLoaded();
    return _cache![id];
  }

  @override
  Future<bool> hasTransaction(String id) async {
    await _ensureLoaded();
    return _cache!.containsKey(id);
  }

  @override
  Future<bool> saveTransaction(TransactionModel transaction) async {
    await _ensureLoaded();
    // Deduplication check: Reject if already exists
    if (_cache!.containsKey(transaction.id)) {
      return false;
    }
    _cache![transaction.id] = transaction;
    await _persistTransactions();
    return true;
  }

  @override
  Future<int> saveTransactions(List<TransactionModel> transactions) async {
    await _ensureLoaded();
    int addedCount = 0;
    for (final txn in transactions) {
      // Deduplication check
      if (!_cache!.containsKey(txn.id)) {
        _cache![txn.id] = txn;
        addedCount++;
      }
    }
    if (addedCount > 0) {
      await _persistTransactions();
    }
    return addedCount;
  }

  @override
  Future<bool> updateTransaction(TransactionModel transaction) async {
    await _ensureLoaded();
    if (!_cache!.containsKey(transaction.id)) {
      return false;
    }
    _cache![transaction.id] = transaction;
    await _persistTransactions();
    return true;
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    await _ensureLoaded();
    if (_cache!.remove(id) != null) {
      await _persistTransactions();
      return true;
    }
    return false;
  }

  @override
  Future<Map<String, BudgetCategory>> getUserCategoryRules() async {
    await _ensureLoaded();
    return Map.unmodifiable(_rulesCache!);
  }

  @override
  Future<void> saveUserCategoryRule(
    String keyword,
    BudgetCategory category,
  ) async {
    await _ensureLoaded();
    _rulesCache![keyword.toLowerCase().trim()] = category;
    await _persistRules();
  }

  @override
  Future<void> deleteUserCategoryRule(String keyword) async {
    await _ensureLoaded();
    if (_rulesCache!.remove(keyword.toLowerCase().trim()) != null) {
      await _persistRules();
    }
  }

  @override
  Future<void> clearAll() async {
    _cache = {};
    _rulesCache = {};
    await _prefs.remove(_keyTransactions);
    await _prefs.remove(_keyUserRules);
  }
}

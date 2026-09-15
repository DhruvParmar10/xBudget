import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/balance_log_model.dart';

abstract class BalanceLogLocalDataSource {
  Future<List<BalanceLogModel>> getAllLogs();
  Future<bool> saveLog(BalanceLogModel log);
  Future<bool> updateLog(BalanceLogModel log);
  Future<bool> deleteLog(String id);
  Future<void> clearAll();
}

class BalanceLogLocalDataSourceImpl implements BalanceLogLocalDataSource {
  final SharedPreferences _prefs;

  static const String _keyBalanceLogs = 'xbudget_balance_logs_v1';

  Map<String, BalanceLogModel>? _cache;

  BalanceLogLocalDataSourceImpl(this._prefs);

  Future<void> _ensureLoaded() async {
    if (_cache != null) return;

    _cache = {};
    final rawList = _prefs.getStringList(_keyBalanceLogs);
    if (rawList != null) {
      for (final jsonStr in rawList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final model = BalanceLogModel.fromJson(map);
          _cache![model.id] = model;
        } catch (_) {
          // Skip malformed entries
        }
      }
    }
  }

  Future<void> _persist() async {
    final list = _cache!.values.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList(_keyBalanceLogs, list);
  }

  @override
  Future<List<BalanceLogModel>> getAllLogs() async {
    await _ensureLoaded();
    final list = _cache!.values.toList();
    // Sort descending by timestamp (newest first)
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<bool> saveLog(BalanceLogModel log) async {
    await _ensureLoaded();
    _cache![log.id] = log;
    await _persist();
    return true;
  }

  @override
  Future<bool> updateLog(BalanceLogModel log) async {
    await _ensureLoaded();
    if (!_cache!.containsKey(log.id)) {
      return false;
    }
    _cache![log.id] = log;
    await _persist();
    return true;
  }

  @override
  Future<bool> deleteLog(String id) async {
    await _ensureLoaded();
    if (_cache!.remove(id) != null) {
      await _persist();
      return true;
    }
    return false;
  }

  @override
  Future<void> clearAll() async {
    _cache = {};
    await _prefs.remove(_keyBalanceLogs);
  }
}

import 'package:drift/drift.dart';
import 'package:xbudget/core/database/app_database.dart';
import 'package:xbudget/core/database/daos/balance_log_dao.dart';
import '../models/balance_log_model.dart';

abstract class BalanceLogLocalDataSource {
  Future<List<BalanceLogModel>> getAllLogs();
  Future<bool> saveLog(BalanceLogModel log);
  Future<bool> updateLog(BalanceLogModel log);
  Future<bool> deleteLog(String id);
  Future<void> clearAll();
}

class BalanceLogLocalDataSourceImpl implements BalanceLogLocalDataSource {
  final BalanceLogDao _dao;

  BalanceLogLocalDataSourceImpl([
    dynamic prefsOrDb,
    BalanceLogDao? dao,
  ]) : _dao = dao ??
            (prefsOrDb is AppDatabase
                ? prefsOrDb.balanceLogDao
                : (prefsOrDb is BalanceLogDao
                    ? prefsOrDb
                    : AppDatabase.inMemory().balanceLogDao));

  /// Convenience constructor when passing AppDatabase (defaults to inMemory for testing)
  factory BalanceLogLocalDataSourceImpl.fromDb({AppDatabase? db}) {
    final database = db ?? AppDatabase.inMemory();
    return BalanceLogLocalDataSourceImpl(database.balanceLogDao);
  }

  @override
  Future<List<BalanceLogModel>> getAllLogs() async {
    final rows = await _dao.getAllLogs();
    return rows.map(_fromDrift).toList();
  }

  @override
  Future<bool> saveLog(BalanceLogModel log) async {
    return await _dao.saveLog(_toCompanion(log));
  }

  @override
  Future<bool> updateLog(BalanceLogModel log) async {
    return await _dao.updateLog(_toCompanion(log));
  }

  @override
  Future<bool> deleteLog(String id) async {
    return await _dao.deleteLog(id);
  }

  @override
  Future<void> clearAll() async {
    await _dao.clearAll();
  }

  BalanceLogsCompanion _toCompanion(BalanceLogModel m) {
    return BalanceLogsCompanion(
      id: Value(m.id),
      timestamp: Value(m.timestamp),
      previousBalance: Value(m.previousBalance),
      adjustmentAmount: Value(m.adjustmentAmount),
      resultingBalance: Value(m.resultingBalance),
      source: Value(m.source),
      note: Value(m.note),
      createdAt: Value(m.createdAt),
    );
  }

  BalanceLogModel _fromDrift(BalanceLog row) {
    return BalanceLogModel(
      id: row.id,
      timestamp: row.timestamp,
      previousBalance: row.previousBalance,
      adjustmentAmount: row.adjustmentAmount,
      resultingBalance: row.resultingBalance,
      source: row.source,
      note: row.note,
      createdAt: row.createdAt,
    );
  }
}

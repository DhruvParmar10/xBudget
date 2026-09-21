import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'balance_log_dao.g.dart';

@DriftAccessor(tables: [BalanceLogs])
class BalanceLogDao extends DatabaseAccessor<AppDatabase>
    with _$BalanceLogDaoMixin {
  BalanceLogDao(super.db);

  /// Retrieves all balance logs sorted descending by timestamp.
  Future<List<BalanceLog>> getAllLogs() {
    return (select(balanceLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  /// Inserts a new balance log or updates if ID already exists.
  Future<bool> saveLog(BalanceLogsCompanion entry) async {
    await into(balanceLogs).insertOnConflictUpdate(entry);
    return true;
  }

  /// Updates an existing balance log.
  Future<bool> updateLog(BalanceLogsCompanion entry) async {
    final count = await (update(balanceLogs)
          ..where((t) => t.id.equals(entry.id.value)))
        .write(entry);
    return count > 0;
  }

  /// Deletes a balance log by ID.
  Future<bool> deleteLog(String id) async {
    final count =
        await (delete(balanceLogs)..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  /// Clears all balance logs.
  Future<void> clearAll() async {
    await delete(balanceLogs).go();
  }
}

import '../entities/balance_log_entity.dart';

/// Repository interface for persisting and querying balance logs.
abstract class BalanceLogRepository {
  /// Returns all balance logs sorted chronologically descending (newest first).
  Future<List<BalanceLogEntity>> getBalanceLogs();

  /// Adds a new balance log.
  Future<void> addBalanceLog(BalanceLogEntity log);

  /// Updates an existing balance log.
  Future<void> updateBalanceLog(BalanceLogEntity log);

  /// Deletes a balance log by ID.
  Future<bool> deleteBalanceLog(String id);

  /// Clears all balance logs.
  Future<void> clearBalanceLogs();
}

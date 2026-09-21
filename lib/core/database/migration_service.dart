import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/features/balance/data/models/balance_log_model.dart';
import 'package:xbudget/features/transactions/data/models/transaction_model.dart';
import 'app_database.dart';

/// Service responsible for migrating legacy SharedPreferences JSON stores to Drift SQLite.
class MigrationService {
  static const String keyIsMigrated = 'is_migrated_to_drift_v1';
  static const String keyTransactions = 'xbudget_transactions_store_v1';
  static const String keyBalanceLogs = 'xbudget_balance_logs_v1';

  /// Performs a one-time migration of transactions and balance logs from SharedPreferences to Drift.
  /// Preserves the legacy data as a safety backup until explicitly reclaimed by the user.
  static Future<void> migrateIfNeeded({
    required SharedPreferences prefs,
    required AppDatabase db,
  }) async {
    final isMigrated = prefs.getBool(keyIsMigrated) ?? false;
    if (isMigrated) {
      return;
    }

    final rawTxns = prefs.getStringList(keyTransactions);
    final rawLogs = prefs.getStringList(keyBalanceLogs);

    final List<TransactionsCompanion> txnCompanions = [];
    if (rawTxns != null) {
      for (final jsonStr in rawTxns) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final model = TransactionModel.fromJson(map);
          txnCompanions.add(
            TransactionsCompanion(
              id: Value(model.id),
              amount: Value(model.amount),
              merchant: Value(model.merchant),
              transactionType: Value(model.transactionType),
              category: Value(model.category),
              isP2P: Value(model.isP2P),
              date: Value(model.date),
              rawMessage: Value(model.rawMessage),
              isUserCategorized: Value(model.isUserCategorized),
              note: Value(model.note),
              createdAt: Value(model.createdAt),
            ),
          );
        } catch (_) {
          // Ignore corrupt individual entries
        }
      }
    }

    final List<BalanceLogsCompanion> logCompanions = [];
    if (rawLogs != null) {
      for (final jsonStr in rawLogs) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final model = BalanceLogModel.fromJson(map);
          logCompanions.add(
            BalanceLogsCompanion(
              id: Value(model.id),
              timestamp: Value(model.timestamp),
              previousBalance: Value(model.previousBalance),
              adjustmentAmount: Value(model.adjustmentAmount),
              resultingBalance: Value(model.resultingBalance),
              source: Value(model.source),
              note: Value(model.note),
              createdAt: Value(model.createdAt),
            ),
          );
        } catch (_) {
          // Ignore corrupt individual entries
        }
      }
    }

    // Execute atomic migration inside a single database transaction
    await db.transaction(() async {
      if (txnCompanions.isNotEmpty) {
        await db.transactionDao.insertTransactions(txnCompanions);
      }
      for (final log in logCompanions) {
        await db.balanceLogDao.saveLog(log);
      }
    });

    // Mark as migrated, preserving old keys for safety verification
    await prefs.setBool(keyIsMigrated, true);
  }

  /// Checks if legacy backup data still exists in SharedPreferences.
  static bool hasLegacyBackup(SharedPreferences prefs) {
    final txns = prefs.getStringList(keyTransactions);
    final logs = prefs.getStringList(keyBalanceLogs);
    return (txns != null && txns.isNotEmpty) || (logs != null && logs.isNotEmpty);
  }

  /// Returns the count of legacy backup items: (transactionsCount, balanceLogsCount).
  static (int, int) getLegacyBackupCounts(SharedPreferences prefs) {
    final txns = prefs.getStringList(keyTransactions);
    final logs = prefs.getStringList(keyBalanceLogs);
    return (txns?.length ?? 0, logs?.length ?? 0);
  }

  /// Permanently deletes legacy SharedPreferences backup data to reclaim storage.
  static Future<bool> reclaimLegacyStorage(SharedPreferences prefs) async {
    final r1 = await prefs.remove(keyTransactions);
    final r2 = await prefs.remove(keyBalanceLogs);
    return r1 || r2;
  }
}

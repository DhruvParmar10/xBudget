import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/database/app_database.dart';
import 'package:xbudget/core/database/migration_service.dart';
import 'package:xbudget/features/balance/data/models/balance_log_model.dart';
import 'package:xbudget/features/transactions/data/models/transaction_model.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';

void main() {
  group('MigrationService Tests', () {
    late AppDatabase db;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase.inMemory();
    });

    tearDown(() async {
      await db.close();
    });

    test('migrates transactions and balance logs from SharedPreferences into Drift', () async {
      final txn = TransactionModel(
        id: 'txn_mig_1',
        amount: 350.0,
        merchant: 'Swiggy',
        transactionType: 'expense',
        category: BudgetCategory.food,
        isP2P: false,
        date: DateTime(2026, 8, 15),
        rawMessage: 'Debited 350 at Swiggy',
        isUserCategorized: false,
        createdAt: DateTime(2026, 8, 15),
      );

      final log = BalanceLogModel(
        id: 'log_mig_1',
        timestamp: DateTime(2026, 8, 15),
        previousBalance: 10000.0,
        adjustmentAmount: -350.0,
        resultingBalance: 9650.0,
        source: 'sms',
        createdAt: DateTime(2026, 8, 15),
      );

      await prefs.setStringList(
        MigrationService.keyTransactions,
        [jsonEncode(txn.toJson())],
      );
      await prefs.setStringList(
        MigrationService.keyBalanceLogs,
        [jsonEncode(log.toJson())],
      );

      expect(MigrationService.hasLegacyBackup(prefs), isTrue);
      final countsBefore = MigrationService.getLegacyBackupCounts(prefs);
      expect(countsBefore.$1, equals(1));
      expect(countsBefore.$2, equals(1));

      // Run migration
      await MigrationService.migrateIfNeeded(prefs: prefs, db: db);

      // Verify data is now in Drift
      final dbTxns = await db.transactionDao.getAllTransactions();
      expect(dbTxns.length, equals(1));
      expect(dbTxns.first.id, equals('txn_mig_1'));
      expect(dbTxns.first.amount, equals(350.0));

      final dbLogs = await db.balanceLogDao.getAllLogs();
      expect(dbLogs.length, equals(1));
      expect(dbLogs.first.id, equals('log_mig_1'));
      expect(dbLogs.first.resultingBalance, equals(9650.0));

      // Verify migration flag is set
      expect(prefs.getBool(MigrationService.keyIsMigrated), isTrue);

      // Verify legacy backup is PRESERVED for safety
      expect(MigrationService.hasLegacyBackup(prefs), isTrue);

      // Reclaim storage
      await MigrationService.reclaimLegacyStorage(prefs);
      expect(MigrationService.hasLegacyBackup(prefs), isFalse);
    });

    test('skips migration if already marked as migrated', () async {
      await prefs.setBool(MigrationService.keyIsMigrated, true);

      final txn = TransactionModel(
        id: 'txn_mig_2',
        amount: 100.0,
        merchant: 'Uber',
        transactionType: 'expense',
        category: BudgetCategory.transport,
        isP2P: false,
        date: DateTime(2026, 8, 16),
        rawMessage: 'Debited 100 at Uber',
        createdAt: DateTime(2026, 8, 16),
      );

      await prefs.setStringList(
        MigrationService.keyTransactions,
        [jsonEncode(txn.toJson())],
      );

      await MigrationService.migrateIfNeeded(prefs: prefs, db: db);

      // Should not be in database because already marked migrated
      final dbTxns = await db.transactionDao.getAllTransactions();
      expect(dbTxns, isEmpty);
    });
  });
}

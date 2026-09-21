import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:xbudget/core/database/app_database.dart';
import 'package:xbudget/core/database/daos/balance_log_dao.dart';

void main() {
  group('BalanceLogDao Tests', () {
    late AppDatabase db;
    late BalanceLogDao dao;

    setUp(() {
      db = AppDatabase.inMemory();
      dao = db.balanceLogDao;
    });

    tearDown(() async {
      await db.close();
    });

    BalanceLogsCompanion createLog({
      required String id,
      required DateTime timestamp,
      required double previousBalance,
      required double adjustmentAmount,
      required double resultingBalance,
      String source = 'manual',
      String? note,
    }) {
      return BalanceLogsCompanion(
        id: Value(id),
        timestamp: Value(timestamp),
        previousBalance: Value(previousBalance),
        adjustmentAmount: Value(adjustmentAmount),
        resultingBalance: Value(resultingBalance),
        source: Value(source),
        note: Value(note),
        createdAt: Value(DateTime.now()),
      );
    }

    test('saves and retrieves logs ordered descending by timestamp', () async {
      final l1 = createLog(
        id: '1',
        timestamp: DateTime(2026, 8, 10),
        previousBalance: 10000,
        adjustmentAmount: -2000,
        resultingBalance: 8000,
      );
      final l2 = createLog(
        id: '2',
        timestamp: DateTime(2026, 8, 15),
        previousBalance: 8000,
        adjustmentAmount: 5000,
        resultingBalance: 13000,
      );

      await dao.saveLog(l1);
      await dao.saveLog(l2);

      final all = await dao.getAllLogs();
      expect(all.length, equals(2));
      expect(all.first.id, equals('2')); // Newest first
      expect(all.last.id, equals('1'));
    });

    test('updates existing log on conflict or via updateLog', () async {
      final l = createLog(
        id: 'log_up',
        timestamp: DateTime(2026, 8, 10),
        previousBalance: 5000,
        adjustmentAmount: -1000,
        resultingBalance: 4000,
        note: 'Old note',
      );
      await dao.saveLog(l);

      final updated = createLog(
        id: 'log_up',
        timestamp: DateTime(2026, 8, 10),
        previousBalance: 5000,
        adjustmentAmount: -1500,
        resultingBalance: 3500,
        note: 'New note',
      );
      final success = await dao.updateLog(updated);
      expect(success, isTrue);

      final all = await dao.getAllLogs();
      expect(all.length, equals(1));
      expect(all.first.adjustmentAmount, equals(-1500));
      expect(all.first.note, equals('New note'));
    });

    test('deletes a log and clears all logs', () async {
      final l1 = createLog(
        id: '1',
        timestamp: DateTime(2026, 8, 1),
        previousBalance: 0,
        adjustmentAmount: 1000,
        resultingBalance: 1000,
      );
      final l2 = createLog(
        id: '2',
        timestamp: DateTime(2026, 8, 2),
        previousBalance: 1000,
        adjustmentAmount: 2000,
        resultingBalance: 3000,
      );

      await dao.saveLog(l1);
      await dao.saveLog(l2);

      final deleted = await dao.deleteLog('1');
      expect(deleted, isTrue);
      expect((await dao.getAllLogs()).length, equals(1));

      await dao.clearAll();
      expect(await dao.getAllLogs(), isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/features/balance/data/datasources/balance_log_local_datasource.dart';
import 'package:xbudget/features/balance/data/models/balance_log_model.dart';
import 'package:xbudget/features/balance/data/repositories/balance_log_repository_impl.dart';
import 'package:xbudget/features/balance/domain/entities/balance_log_entity.dart';
import 'package:xbudget/features/balance/domain/repositories/balance_log_repository.dart';

void main() {
  late BalanceLogLocalDataSource dataSource;
  late BalanceLogRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dataSource = BalanceLogLocalDataSourceImpl(prefs);
    repository = BalanceLogRepositoryImpl(localDataSource: dataSource);
  });

  group('BalanceLogRepository & LocalDataSource', () {
    test('initially returns empty list of logs', () async {
      final logs = await repository.getBalanceLogs();
      expect(logs, isEmpty);
    });

    test('saves, retrieves, updates, and deletes balance logs', () async {
      final now = DateTime(2026, 8, 24, 10, 0);
      final id = BalanceLogModel.generateId(
        timestamp: now,
        adjustmentAmount: -5000.0,
        source: 'manual',
      );

      final log = BalanceLogEntity(
        id: id,
        timestamp: now,
        previousBalance: 25000.0,
        adjustmentAmount: -5000.0,
        resultingBalance: 20000.0,
        source: 'manual',
        note: 'Cash payment',
        createdAt: now,
      );

      await repository.addBalanceLog(log);
      var logs = await repository.getBalanceLogs();
      expect(logs.length, equals(1));
      expect(logs.first.id, equals(id));
      expect(logs.first.adjustmentAmount, equals(-5000.0));
      expect(logs.first.note, equals('Cash payment'));

      // Update log
      final updated = log.copyWith(
        adjustmentAmount: -3000.0,
        resultingBalance: 22000.0,
        note: 'Corrected payment',
      );
      await repository.updateBalanceLog(updated);
      logs = await repository.getBalanceLogs();
      expect(logs.length, equals(1));
      expect(logs.first.adjustmentAmount, equals(-3000.0));
      expect(logs.first.note, equals('Corrected payment'));

      // Delete log
      final deleted = await repository.deleteBalanceLog(id);
      expect(deleted, isTrue);
      logs = await repository.getBalanceLogs();
      expect(logs, isEmpty);
    });

    test('clears all logs', () async {
      final log1 = BalanceLogEntity(
        id: '1',
        timestamp: DateTime.now(),
        previousBalance: 0,
        adjustmentAmount: 1000,
        resultingBalance: 1000,
        source: 'manual',
        createdAt: DateTime.now(),
      );
      final log2 = BalanceLogEntity(
        id: '2',
        timestamp: DateTime.now(),
        previousBalance: 1000,
        adjustmentAmount: 500,
        resultingBalance: 1500,
        source: 'manual',
        createdAt: DateTime.now(),
      );

      await repository.addBalanceLog(log1);
      await repository.addBalanceLog(log2);
      expect((await repository.getBalanceLogs()).length, equals(2));

      await repository.clearBalanceLogs();
      expect(await repository.getBalanceLogs(), isEmpty);
    });
  });
}

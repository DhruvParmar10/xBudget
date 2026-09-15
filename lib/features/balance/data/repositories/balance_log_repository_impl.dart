import '../../domain/entities/balance_log_entity.dart';
import '../../domain/repositories/balance_log_repository.dart';
import '../datasources/balance_log_local_datasource.dart';
import '../models/balance_log_model.dart';

class BalanceLogRepositoryImpl implements BalanceLogRepository {
  final BalanceLogLocalDataSource localDataSource;

  BalanceLogRepositoryImpl({required this.localDataSource});

  @override
  Future<List<BalanceLogEntity>> getBalanceLogs() async {
    return await localDataSource.getAllLogs();
  }

  @override
  Future<void> addBalanceLog(BalanceLogEntity log) async {
    final model = BalanceLogModel.fromEntity(log);
    await localDataSource.saveLog(model);
  }

  @override
  Future<void> updateBalanceLog(BalanceLogEntity log) async {
    final model = BalanceLogModel.fromEntity(log);
    await localDataSource.updateLog(model);
  }

  @override
  Future<bool> deleteBalanceLog(String id) async {
    return await localDataSource.deleteLog(id);
  }

  @override
  Future<void> clearBalanceLogs() async {
    await localDataSource.clearAll();
  }
}

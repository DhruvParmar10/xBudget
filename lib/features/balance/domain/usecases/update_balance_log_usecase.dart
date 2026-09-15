import 'package:xbudget/core/usecases/usecase.dart';
import '../entities/balance_log_entity.dart';
import '../repositories/balance_log_repository.dart';

class UpdateBalanceLogUseCase implements UseCase<void, BalanceLogEntity> {
  final BalanceLogRepository repository;

  UpdateBalanceLogUseCase(this.repository);

  @override
  Future<void> call(BalanceLogEntity params) async {
    await repository.updateBalanceLog(params);
  }
}

import 'package:xbudget/core/usecases/usecase.dart';
import '../entities/balance_log_entity.dart';
import '../repositories/balance_log_repository.dart';

class AddBalanceLogUseCase implements UseCase<void, BalanceLogEntity> {
  final BalanceLogRepository repository;

  AddBalanceLogUseCase(this.repository);

  @override
  Future<void> call(BalanceLogEntity params) async {
    await repository.addBalanceLog(params);
  }
}

import 'package:xbudget/core/usecases/usecase.dart';
import '../entities/balance_log_entity.dart';
import '../repositories/balance_log_repository.dart';

class GetBalanceLogsUseCase implements UseCase<List<BalanceLogEntity>, NoParams> {
  final BalanceLogRepository repository;

  GetBalanceLogsUseCase(this.repository);

  @override
  Future<List<BalanceLogEntity>> call(NoParams params) async {
    return await repository.getBalanceLogs();
  }
}

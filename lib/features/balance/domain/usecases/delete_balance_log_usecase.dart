import 'package:xbudget/core/usecases/usecase.dart';
import '../repositories/balance_log_repository.dart';

class DeleteBalanceLogUseCase implements UseCase<bool, String> {
  final BalanceLogRepository repository;

  DeleteBalanceLogUseCase(this.repository);

  @override
  Future<bool> call(String id) async {
    return await repository.deleteBalanceLog(id);
  }
}

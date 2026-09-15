import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import '../repositories/balance_log_repository.dart';

class ClearBalanceUseCase implements UseCase<bool, NoParams> {
  final AppPreferences preferences;
  final BalanceLogRepository balanceLogRepository;

  ClearBalanceUseCase({
    required this.preferences,
    required this.balanceLogRepository,
  });

  @override
  Future<bool> call(NoParams params) async {
    await balanceLogRepository.clearBalanceLogs();
    return await preferences.clearCurrentBalance();
  }
}

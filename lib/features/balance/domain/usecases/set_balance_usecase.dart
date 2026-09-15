import 'package:equatable/equatable.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/balance/data/models/balance_log_model.dart';
import '../entities/balance_log_entity.dart';
import '../repositories/balance_log_repository.dart';

class SetBalanceParams extends Equatable {
  final double balance;
  final String source;
  final DateTime? updatedAt;
  final String? note;

  const SetBalanceParams({
    required this.balance,
    this.source = 'manual',
    this.updatedAt,
    this.note,
  });

  @override
  List<Object?> get props => [balance, source, updatedAt, note];
}

class SetBalanceUseCase implements UseCase<bool, SetBalanceParams> {
  final AppPreferences preferences;
  final BalanceLogRepository balanceLogRepository;

  SetBalanceUseCase({
    required this.preferences,
    required this.balanceLogRepository,
  });

  @override
  Future<bool> call(SetBalanceParams params) async {
    final existingLogs = await balanceLogRepository.getBalanceLogs();
    final validLogs = existingLogs
        .where((l) => !(l.source == 'opening' && l.adjustmentAmount < 0))
        .toList();

    // Sort chronologically ascending to get the true latest log
    validLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final bool isFirstTime = validLogs.isEmpty;
    final double prevBalance = isFirstTime ? 0.0 : validLogs.last.resultingBalance;
    final double adjustment = isFirstTime ? params.balance : (params.balance - prevBalance);
    final String source = isFirstTime ? 'opening' : params.source;
    final now = params.updatedAt ?? DateTime.now();

    final id = BalanceLogModel.generateId(
      timestamp: now,
      adjustmentAmount: adjustment,
      source: source,
    );

    final log = BalanceLogEntity(
      id: id,
      timestamp: now,
      previousBalance: prevBalance,
      adjustmentAmount: adjustment,
      resultingBalance: params.balance,
      source: source,
      note: params.note ?? (isFirstTime ? 'Opening Balance' : 'Manual Adjustment'),
      createdAt: now,
    );

    await balanceLogRepository.addBalanceLog(log);

    return await preferences.setCurrentBalance(
      params.balance,
      source: source,
      updatedAt: now,
    );
  }
}

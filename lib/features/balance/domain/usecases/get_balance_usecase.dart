import 'package:equatable/equatable.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/balance/domain/entities/balance_log_entity.dart';
import 'package:xbudget/features/balance/domain/repositories/balance_log_repository.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

class BalanceData extends Equatable {
  final double? currentBalance;
  final DateTime? balanceUpdatedAt;
  final String balanceSource;
  final List<BalanceLogEntity> balanceLogs;

  const BalanceData({
    this.currentBalance,
    this.balanceUpdatedAt,
    required this.balanceSource,
    this.balanceLogs = const [],
  });

  @override
  List<Object?> get props => [
        currentBalance,
        balanceUpdatedAt,
        balanceSource,
        balanceLogs,
      ];
}

class GetBalanceUseCase implements UseCase<BalanceData, NoParams> {
  final AppPreferences preferences;
  final TransactionRepository? repository;
  final BalanceLogRepository? balanceLogRepository;

  GetBalanceUseCase({
    required this.preferences,
    this.repository,
    this.balanceLogRepository,
  });

  @override
  Future<BalanceData> call(NoParams params) async {
    final repo = balanceLogRepository;
    if (repo == null) {
      final baseBalance = preferences.currentBalance;
      if (baseBalance == null) {
        return BalanceData(
          currentBalance: null,
          balanceUpdatedAt: null,
          balanceSource: preferences.balanceSource,
        );
      }
      final updatedAt = preferences.balanceUpdatedAt;
      double calculatedBalance = baseBalance;
      if (updatedAt != null && repository != null) {
        final transactions = await repository!.getTransactions(
          startDate: updatedAt,
        );
        for (final txn in transactions) {
          if (txn.date.isAfter(updatedAt)) {
            if (txn.isExpense) {
              calculatedBalance -= txn.amount;
            } else if (txn.isIncome) {
              calculatedBalance += txn.amount;
            }
          }
        }
      }
      return BalanceData(
        currentBalance: calculatedBalance,
        balanceUpdatedAt: updatedAt,
        balanceSource: preferences.balanceSource,
      );
    }

    final rawLogs = await repo.getBalanceLogs();

    // Auto-purge any corrupted negative opening logs
    for (final l in rawLogs) {
      if (l.source == 'opening' && l.adjustmentAmount < 0) {
        await repo.deleteBalanceLog(l.id);
      }
    }

    final List<BalanceLogEntity> logs = List<BalanceLogEntity>.from(
      (await repo.getBalanceLogs())
          .where((l) => !(l.source == 'opening' && l.adjustmentAmount < 0)),
    );

    // Migration / Backwards compatibility for existing users with positive stored balance
    if (logs.isEmpty) {
      if (preferences.currentBalance != null && preferences.currentBalance! > 0) {
        final initialBal = preferences.currentBalance!;
        final initialDate = preferences.balanceUpdatedAt ?? DateTime.now();
        final legacyLog = BalanceLogEntity(
          id: 'legacy_initial_${initialDate.millisecondsSinceEpoch}',
          timestamp: initialDate,
          previousBalance: 0.0,
          adjustmentAmount: initialBal,
          resultingBalance: initialBal,
          source: preferences.balanceSource,
          note: 'Opening Balance',
          createdAt: initialDate,
        );
        await repo.addBalanceLog(legacyLog);
        logs.add(legacyLog);
      } else {
        return BalanceData(
          currentBalance: null,
          balanceUpdatedAt: null,
          balanceSource: preferences.balanceSource,
          balanceLogs: const [],
        );
      }
    }

    // Sort chronologically ascending
    final sortedAsc = List<BalanceLogEntity>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Base balance is established by the latest balance log
    final latestLog = sortedAsc.last;
    double calculatedBalance = latestLog.resultingBalance;

    // Apply only new transactions that occurred AFTER the latest balance log
    if (repository != null) {
      final transactions = await repository!.getTransactions(
        startDate: latestLog.timestamp,
      );

      for (final txn in transactions) {
        if (txn.date.isAfter(latestLog.timestamp)) {
          if (txn.isExpense) {
            calculatedBalance -= txn.amount;
          } else if (txn.isIncome) {
            calculatedBalance += txn.amount;
          }
        }
      }
    }

    // Sync calculated balance with central app preferences
    await preferences.setCurrentBalance(
      calculatedBalance,
      source: latestLog.source,
      updatedAt: latestLog.timestamp,
    );

    // Return logs sorted newest first for presentation
    final sortedDesc = List<BalanceLogEntity>.from(logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return BalanceData(
      currentBalance: calculatedBalance,
      balanceUpdatedAt: latestLog.timestamp,
      balanceSource: latestLog.source,
      balanceLogs: sortedDesc,
    );
  }
}

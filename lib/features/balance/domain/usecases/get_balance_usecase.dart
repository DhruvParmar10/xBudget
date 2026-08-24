import 'package:equatable/equatable.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

class BalanceData extends Equatable {
  final double? currentBalance;
  final DateTime? balanceUpdatedAt;
  final String balanceSource;

  const BalanceData({
    this.currentBalance,
    this.balanceUpdatedAt,
    required this.balanceSource,
  });

  @override
  List<Object?> get props => [currentBalance, balanceUpdatedAt, balanceSource];
}

class GetBalanceUseCase implements UseCase<BalanceData, NoParams> {
  final AppPreferences preferences;
  final TransactionRepository? repository;

  GetBalanceUseCase({
    required this.preferences,
    this.repository,
  });

  @override
  Future<BalanceData> call(NoParams params) async {
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
}

import 'package:equatable/equatable.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';

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

  GetBalanceUseCase(this.preferences);

  @override
  Future<BalanceData> call(NoParams params) async {
    return BalanceData(
      currentBalance: preferences.currentBalance,
      balanceUpdatedAt: preferences.balanceUpdatedAt,
      balanceSource: preferences.balanceSource,
    );
  }
}

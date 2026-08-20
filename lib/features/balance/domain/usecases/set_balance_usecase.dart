import 'package:equatable/equatable.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';

class SetBalanceParams extends Equatable {
  final double balance;
  final String source;
  final DateTime? updatedAt;

  const SetBalanceParams({
    required this.balance,
    this.source = 'manual',
    this.updatedAt,
  });

  @override
  List<Object?> get props => [balance, source, updatedAt];
}

class SetBalanceUseCase implements UseCase<bool, SetBalanceParams> {
  final AppPreferences preferences;

  SetBalanceUseCase(this.preferences);

  @override
  Future<bool> call(SetBalanceParams params) async {
    return await preferences.setCurrentBalance(
      params.balance,
      source: params.source,
      updatedAt: params.updatedAt,
    );
  }
}

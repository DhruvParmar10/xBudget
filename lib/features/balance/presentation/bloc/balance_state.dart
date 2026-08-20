import 'package:equatable/equatable.dart';

abstract class BalanceState extends Equatable {
  const BalanceState();

  @override
  List<Object?> get props => [];
}

class BalanceInitial extends BalanceState {
  const BalanceInitial();
}

class BalanceLoaded extends BalanceState {
  final double? currentBalance;
  final DateTime? balanceUpdatedAt;
  final String balanceSource;

  const BalanceLoaded({
    this.currentBalance,
    this.balanceUpdatedAt,
    required this.balanceSource,
  });

  BalanceLoaded copyWith({
    double? currentBalance,
    DateTime? balanceUpdatedAt,
    String? balanceSource,
    bool clearBalance = false,
  }) {
    return BalanceLoaded(
      currentBalance: clearBalance ? null : (currentBalance ?? this.currentBalance),
      balanceUpdatedAt: clearBalance ? null : (balanceUpdatedAt ?? this.balanceUpdatedAt),
      balanceSource: balanceSource ?? this.balanceSource,
    );
  }

  @override
  List<Object?> get props => [currentBalance, balanceUpdatedAt, balanceSource];
}

class BalanceError extends BalanceState {
  final String message;

  const BalanceError(this.message);

  @override
  List<Object?> get props => [message];
}

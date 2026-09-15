import 'package:equatable/equatable.dart';
import '../../domain/entities/balance_log_entity.dart';

abstract class BalanceState extends Equatable {
  const BalanceState();

  @override
  List<Object?> get props => [];
}

class BalanceInitial extends BalanceState {
  const BalanceInitial();
}

class BalanceLoading extends BalanceState {
  const BalanceLoading();
}

class BalanceLoaded extends BalanceState {
  final double? currentBalance;
  final DateTime? balanceUpdatedAt;
  final String balanceSource;
  final List<BalanceLogEntity> balanceLogs;

  const BalanceLoaded({
    this.currentBalance,
    this.balanceUpdatedAt,
    required this.balanceSource,
    this.balanceLogs = const [],
  });

  BalanceLoaded copyWith({
    double? currentBalance,
    DateTime? balanceUpdatedAt,
    String? balanceSource,
    List<BalanceLogEntity>? balanceLogs,
    bool clearBalance = false,
  }) {
    return BalanceLoaded(
      currentBalance: clearBalance ? null : (currentBalance ?? this.currentBalance),
      balanceUpdatedAt: clearBalance ? null : (balanceUpdatedAt ?? this.balanceUpdatedAt),
      balanceSource: balanceSource ?? this.balanceSource,
      balanceLogs: balanceLogs ?? this.balanceLogs,
    );
  }

  @override
  List<Object?> get props => [
        currentBalance,
        balanceUpdatedAt,
        balanceSource,
        balanceLogs,
      ];
}

class BalanceError extends BalanceState {
  final String message;

  const BalanceError(this.message);

  @override
  List<Object?> get props => [message];
}

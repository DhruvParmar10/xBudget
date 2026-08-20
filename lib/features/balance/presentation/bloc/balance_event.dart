import 'package:equatable/equatable.dart';

abstract class BalanceEvent extends Equatable {
  const BalanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadBalanceEvent extends BalanceEvent {
  const LoadBalanceEvent();
}

class UpdateBalanceEvent extends BalanceEvent {
  final double balance;
  final String source;
  final DateTime? updatedAt;

  const UpdateBalanceEvent({
    required this.balance,
    this.source = 'manual',
    this.updatedAt,
  });

  @override
  List<Object?> get props => [balance, source, updatedAt];
}

class ClearBalanceEvent extends BalanceEvent {
  const ClearBalanceEvent();
}

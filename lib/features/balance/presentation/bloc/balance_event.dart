import 'package:equatable/equatable.dart';
import '../../domain/entities/balance_log_entity.dart';

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
  final String? note;

  const UpdateBalanceEvent({
    required this.balance,
    this.source = 'manual',
    this.updatedAt,
    this.note,
  });

  @override
  List<Object?> get props => [balance, source, updatedAt, note];
}

class AddBalanceLogEvent extends BalanceEvent {
  final BalanceLogEntity log;

  const AddBalanceLogEvent(this.log);

  @override
  List<Object?> get props => [log];
}

class UpdateBalanceLogEvent extends BalanceEvent {
  final BalanceLogEntity log;

  const UpdateBalanceLogEvent(this.log);

  @override
  List<Object?> get props => [log];
}

class DeleteBalanceLogEvent extends BalanceEvent {
  final String id;

  const DeleteBalanceLogEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ClearBalanceEvent extends BalanceEvent {
  const ClearBalanceEvent();
}

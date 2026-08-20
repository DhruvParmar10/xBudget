import 'package:equatable/equatable.dart';
import 'package:xbudget/domain/entities/budget_category.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionsEvent extends TransactionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final BudgetCategory? category;
  final String? query;
  final String? transactionType;

  const LoadTransactionsEvent({
    this.startDate,
    this.endDate,
    this.category,
    this.query,
    this.transactionType,
  });

  @override
  List<Object?> get props => [startDate, endDate, category, query, transactionType];
}

class FilterCategoryEvent extends TransactionEvent {
  final BudgetCategory? category;

  const FilterCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class UpdateCategoryEvent extends TransactionEvent {
  final String transactionId;
  final BudgetCategory category;

  const UpdateCategoryEvent({
    required this.transactionId,
    required this.category,
  });

  @override
  List<Object?> get props => [transactionId, category];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String transactionId;

  const DeleteTransactionEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

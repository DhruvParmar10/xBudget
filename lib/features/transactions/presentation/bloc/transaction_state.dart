import 'package:equatable/equatable.dart';
import 'package:xbudget/domain/entities/budget_category.dart';
import 'package:xbudget/domain/entities/transaction_entity.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  final Map<BudgetCategory, double> categorySpend;
  final double totalExpense;
  final double totalIncome;
  final BudgetCategory? selectedCategory;

  const TransactionLoaded({
    required this.transactions,
    required this.categorySpend,
    required this.totalExpense,
    required this.totalIncome,
    this.selectedCategory,
  });

  double get netFlow => totalIncome - totalExpense;

  TransactionLoaded copyWith({
    List<TransactionEntity>? transactions,
    Map<BudgetCategory, double>? categorySpend,
    double? totalExpense,
    double? totalIncome,
    BudgetCategory? selectedCategory,
    bool clearCategoryFilter = false,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      categorySpend: categorySpend ?? this.categorySpend,
      totalExpense: totalExpense ?? this.totalExpense,
      totalIncome: totalIncome ?? this.totalIncome,
      selectedCategory: clearCategoryFilter ? null : (selectedCategory ?? this.selectedCategory),
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        categorySpend,
        totalExpense,
        totalIncome,
        selectedCategory,
      ];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

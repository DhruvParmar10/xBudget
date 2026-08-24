import 'package:equatable/equatable.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/transactions/data/models/transaction_model.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

class AddTransactionParams extends Equatable {
  final double amount;
  final String merchant;
  final String transactionType;
  final BudgetCategory category;
  final bool isP2P;
  final DateTime date;
  final String? note;
  final bool isUserCategorized;

  const AddTransactionParams({
    required this.amount,
    required this.merchant,
    required this.transactionType,
    required this.category,
    this.isP2P = false,
    required this.date,
    this.note,
    this.isUserCategorized = true,
  });

  @override
  List<Object?> get props => [
        amount,
        merchant,
        transactionType,
        category,
        isP2P,
        date,
        note,
        isUserCategorized,
      ];
}

class AddTransactionUseCase implements UseCase<bool, AddTransactionParams> {
  final TransactionRepository repository;

  AddTransactionUseCase(this.repository);

  @override
  Future<bool> call(AddTransactionParams params) async {
    final now = DateTime.now();
    final rawMessage = 'Manual entry: ${params.merchant} (₹${params.amount.toStringAsFixed(2)})';
    final id = TransactionModel.generateId(
      amount: params.amount,
      merchant: params.merchant,
      date: params.date,
      rawMessage: rawMessage,
    );

    final txn = TransactionModel(
      id: id,
      amount: params.amount,
      merchant: params.merchant,
      transactionType: params.transactionType,
      category: params.category,
      isP2P: params.isP2P,
      date: params.date,
      rawMessage: rawMessage,
      isUserCategorized: params.isUserCategorized,
      note: params.note,
      createdAt: now,
    );

    return await repository.saveTransaction(txn);
  }
}

import 'package:equatable/equatable.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/domain/entities/budget_category.dart';
import 'package:xbudget/domain/entities/transaction_entity.dart';
import 'package:xbudget/domain/repositories/transaction_repository.dart';

class GetTransactionsParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final BudgetCategory? category;
  final String? query;
  final String? transactionType;

  const GetTransactionsParams({
    this.startDate,
    this.endDate,
    this.category,
    this.query,
    this.transactionType,
  });

  @override
  List<Object?> get props => [startDate, endDate, category, query, transactionType];
}

class GetTransactionsUseCase implements UseCase<List<TransactionEntity>, GetTransactionsParams> {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  @override
  Future<List<TransactionEntity>> call(GetTransactionsParams params) async {
    return await repository.getTransactions(
      startDate: params.startDate,
      endDate: params.endDate,
      category: params.category,
      query: params.query,
      transactionType: params.transactionType,
    );
  }
}

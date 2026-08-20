import 'package:equatable/equatable.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

class GetSpendBreakdownParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;

  const GetSpendBreakdownParams({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class GetSpendBreakdownUseCase implements UseCase<Map<BudgetCategory, double>, GetSpendBreakdownParams> {
  final TransactionRepository repository;

  GetSpendBreakdownUseCase(this.repository);

  @override
  Future<Map<BudgetCategory, double>> call(GetSpendBreakdownParams params) async {
    return await repository.getSpendByCategory(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

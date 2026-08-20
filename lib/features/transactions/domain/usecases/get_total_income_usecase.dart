import 'package:equatable/equatable.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

class GetTotalIncomeParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;

  const GetTotalIncomeParams({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class GetTotalIncomeUseCase implements UseCase<double, GetTotalIncomeParams> {
  final TransactionRepository repository;

  GetTotalIncomeUseCase(this.repository);

  @override
  Future<double> call(GetTotalIncomeParams params) async {
    return await repository.getTotalIncome(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

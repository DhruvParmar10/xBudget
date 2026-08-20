import 'package:equatable/equatable.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

class GetTotalSpendParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;

  const GetTotalSpendParams({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class GetTotalSpendUseCase implements UseCase<double, GetTotalSpendParams> {
  final TransactionRepository repository;

  GetTotalSpendUseCase(this.repository);

  @override
  Future<double> call(GetTotalSpendParams params) async {
    return await repository.getTotalSpend(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

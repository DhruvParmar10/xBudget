import 'package:equatable/equatable.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/domain/repositories/transaction_repository.dart';

class DeleteTransactionParams extends Equatable {
  final String id;

  const DeleteTransactionParams(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteTransactionUseCase implements UseCase<bool, DeleteTransactionParams> {
  final TransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  @override
  Future<bool> call(DeleteTransactionParams params) async {
    return await repository.deleteTransaction(params.id);
  }
}

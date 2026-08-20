import 'package:equatable/equatable.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

class UpdateTransactionCategoryParams extends Equatable {
  final String id;
  final BudgetCategory category;
  final bool isUserCategorized;

  const UpdateTransactionCategoryParams({
    required this.id,
    required this.category,
    this.isUserCategorized = true,
  });

  @override
  List<Object?> get props => [id, category, isUserCategorized];
}

class UpdateTransactionCategoryUseCase implements UseCase<bool, UpdateTransactionCategoryParams> {
  final TransactionRepository repository;

  UpdateTransactionCategoryUseCase(this.repository);

  @override
  Future<bool> call(UpdateTransactionCategoryParams params) async {
    return await repository.updateTransactionCategory(
      params.id,
      params.category,
      isUserCategorized: params.isUserCategorized,
    );
  }
}

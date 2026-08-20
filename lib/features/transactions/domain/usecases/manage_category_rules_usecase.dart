import 'package:equatable/equatable.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

class SaveCategoryRuleParams extends Equatable {
  final String keyword;
  final BudgetCategory category;

  const SaveCategoryRuleParams(this.keyword, this.category);

  @override
  List<Object?> get props => [keyword, category];
}

class SaveCategoryRuleUseCase implements UseCase<void, SaveCategoryRuleParams> {
  final TransactionRepository repository;

  SaveCategoryRuleUseCase(this.repository);

  @override
  Future<void> call(SaveCategoryRuleParams params) async {
    await repository.saveUserCategoryRule(params.keyword, params.category);
  }
}

class GetCategoryRulesUseCase implements UseCase<Map<String, BudgetCategory>, NoParams> {
  final TransactionRepository repository;

  GetCategoryRulesUseCase(this.repository);

  @override
  Future<Map<String, BudgetCategory>> call(NoParams params) async {
    return await repository.getUserCategoryRules();
  }
}

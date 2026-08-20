import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/domain/repositories/transaction_repository.dart';

class ClearAllDataUseCase implements UseCase<void, NoParams> {
  final AppPreferences preferences;
  final TransactionRepository repository;

  ClearAllDataUseCase({
    required this.preferences,
    required this.repository,
  });

  @override
  Future<void> call(NoParams params) async {
    await preferences.clearAll();
    final all = await repository.getTransactions();
    for (final t in all) {
      await repository.deleteTransaction(t.id);
    }
  }
}

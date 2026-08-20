import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';

class ClearBalanceUseCase implements UseCase<bool, NoParams> {
  final AppPreferences preferences;

  ClearBalanceUseCase(this.preferences);

  @override
  Future<bool> call(NoParams params) async {
    return await preferences.clearCurrentBalance();
  }
}

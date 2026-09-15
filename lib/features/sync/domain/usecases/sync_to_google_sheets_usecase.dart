import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/services/google_sheets_service.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/core/utils/cycle_date_util.dart';
import 'package:xbudget/features/balance/domain/usecases/get_balance_usecase.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

class SyncToGoogleSheetsUseCase
    implements UseCase<GoogleSheetsSyncSummary, NoParams> {
  final GoogleSheetsService googleSheetsService;
  final TransactionRepository repository;
  final AppPreferences preferences;
  final GetBalanceUseCase? getBalanceUseCase;

  SyncToGoogleSheetsUseCase({
    required this.googleSheetsService,
    required this.repository,
    required this.preferences,
    this.getBalanceUseCase,
  });

  @override
  Future<GoogleSheetsSyncSummary> call(NoParams params) async {
    // 1. Fetch all local transactions
    final transactions = await repository.getTransactions();

    // 2. Fetch dynamically calculated current balance
    double? currentBalance;
    try {
      final balanceUseCase = getBalanceUseCase ??
          GetBalanceUseCase(
            preferences: preferences,
            repository: repository,
          );
      final balanceData = await balanceUseCase(const NoParams());
      currentBalance = balanceData.currentBalance;
    } catch (_) {
      currentBalance = preferences.currentBalance;
    }

    // 3. Compute active monthly billing cycle range
    final now = DateTime.now();
    final cycleRange = CycleDateUtil.getCycleRange(
      now: now,
      mode: preferences.cycleMode,
      startDay: preferences.cycleStartDay,
      endDay: preferences.cycleEndDay,
    );

    // 4. Perform sync via GoogleSheetsService with dynamic balance & active cycle dates
    final summary = await googleSheetsService.syncTransactions(
      transactions,
      currentBalance: currentBalance,
      cycleStartDate: cycleRange.start,
      cycleEndDate: cycleRange.end,
    );

    // 5. Update cached preferences if successful
    if (summary.isSuccess && summary.spreadsheetId.isNotEmpty) {
      await preferences.setGoogleSheetId(summary.spreadsheetId);
      await preferences.setLastGoogleSheetSyncTimestamp(summary.syncTimestamp);
      if (googleSheetsService.currentEmail != null) {
        await preferences.setGoogleAccountEmail(googleSheetsService.currentEmail);
      }
    }

    return summary;
  }
}

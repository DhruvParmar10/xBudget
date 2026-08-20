import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/services/google_sheets_service.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';

class SyncToGoogleSheetsUseCase
    implements UseCase<GoogleSheetsSyncSummary, NoParams> {
  final GoogleSheetsService googleSheetsService;
  final TransactionRepository repository;
  final AppPreferences preferences;

  SyncToGoogleSheetsUseCase({
    required this.googleSheetsService,
    required this.repository,
    required this.preferences,
  });

  @override
  Future<GoogleSheetsSyncSummary> call(NoParams params) async {
    // 1. Fetch all local transactions
    final transactions = await repository.getTransactions();

    // 2. Perform sync via GoogleSheetsService
    final summary = await googleSheetsService.syncTransactions(transactions);

    // 3. Update cached preferences if successful
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

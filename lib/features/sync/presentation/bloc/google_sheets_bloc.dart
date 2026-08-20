import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/sync/domain/usecases/google_auth_usecases.dart';
import 'package:xbudget/features/sync/domain/usecases/sync_to_google_sheets_usecase.dart';
import 'google_sheets_event.dart';
import 'google_sheets_state.dart';

class GoogleSheetsBloc extends Bloc<GoogleSheetsEvent, GoogleSheetsState> {
  final SignInGoogleUseCase signInGoogleUseCase;
  final SignOutGoogleUseCase signOutGoogleUseCase;
  final GetGoogleAuthStatusUseCase getGoogleAuthStatusUseCase;
  final SyncToGoogleSheetsUseCase syncToGoogleSheetsUseCase;
  final AppPreferences preferences;

  GoogleSheetsBloc({
    required this.signInGoogleUseCase,
    required this.signOutGoogleUseCase,
    required this.getGoogleAuthStatusUseCase,
    required this.syncToGoogleSheetsUseCase,
    required this.preferences,
  }) : super(GoogleSheetsInitial(
          lastSyncTimestamp: preferences.lastGoogleSheetSyncTimestamp,
        )) {
    on<CheckGoogleSheetsAuthEvent>(_onCheckAuth);
    on<SignInGoogleSheetsEvent>(_onSignIn);
    on<SignOutGoogleSheetsEvent>(_onSignOut);
    on<SyncToGoogleSheetsEvent>(_onSyncToGoogleSheets);
  }

  Future<void> _onCheckAuth(
    CheckGoogleSheetsAuthEvent event,
    Emitter<GoogleSheetsState> emit,
  ) async {
    final status = await getGoogleAuthStatusUseCase(const NoParams());

    if (status.isSignedIn && status.email != null) {
      emit(
        GoogleSheetsAuthenticated(
          email: status.email!,
          spreadsheetId: status.spreadsheetId,
          lastSyncTimestamp: status.lastSyncTimestamp,
        ),
      );
    } else {
      emit(
        GoogleSheetsUnauthenticated(
          lastSyncTimestamp: status.lastSyncTimestamp,
        ),
      );
    }
  }

  Future<void> _onSignIn(
    SignInGoogleSheetsEvent event,
    Emitter<GoogleSheetsState> emit,
  ) async {
    emit(
      GoogleSheetsLoading(
        message: 'Signing in to Google account...',
        lastSyncTimestamp: preferences.lastGoogleSheetSyncTimestamp,
      ),
    );

    final success = await signInGoogleUseCase(const NoParams());

    if (success) {
      final status = await getGoogleAuthStatusUseCase(const NoParams());
      emit(
        GoogleSheetsAuthenticated(
          email: status.email ?? 'Google User',
          spreadsheetId: status.spreadsheetId,
          lastSyncTimestamp: status.lastSyncTimestamp,
        ),
      );
    } else {
      emit(
        GoogleSheetsError(
          errorMessage: 'Google Sign-In was cancelled or failed.',
          isAuthenticated: false,
          lastSyncTimestamp: preferences.lastGoogleSheetSyncTimestamp,
        ),
      );
    }
  }

  Future<void> _onSignOut(
    SignOutGoogleSheetsEvent event,
    Emitter<GoogleSheetsState> emit,
  ) async {
    emit(
      GoogleSheetsLoading(
        message: 'Disconnecting Google account...',
        lastSyncTimestamp: preferences.lastGoogleSheetSyncTimestamp,
      ),
    );

    await signOutGoogleUseCase(const NoParams());

    emit(const GoogleSheetsUnauthenticated());
  }

  Future<void> _onSyncToGoogleSheets(
    SyncToGoogleSheetsEvent event,
    Emitter<GoogleSheetsState> emit,
  ) async {
    emit(
      GoogleSheetsLoading(
        message: 'Syncing transactions to Google Sheets...',
        lastSyncTimestamp: preferences.lastGoogleSheetSyncTimestamp,
      ),
    );

    final summary = await syncToGoogleSheetsUseCase(const NoParams());

    if (summary.isSuccess) {
      emit(
        GoogleSheetsSyncSuccess(
          message: summary.newRowsAppended > 0
              ? 'Synced ${summary.totalLocalTransactions} transactions (${summary.newRowsAppended} new rows added to Drive)'
              : 'Google Sheet is up to date (${summary.totalLocalTransactions} transactions)',
          newRowsAppended: summary.newRowsAppended,
          totalTransactions: summary.totalLocalTransactions,
          spreadsheetId: summary.spreadsheetId,
          lastSyncTimestamp: summary.syncTimestamp,
        ),
      );
    } else {
      emit(
        GoogleSheetsError(
          errorMessage: summary.errorMessage ?? 'Google Sheets sync failed.',
          isAuthenticated: true,
          lastSyncTimestamp: preferences.lastGoogleSheetSyncTimestamp,
        ),
      );
    }
  }
}

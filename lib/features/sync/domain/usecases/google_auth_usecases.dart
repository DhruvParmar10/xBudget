import 'package:equatable/equatable.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/services/google_sheets_service.dart';
import 'package:xbudget/core/usecases/usecase.dart';

/// Information about the current Google authentication status.
class GoogleAuthStatus extends Equatable {
  final bool isSignedIn;
  final String? email;
  final String? spreadsheetId;
  final DateTime? lastSyncTimestamp;

  const GoogleAuthStatus({
    required this.isSignedIn,
    this.email,
    this.spreadsheetId,
    this.lastSyncTimestamp,
  });

  @override
  List<Object?> get props => [
        isSignedIn,
        email,
        spreadsheetId,
        lastSyncTimestamp,
      ];
}

/// Signs in interactively via Google OAuth and initializes APIs.
class SignInGoogleUseCase implements UseCase<bool, NoParams> {
  final GoogleSheetsService googleSheetsService;
  final AppPreferences preferences;

  SignInGoogleUseCase({
    required this.googleSheetsService,
    required this.preferences,
  });

  @override
  Future<bool> call(NoParams params) async {
    final success = await googleSheetsService.signIn();
    if (success) {
      if (googleSheetsService.currentEmail != null) {
        await preferences.setGoogleAccountEmail(googleSheetsService.currentEmail);
      }
      final sheetId = await googleSheetsService.initSheet();
      if (sheetId != null) {
        await preferences.setGoogleSheetId(sheetId);
      }
    }
    return success;
  }
}

/// Signs out the user and clears stored Google authentication preferences.
class SignOutGoogleUseCase implements UseCase<void, NoParams> {
  final GoogleSheetsService googleSheetsService;
  final AppPreferences preferences;

  SignOutGoogleUseCase({
    required this.googleSheetsService,
    required this.preferences,
  });

  @override
  Future<void> call(NoParams params) async {
    await googleSheetsService.signOut();
    await preferences.clearGoogleSheetConfig();
  }
}

/// Checks current sign-in status (restoring silent session if available).
class GetGoogleAuthStatusUseCase implements UseCase<GoogleAuthStatus, NoParams> {
  final GoogleSheetsService googleSheetsService;
  final AppPreferences preferences;

  GetGoogleAuthStatusUseCase({
    required this.googleSheetsService,
    required this.preferences,
  });

  @override
  Future<GoogleAuthStatus> call(NoParams params) async {
    bool signedIn = googleSheetsService.isSignedIn;

    // Try silent sign-in to restore existing session if cached email exists
    if (!signedIn && preferences.googleAccountEmail != null) {
      signedIn = await googleSheetsService.signInSilently();
    }

    final email = googleSheetsService.currentEmail ?? preferences.googleAccountEmail;
    final sheetId = googleSheetsService.spreadsheetId ?? preferences.googleSheetId;

    if (sheetId != null && googleSheetsService.spreadsheetId == null) {
      googleSheetsService.setSpreadsheetId(sheetId);
    }

    return GoogleAuthStatus(
      isSignedIn: signedIn,
      email: signedIn ? email : null,
      spreadsheetId: signedIn ? sheetId : null,
      lastSyncTimestamp: preferences.lastGoogleSheetSyncTimestamp,
    );
  }
}

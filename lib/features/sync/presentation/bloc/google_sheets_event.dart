import 'package:equatable/equatable.dart';

abstract class GoogleSheetsEvent extends Equatable {
  const GoogleSheetsEvent();

  @override
  List<Object?> get props => [];
}

/// Checks the current authentication status (silently re-authenticating if needed).
class CheckGoogleSheetsAuthEvent extends GoogleSheetsEvent {
  const CheckGoogleSheetsAuthEvent();
}

/// Prompts the user with the interactive Google Sign-In sheet.
class SignInGoogleSheetsEvent extends GoogleSheetsEvent {
  const SignInGoogleSheetsEvent();
}

/// Signs out the user and clears Google Sheets preferences.
class SignOutGoogleSheetsEvent extends GoogleSheetsEvent {
  const SignOutGoogleSheetsEvent();
}

/// Triggers transaction sync to the user's Google Sheet in Google Drive.
class SyncToGoogleSheetsEvent extends GoogleSheetsEvent {
  const SyncToGoogleSheetsEvent();
}

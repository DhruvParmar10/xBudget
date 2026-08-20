import 'package:equatable/equatable.dart';

abstract class GoogleSheetsState extends Equatable {
  final DateTime? lastSyncTimestamp;

  const GoogleSheetsState({this.lastSyncTimestamp});

  @override
  List<Object?> get props => [lastSyncTimestamp];
}

/// Initial uninitialized state.
class GoogleSheetsInitial extends GoogleSheetsState {
  const GoogleSheetsInitial({super.lastSyncTimestamp});
}

/// In-progress state (signing in, discovering spreadsheet, or appending rows).
class GoogleSheetsLoading extends GoogleSheetsState {
  final String message;

  const GoogleSheetsLoading({
    required this.message,
    super.lastSyncTimestamp,
  });

  @override
  List<Object?> get props => [message, lastSyncTimestamp];
}

/// User is authenticated with Google and spreadsheet info is available.
class GoogleSheetsAuthenticated extends GoogleSheetsState {
  final String email;
  final String? spreadsheetId;

  const GoogleSheetsAuthenticated({
    required this.email,
    this.spreadsheetId,
    super.lastSyncTimestamp,
  });

  @override
  List<Object?> get props => [email, spreadsheetId, lastSyncTimestamp];
}

/// No Google account is connected.
class GoogleSheetsUnauthenticated extends GoogleSheetsState {
  const GoogleSheetsUnauthenticated({super.lastSyncTimestamp});
}

/// Google Sheets sync completed successfully.
class GoogleSheetsSyncSuccess extends GoogleSheetsState {
  final String message;
  final int newRowsAppended;
  final int totalTransactions;
  final String spreadsheetId;

  const GoogleSheetsSyncSuccess({
    required this.message,
    required this.newRowsAppended,
    required this.totalTransactions,
    required this.spreadsheetId,
    super.lastSyncTimestamp,
  });

  @override
  List<Object?> get props => [
        message,
        newRowsAppended,
        totalTransactions,
        spreadsheetId,
        lastSyncTimestamp,
      ];
}

/// An error occurred during auth or sync operation.
class GoogleSheetsError extends GoogleSheetsState {
  final String errorMessage;
  final bool isAuthenticated;

  const GoogleSheetsError({
    required this.errorMessage,
    this.isAuthenticated = false,
    super.lastSyncTimestamp,
  });

  @override
  List<Object?> get props => [
        errorMessage,
        isAuthenticated,
        lastSyncTimestamp,
      ];
}

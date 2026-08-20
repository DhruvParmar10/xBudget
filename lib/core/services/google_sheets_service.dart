import 'dart:developer' as developer;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';

/// Result summary returned after a Google Sheets synchronization run.
class GoogleSheetsSyncSummary {
  final int totalLocalTransactions;
  final int newRowsAppended;
  final String spreadsheetId;
  final DateTime syncTimestamp;
  final String? errorMessage;

  const GoogleSheetsSyncSummary({
    required this.totalLocalTransactions,
    required this.newRowsAppended,
    required this.spreadsheetId,
    required this.syncTimestamp,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

/// Service to handle Google OAuth authentication, Drive spreadsheet discovery/creation,
/// and syncing transaction records to Google Sheets.
class GoogleSheetsService {
  static const String defaultSpreadsheetTitle = 'BudgetApp_Data';
  static const List<String> requiredScopes = [
    drive.DriveApi.driveFileScope,
    sheets.SheetsApi.spreadsheetsScope,
  ];

  final GoogleSignIn _googleSignIn;
  drive.DriveApi? _driveApi;
  sheets.SheetsApi? _sheetsApi;
  String? _spreadsheetId;

  GoogleSheetsService({
    GoogleSignIn? googleSignIn,
    drive.DriveApi? driveApi,
    sheets.SheetsApi? sheetsApi,
    String? initialSpreadsheetId,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: requiredScopes,
            ),
        _driveApi = driveApi,
        _sheetsApi = sheetsApi,
        _spreadsheetId = initialSpreadsheetId;

  /// Current spreadsheet ID if discovered or initialized.
  String? get spreadsheetId => _spreadsheetId;

  /// Sets the spreadsheet ID directly (e.g. from cached preferences).
  void setSpreadsheetId(String? id) {
    _spreadsheetId = id;
  }

  /// Whether a user is currently signed in.
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Current signed-in Google account.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Current signed-in user's email.
  String? get currentEmail => _googleSignIn.currentUser?.email;

  /// Helper to initialize API clients from an authenticated HTTP client.
  Future<bool> _initApis() async {
    if (_driveApi != null && _sheetsApi != null) return true;

    try {
      final http.Client? authenticatedClient =
          await _googleSignIn.authenticatedClient();
      if (authenticatedClient == null) {
        developer.log(
          'Failed to obtain authenticated HTTP client.',
          name: 'GoogleSheetsService',
        );
        return false;
      }

      _driveApi = drive.DriveApi(authenticatedClient);
      _sheetsApi = sheets.SheetsApi(authenticatedClient);
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize Drive and Sheets APIs: $e',
        name: 'GoogleSheetsService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 1. Interactive Sign In
  /// Prompts the user to sign in with Google and initializes the API clients.
  Future<bool> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        developer.log(
          'Google Sign-In canceled by user.',
          name: 'GoogleSheetsService',
        );
        return false;
      }

      return await _initApis();
    } catch (e, stackTrace) {
      developer.log(
        'Error during Google Sign-In: $e',
        name: 'GoogleSheetsService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Silent Sign In
  /// Attempts to authenticate without showing a user prompt (restores existing session).
  Future<bool> signInSilently() async {
    try {
      final GoogleSignInAccount? account =
          await _googleSignIn.signInSilently();
      if (account == null) {
        return false;
      }

      return await _initApis();
    } catch (e, stackTrace) {
      developer.log(
        'Error during silent Google Sign-In: $e',
        name: 'GoogleSheetsService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Sign Out
  /// Disconnects the user account and cleans up API instances.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      developer.log('Error during sign out: $e', name: 'GoogleSheetsService');
    } finally {
      _driveApi = null;
      _sheetsApi = null;
      _spreadsheetId = null;
    }
  }

  /// 2. File Discovery & Creation
  /// Searches for spreadsheet named [sheetTitle] in the user's Google Drive.
  /// If found, caches and returns its ID.
  /// If not found, creates a new spreadsheet with the header row:
  /// `['Date', 'Category', 'Amount', 'Type', 'Merchant', 'Notes', 'Transaction ID']`.
  Future<String?> initSheet({
    String sheetTitle = defaultSpreadsheetTitle,
  }) async {
    try {
      final apiReady = await _initApis();
      if (!apiReady || _driveApi == null || _sheetsApi == null) {
        developer.log(
          'Drive or Sheets API client not initialized.',
          name: 'GoogleSheetsService',
        );
        return null;
      }

      // Check if we already have a valid spreadsheet ID
      if (_spreadsheetId != null && _spreadsheetId!.isNotEmpty) {
        try {
          final existing = await _sheetsApi!.spreadsheets.get(_spreadsheetId!);
          if (existing.spreadsheetId != null) {
            return _spreadsheetId;
          }
        } catch (_) {
          // ID might be invalid/deleted; fallback to searching
          _spreadsheetId = null;
        }
      }

      // 1. Search Google Drive for existing spreadsheet
      final fileList = await _driveApi!.files.list(
        q: "name = '$sheetTitle' and mimeType = 'application/vnd.google-apps.spreadsheet' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final existingFile = fileList.files!.first;
        _spreadsheetId = existingFile.id;
        developer.log(
          'Found existing spreadsheet: $_spreadsheetId',
          name: 'GoogleSheetsService',
        );
        return _spreadsheetId;
      }

      // 2. Create new spreadsheet if not found
      final newSpreadsheet = sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: sheetTitle),
      );

      final created = await _sheetsApi!.spreadsheets.create(newSpreadsheet);
      _spreadsheetId = created.spreadsheetId;

      if (_spreadsheetId == null) {
        developer.log(
          'Failed to retrieve spreadsheetId after creation.',
          name: 'GoogleSheetsService',
        );
        return null;
      }

      // 3. Insert default header row
      final headerRange = sheets.ValueRange(
        values: [
          [
            'Date',
            'Category',
            'Amount',
            'Type',
            'Merchant',
            'Notes',
            'Transaction ID',
          ],
        ],
      );

      await _sheetsApi!.spreadsheets.values.append(
        headerRange,
        _spreadsheetId!,
        'A1',
        valueInputOption: 'USER_ENTERED',
      );

      developer.log(
        'Created new spreadsheet with ID: $_spreadsheetId',
        name: 'GoogleSheetsService',
      );
      return _spreadsheetId;
    } catch (e, stackTrace) {
      developer.log(
        'Error during initSheet: $e',
        name: 'GoogleSheetsService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// 3. Writing Data - Single Transaction
  /// Appends a single transaction row to the end of the spreadsheet.
  Future<bool> addTransaction({
    required String date,
    required String category,
    required double amount,
    String type = 'expense',
    String merchant = '',
    String notes = '',
    String id = '',
  }) async {
    try {
      final sheetId = await initSheet();
      if (sheetId == null || _sheetsApi == null) {
        developer.log(
          'Cannot add transaction: spreadsheet initialization failed.',
          name: 'GoogleSheetsService',
        );
        return false;
      }

      final valueRange = sheets.ValueRange(
        values: [
          [date, category, amount, type, merchant, notes, id],
        ],
      );

      await _sheetsApi!.spreadsheets.values.append(
        valueRange,
        sheetId,
        'A1',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );

      developer.log(
        'Appended single transaction to sheet successfully.',
        name: 'GoogleSheetsService',
      );
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error appending single transaction: $e',
        name: 'GoogleSheetsService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 4. Bulk Sync Transactions (Idempotent)
  /// Fetches existing transaction IDs from column G to avoid duplicate rows,
  /// then appends only the new transactions in bulk.
  Future<GoogleSheetsSyncSummary> syncTransactions(
    List<TransactionEntity> transactions,
  ) async {
    final now = DateTime.now();

    try {
      final sheetId = await initSheet();
      if (sheetId == null || _sheetsApi == null) {
        return GoogleSheetsSyncSummary(
          totalLocalTransactions: transactions.length,
          newRowsAppended: 0,
          spreadsheetId: '',
          syncTimestamp: now,
          errorMessage: 'Failed to access or create Google Sheet.',
        );
      }

      // Fetch existing transaction IDs from column G to ensure idempotency
      final Set<String> existingIds = {};
      try {
        final existingValues = await _sheetsApi!.spreadsheets.values.get(
          sheetId,
          'A:G',
        );

        if (existingValues.values != null) {
          for (final row in existingValues.values!) {
            if (row.length >= 7 && row[6] != null) {
              final idStr = row[6].toString().trim();
              if (idStr.isNotEmpty && idStr != 'Transaction ID') {
                existingIds.add(idStr);
              }
            }
          }
        }
      } catch (e) {
        developer.log(
          'Note: Could not query existing sheet rows (might be empty): $e',
          name: 'GoogleSheetsService',
        );
      }

      // Filter out already synced transactions
      final toAppend = transactions.where((t) => !existingIds.contains(t.id)).toList();

      if (toAppend.isEmpty) {
        developer.log(
          'All ${transactions.length} transactions are already present in Google Sheet.',
          name: 'GoogleSheetsService',
        );
        return GoogleSheetsSyncSummary(
          totalLocalTransactions: transactions.length,
          newRowsAppended: 0,
          spreadsheetId: sheetId,
          syncTimestamp: now,
        );
      }

      // Format rows chronologically ascending so oldest are on top, newest at bottom
      final sorted = List<TransactionEntity>.from(toAppend)
        ..sort((a, b) => a.date.compareTo(b.date));

      final rows = sorted.map((t) {
        final dateStr =
            '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
        return [
          dateStr,
          t.category.displayName,
          t.amount,
          t.transactionType,
          t.merchant,
          t.note ?? '',
          t.id,
        ];
      }).toList();

      final valueRange = sheets.ValueRange(values: rows);

      await _sheetsApi!.spreadsheets.values.append(
        valueRange,
        sheetId,
        'A1',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );

      developer.log(
        'Appended ${rows.length} new transactions to Google Sheet $sheetId.',
        name: 'GoogleSheetsService',
      );

      return GoogleSheetsSyncSummary(
        totalLocalTransactions: transactions.length,
        newRowsAppended: rows.length,
        spreadsheetId: sheetId,
        syncTimestamp: now,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing transactions to Google Sheets: $e',
        name: 'GoogleSheetsService',
        error: e,
        stackTrace: stackTrace,
      );
      return GoogleSheetsSyncSummary(
        totalLocalTransactions: transactions.length,
        newRowsAppended: 0,
        spreadsheetId: _spreadsheetId ?? '',
        syncTimestamp: now,
        errorMessage: 'Failed to sync to Google Sheets: $e',
      );
    }
  }

  /// Generates the direct web URL to open the Google Sheet in browser or app.
  String? getSpreadsheetUrl([String? sheetId]) {
    final id = sheetId ?? _spreadsheetId;
    if (id == null || id.isEmpty) return null;
    return 'https://docs.google.com/spreadsheets/d/$id/edit';
  }
}

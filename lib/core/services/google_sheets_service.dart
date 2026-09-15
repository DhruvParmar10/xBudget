import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
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
/// and syncing transaction records along with an interactive visual Dashboard and Pie Chart.
class GoogleSheetsService {
  static const String defaultSpreadsheetTitle = 'BudgetApp_Data';
  static const String dashboardSheetTitle = 'Dashboard';
  static const String transactionsSheetTitle = 'Transactions';
  static const int defaultPieChartId = 1001;

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
  /// If found, verifies its sheets structure (Dashboard & Transactions).
  /// If not found, creates a new spreadsheet and initializes Dashboard + Transactions.
  Future<String?> initSheet({
    String sheetTitle = defaultSpreadsheetTitle,
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
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
            await _ensureSheetsAndStructure(
              _spreadsheetId!,
              currentBalance: currentBalance,
              cycleStartDate: cycleStartDate,
              cycleEndDate: cycleEndDate,
            );
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
        if (_spreadsheetId != null) {
          await _ensureSheetsAndStructure(
            _spreadsheetId!,
            currentBalance: currentBalance,
            cycleStartDate: cycleStartDate,
            cycleEndDate: cycleEndDate,
          );
        }
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

      developer.log(
        'Created new spreadsheet with ID: $_spreadsheetId',
        name: 'GoogleSheetsService',
      );

      // 3. Set up Dashboard and Transactions tabs
      await _ensureSheetsAndStructure(
        _spreadsheetId!,
        currentBalance: currentBalance,
        cycleStartDate: cycleStartDate,
        cycleEndDate: cycleEndDate,
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

  /// Ensures that both the `Dashboard` and `Transactions` sheets exist,
  /// initializes standard headers on `Transactions`, and populates `Dashboard`.
  Future<({int dashboardSheetId, int transactionsSheetId})?> _ensureSheetsAndStructure(
    String spreadsheetId, {
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
  }) async {
    try {
      final spreadsheet = await _sheetsApi!.spreadsheets.get(spreadsheetId);
      final existingSheets = spreadsheet.sheets ?? [];

      int? dashboardSheetId;
      int? transactionsSheetId;

      for (final s in existingSheets) {
        final title = s.properties?.title;
        final id = s.properties?.sheetId;
        if (title == dashboardSheetTitle) {
          dashboardSheetId = id;
        } else if (title == transactionsSheetTitle) {
          transactionsSheetId = id;
        }
      }

      final List<sheets.Request> initRequests = [];
      int maxSheetId = 0;
      for (final s in existingSheets) {
        if (s.properties?.sheetId != null) {
          maxSheetId = math.max(maxSheetId, s.properties!.sheetId!);
        }
      }

      // Handle Transactions Sheet: Rename Sheet1 if needed, or add new sheet
      if (transactionsSheetId == null) {
        final sheet1 = existingSheets.firstWhere(
          (s) => s.properties?.title == 'Sheet1',
          orElse: () => sheets.Sheet(),
        );

        if (sheet1.properties?.sheetId != null) {
          transactionsSheetId = sheet1.properties!.sheetId!;
          initRequests.add(
            sheets.Request(
              updateSheetProperties: sheets.UpdateSheetPropertiesRequest(
                properties: sheets.SheetProperties(
                  sheetId: transactionsSheetId,
                  title: transactionsSheetTitle,
                  index: 1,
                ),
                fields: 'title,index',
              ),
            ),
          );
        } else {
          maxSheetId++;
          transactionsSheetId = maxSheetId;
          initRequests.add(
            sheets.Request(
              addSheet: sheets.AddSheetRequest(
                properties: sheets.SheetProperties(
                  sheetId: transactionsSheetId,
                  title: transactionsSheetTitle,
                  index: 1,
                ),
              ),
            ),
          );
        }
      }

      // Handle Dashboard Sheet: Add if it doesn't exist
      if (dashboardSheetId == null) {
        maxSheetId++;
        dashboardSheetId = maxSheetId;
        initRequests.add(
          sheets.Request(
            addSheet: sheets.AddSheetRequest(
              properties: sheets.SheetProperties(
                sheetId: dashboardSheetId,
                title: dashboardSheetTitle,
                index: 0,
              ),
            ),
          ),
        );
      }

      if (initRequests.isNotEmpty) {
        await _sheetsApi!.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(requests: initRequests),
          spreadsheetId,
        );
      }

      // Ensure header row in Transactions sheet
      try {
        final existingHeader = await _sheetsApi!.spreadsheets.values.get(
          spreadsheetId,
          '$transactionsSheetTitle!A1:G1',
        );

        if (existingHeader.values == null || existingHeader.values!.isEmpty) {
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

          await _sheetsApi!.spreadsheets.values.update(
            headerRange,
            spreadsheetId,
            '$transactionsSheetTitle!A1',
            valueInputOption: 'USER_ENTERED',
          );
        }
      } catch (e) {
        developer.log(
          'Transactions header check/setup notice: $e',
          name: 'GoogleSheetsService',
        );
      }

      // Populate or refresh Dashboard sheet
      await _updateDashboardSheet(
        spreadsheetId: spreadsheetId,
        dashboardSheetId: dashboardSheetId,
        currentBalance: currentBalance,
        cycleStartDate: cycleStartDate,
        cycleEndDate: cycleEndDate,
      );

      return (
        dashboardSheetId: dashboardSheetId,
        transactionsSheetId: transactionsSheetId,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error ensuring sheets and structure: $e',
        name: 'GoogleSheetsService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Builds and updates the visual Dashboard sheet containing:
  /// - Current Balance card (dynamically computed)
  /// - Active Billing Cycle date range reference cells (B3 to D3)
  /// - Monthly Income & Monthly Expense formulas scoped to active cycle
  /// - Net Monthly Flow metric
  /// - All-Time Income & Expense metrics
  /// - Category Expense breakdown table scoped to active cycle
  /// - Interactive Embedded Pie Chart
  Future<void> _updateDashboardSheet({
    required String spreadsheetId,
    required int dashboardSheetId,
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
    DateTime? syncTime,
  }) async {
    try {
      final now = syncTime ?? DateTime.now();
      final cycleStart =
          cycleStartDate ?? DateTime(now.year, now.month, 1);
      final cycleEnd =
          cycleEndDate ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final cycleStartStr =
          '${cycleStart.year}-${cycleStart.month.toString().padLeft(2, '0')}-${cycleStart.day.toString().padLeft(2, '0')}';
      final cycleEndStr =
          '${cycleEnd.year}-${cycleEnd.month.toString().padLeft(2, '0')}-${cycleEnd.day.toString().padLeft(2, '0')}';
      final timestampStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // 1. Prepare Dashboard Cell Content
      final List<List<Object>> dashboardRows = [
        // Row 1: Banner Title
        ['xBudget Financial Dashboard', '', '', '', '', '', ''],
        // Row 2: Subtitle / Timestamp
        ['Last Synced: $timestampStr', '', '', '', '', '', ''],
        // Row 3: Active Billing Cycle Range
        ['Active Billing Cycle:', cycleStartStr, 'to', cycleEndStr, '', '', ''],
        // Row 4: Monthly KPI Headers
        [
          'Current Balance',
          '',
          'Monthly Income',
          '',
          'Monthly Expense',
          '',
          'Net Monthly Flow',
        ],
        // Row 5: Monthly KPI Values (Scoped to active cycle dates in B3 & D3)
        [
          currentBalance ?? 0.0,
          '',
          '=SUMIFS(Transactions!C:C, Transactions!D:D, "income", Transactions!A:A, ">="&\$B\$3, Transactions!A:A, "<="&\$D\$3)',
          '',
          '=SUMIFS(Transactions!C:C, Transactions!D:D, "expense", Transactions!A:A, ">="&\$B\$3, Transactions!A:A, "<="&\$D\$3)',
          '',
          '=C5-E5',
        ],
        // Row 6: All-Time KPI Headers
        ['', '', 'All-Time Income', '', 'All-Time Expense', '', 'All-Time Net'],
        // Row 7: All-Time KPI Values
        [
          '',
          '',
          '=SUMIF(Transactions!D:D, "income", Transactions!C:C)',
          '',
          '=SUMIF(Transactions!D:D, "expense", Transactions!C:C)',
          '',
          '=C7-E7',
        ],
        // Row 8: Spacer
        ['', '', '', '', '', '', ''],
        // Row 9: Category Breakdown Header
        ['Monthly Expense Category', 'Spend Amount', '', '', '', '', ''],
      ];

      // Rows 10..21: Categories breakdown with SUMIFS formulas (Scoped to active cycle in B3 & D3)
      final categories = BudgetCategory.values;
      for (int i = 0; i < categories.length; i++) {
        final rowNum = 10 + i; // 1-based row index in spreadsheet
        final cat = categories[i];
        dashboardRows.add([
          cat.displayName,
          '=SUMIFS(Transactions!C:C, Transactions!B:B, A$rowNum, Transactions!D:D, "expense", Transactions!A:A, ">="&\$B\$3, Transactions!A:A, "<="&\$D\$3)',
          '',
          '',
          '',
          '',
          '',
        ]);
      }

      // Total row at bottom of category breakdown
      final totalRowNum = 10 + categories.length;
      dashboardRows.add([
        'Total Monthly Expenses',
        '=SUM(B10:B${totalRowNum - 1})',
        '',
        '',
        '',
        '',
        '',
      ]);

      // Write values to Dashboard sheet
      final valueRange = sheets.ValueRange(values: dashboardRows);
      await _sheetsApi!.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        '$dashboardSheetTitle!A1',
        valueInputOption: 'USER_ENTERED',
      );

      // 2. Format Dashboard styling and verify Embedded Pie Chart
      final List<sheets.Request> formattingRequests = [];

      // Title Banner Formatting (Row 1)
      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: 0,
              endRowIndex: 1,
              startColumnIndex: 0,
              endColumnIndex: 7,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                backgroundColor: sheets.Color(
                  red: 0.12,
                  green: 0.16,
                  blue: 0.23,
                ),
                textFormat: sheets.TextFormat(
                  bold: true,
                  fontSize: 14,
                  foregroundColor: sheets.Color(
                    red: 1.0,
                    green: 1.0,
                    blue: 1.0,
                  ),
                ),
                horizontalAlignment: 'LEFT',
              ),
            ),
            fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
          ),
        ),
      );

      // Subtitle Formatting (Row 2)
      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: 1,
              endRowIndex: 2,
              startColumnIndex: 0,
              endColumnIndex: 7,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                textFormat: sheets.TextFormat(
                  italic: true,
                  fontSize: 9,
                  foregroundColor: sheets.Color(
                    red: 0.45,
                    green: 0.45,
                    blue: 0.45,
                  ),
                ),
              ),
            ),
            fields: 'userEnteredFormat(textFormat)',
          ),
        ),
      );

      // Cycle Period Formatting (Row 3)
      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: 2,
              endRowIndex: 3,
              startColumnIndex: 0,
              endColumnIndex: 1,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                textFormat: sheets.TextFormat(
                  bold: true,
                  fontSize: 9,
                  foregroundColor: sheets.Color(
                    red: 0.35,
                    green: 0.40,
                    blue: 0.48,
                  ),
                ),
              ),
            ),
            fields: 'userEnteredFormat(textFormat)',
          ),
        ),
      );

      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: 2,
              endRowIndex: 3,
              startColumnIndex: 1,
              endColumnIndex: 4,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                backgroundColor: sheets.Color(
                  red: 0.94,
                  green: 0.96,
                  blue: 0.99,
                ),
                textFormat: sheets.TextFormat(
                  bold: true,
                  fontSize: 9,
                  foregroundColor: sheets.Color(
                    red: 0.15,
                    green: 0.35,
                    blue: 0.65,
                  ),
                ),
                horizontalAlignment: 'CENTER',
              ),
            ),
            fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
          ),
        ),
      );

      // Monthly KPI Header Formatting (Row 4)
      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: 3,
              endRowIndex: 4,
              startColumnIndex: 0,
              endColumnIndex: 7,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                backgroundColor: sheets.Color(
                  red: 0.93,
                  green: 0.95,
                  blue: 0.98,
                ),
                textFormat: sheets.TextFormat(
                  bold: true,
                  fontSize: 10,
                  foregroundColor: sheets.Color(
                    red: 0.18,
                    green: 0.24,
                    blue: 0.32,
                  ),
                ),
                horizontalAlignment: 'CENTER',
              ),
            ),
            fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
          ),
        ),
      );

      // All-Time KPI Header Formatting (Row 6)
      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: 5,
              endRowIndex: 6,
              startColumnIndex: 2,
              endColumnIndex: 7,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                backgroundColor: sheets.Color(
                  red: 0.95,
                  green: 0.96,
                  blue: 0.98,
                ),
                textFormat: sheets.TextFormat(
                  bold: true,
                  fontSize: 10,
                  foregroundColor: sheets.Color(
                    red: 0.25,
                    green: 0.30,
                    blue: 0.38,
                  ),
                ),
                horizontalAlignment: 'CENTER',
              ),
            ),
            fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
          ),
        ),
      );

      // Monthly KPI Values Formatting (Row 5)
      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: 4,
              endRowIndex: 5,
              startColumnIndex: 0,
              endColumnIndex: 7,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                textFormat: sheets.TextFormat(
                  bold: true,
                  fontSize: 12,
                ),
                numberFormat: sheets.NumberFormat(
                  type: 'NUMBER',
                  pattern: '#,##0.00',
                ),
                horizontalAlignment: 'CENTER',
              ),
            ),
            fields: 'userEnteredFormat(textFormat,numberFormat,horizontalAlignment)',
          ),
        ),
      );

      // All-Time KPI Values Formatting (Row 7)
      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: 6,
              endRowIndex: 7,
              startColumnIndex: 2,
              endColumnIndex: 7,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                textFormat: sheets.TextFormat(
                  bold: true,
                  fontSize: 11,
                ),
                numberFormat: sheets.NumberFormat(
                  type: 'NUMBER',
                  pattern: '#,##0.00',
                ),
                horizontalAlignment: 'CENTER',
              ),
            ),
            fields: 'userEnteredFormat(textFormat,numberFormat,horizontalAlignment)',
          ),
        ),
      );

      // Category Table Header Formatting (Row 9)
      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: 8,
              endRowIndex: 9,
              startColumnIndex: 0,
              endColumnIndex: 2,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                backgroundColor: sheets.Color(
                  red: 0.20,
                  green: 0.28,
                  blue: 0.38,
                ),
                textFormat: sheets.TextFormat(
                  bold: true,
                  fontSize: 11,
                  foregroundColor: sheets.Color(
                    red: 1.0,
                    green: 1.0,
                    blue: 1.0,
                  ),
                ),
              ),
            ),
            fields: 'userEnteredFormat(backgroundColor,textFormat)',
          ),
        ),
      );

      // Category Table Amounts Formatting (Rows 10..22)
      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: 9,
              endRowIndex: totalRowNum,
              startColumnIndex: 1,
              endColumnIndex: 2,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                numberFormat: sheets.NumberFormat(
                  type: 'NUMBER',
                  pattern: '#,##0.00',
                ),
                horizontalAlignment: 'RIGHT',
              ),
            ),
            fields: 'userEnteredFormat(numberFormat,horizontalAlignment)',
          ),
        ),
      );

      // Category Total Row Formatting
      formattingRequests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: dashboardSheetId,
              startRowIndex: totalRowNum - 1,
              endRowIndex: totalRowNum,
              startColumnIndex: 0,
              endColumnIndex: 2,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                backgroundColor: sheets.Color(
                  red: 0.94,
                  green: 0.95,
                  blue: 0.97,
                ),
                textFormat: sheets.TextFormat(
                  bold: true,
                  fontSize: 11,
                ),
              ),
            ),
            fields: 'userEnteredFormat(backgroundColor,textFormat)',
          ),
        ),
      );

      // Column widths
      formattingRequests.add(
        sheets.Request(
          updateDimensionProperties: sheets.UpdateDimensionPropertiesRequest(
            range: sheets.DimensionRange(
              sheetId: dashboardSheetId,
              dimension: 'COLUMNS',
              startIndex: 0,
              endIndex: 1,
            ),
            properties: sheets.DimensionProperties(pixelSize: 190),
            fields: 'pixelSize',
          ),
        ),
      );
      formattingRequests.add(
        sheets.Request(
          updateDimensionProperties: sheets.UpdateDimensionPropertiesRequest(
            range: sheets.DimensionRange(
              sheetId: dashboardSheetId,
              dimension: 'COLUMNS',
              startIndex: 1,
              endIndex: 2,
            ),
            properties: sheets.DimensionProperties(pixelSize: 140),
            fields: 'pixelSize',
          ),
        ),
      );
      formattingRequests.add(
        sheets.Request(
          updateDimensionProperties: sheets.UpdateDimensionPropertiesRequest(
            range: sheets.DimensionRange(
              sheetId: dashboardSheetId,
              dimension: 'COLUMNS',
              startIndex: 2,
              endIndex: 3,
            ),
            properties: sheets.DimensionProperties(pixelSize: 160),
            fields: 'pixelSize',
          ),
        ),
      );
      formattingRequests.add(
        sheets.Request(
          updateDimensionProperties: sheets.UpdateDimensionPropertiesRequest(
            range: sheets.DimensionRange(
              sheetId: dashboardSheetId,
              dimension: 'COLUMNS',
              startIndex: 4,
              endIndex: 5,
            ),
            properties: sheets.DimensionProperties(pixelSize: 160),
            fields: 'pixelSize',
          ),
        ),
      );
      formattingRequests.add(
        sheets.Request(
          updateDimensionProperties: sheets.UpdateDimensionPropertiesRequest(
            range: sheets.DimensionRange(
              sheetId: dashboardSheetId,
              dimension: 'COLUMNS',
              startIndex: 6,
              endIndex: 7,
            ),
            properties: sheets.DimensionProperties(pixelSize: 160),
            fields: 'pixelSize',
          ),
        ),
      );

      // Check if Pie Chart exists on the dashboard
      final currentSpreadsheet =
          await _sheetsApi!.spreadsheets.get(spreadsheetId);
      final dashboardSheet = currentSpreadsheet.sheets?.firstWhere(
        (s) => s.properties?.sheetId == dashboardSheetId,
        orElse: () => sheets.Sheet(),
      );

      final hasPieChart = dashboardSheet?.charts?.any(
            (c) =>
                c.spec?.pieChart != null || c.chartId == defaultPieChartId,
          ) ??
          false;

      if (!hasPieChart) {
        final pieChart = sheets.EmbeddedChart(
          chartId: defaultPieChartId,
          spec: sheets.ChartSpec(
            title: 'Monthly Expense by Category',
            pieChart: sheets.PieChartSpec(
              legendPosition: 'RIGHT_LEGEND',
              pieHole: 0.35,
              threeDimensional: false,
              domain: sheets.ChartData(
                sourceRange: sheets.ChartSourceRange(
                  sources: [
                    sheets.GridRange(
                      sheetId: dashboardSheetId,
                      startRowIndex: 9,
                      endRowIndex: 9 + categories.length,
                      startColumnIndex: 0,
                      endColumnIndex: 1,
                    ),
                  ],
                ),
              ),
              series: sheets.ChartData(
                sourceRange: sheets.ChartSourceRange(
                  sources: [
                    sheets.GridRange(
                      sheetId: dashboardSheetId,
                      startRowIndex: 9,
                      endRowIndex: 9 + categories.length,
                      startColumnIndex: 1,
                      endColumnIndex: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          position: sheets.EmbeddedObjectPosition(
            overlayPosition: sheets.OverlayPosition(
              anchorCell: sheets.GridCoordinate(
                sheetId: dashboardSheetId,
                rowIndex: 8,
                columnIndex: 3,
              ),
              widthPixels: 520,
              heightPixels: 350,
            ),
          ),
        );

        formattingRequests.add(
          sheets.Request(
            addChart: sheets.AddChartRequest(
              chart: pieChart,
            ),
          ),
        );
      }

      if (formattingRequests.isNotEmpty) {
        await _sheetsApi!.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(requests: formattingRequests),
          spreadsheetId,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error updating dashboard sheet: $e',
        name: 'GoogleSheetsService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 3. Writing Data - Single Transaction
  /// Appends a single transaction row to the `Transactions` sheet and refreshes the Dashboard.
  Future<bool> addTransaction({
    required String date,
    required String category,
    required double amount,
    String type = 'expense',
    String merchant = '',
    String notes = '',
    String id = '',
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
  }) async {
    try {
      final sheetId = await initSheet(
        currentBalance: currentBalance,
        cycleStartDate: cycleStartDate,
        cycleEndDate: cycleEndDate,
      );
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
        '$transactionsSheetTitle!A1',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );

      developer.log(
        'Appended single transaction to $transactionsSheetTitle sheet successfully.',
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
  /// Appends missing transactions to `Transactions` sheet and refreshes the `Dashboard`
  /// (Current Balance, Cycle-scoped Income/Expense formulas, and Pie Chart).
  Future<GoogleSheetsSyncSummary> syncTransactions(
    List<TransactionEntity> transactions, {
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
  }) async {
    final now = DateTime.now();

    try {
      final sheetId = await initSheet(
        currentBalance: currentBalance,
        cycleStartDate: cycleStartDate,
        cycleEndDate: cycleEndDate,
      );
      if (sheetId == null || _sheetsApi == null) {
        return GoogleSheetsSyncSummary(
          totalLocalTransactions: transactions.length,
          newRowsAppended: 0,
          spreadsheetId: '',
          syncTimestamp: now,
          errorMessage: 'Failed to access or create Google Sheet.',
        );
      }

      // Fetch existing transaction IDs from column G of Transactions sheet
      final Set<String> existingIds = {};
      try {
        final existingValues = await _sheetsApi!.spreadsheets.values.get(
          sheetId,
          '$transactionsSheetTitle!A:G',
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
          'Note: Could not query existing sheet rows: $e',
          name: 'GoogleSheetsService',
        );
      }

      // Filter out already synced transactions
      final toAppend =
          transactions.where((t) => !existingIds.contains(t.id)).toList();

      if (toAppend.isNotEmpty) {
        // Format rows chronologically ascending
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
          '$transactionsSheetTitle!A1',
          valueInputOption: 'USER_ENTERED',
          insertDataOption: 'INSERT_ROWS',
        );

        developer.log(
          'Appended ${rows.length} new transactions to $transactionsSheetTitle sheet in Google Sheet $sheetId.',
          name: 'GoogleSheetsService',
        );
      } else {
        developer.log(
          'All ${transactions.length} transactions are already present in Google Sheet.',
          name: 'GoogleSheetsService',
        );
      }

      // Refresh Dashboard with updated balance, active cycle dates, & timestamp
      await _ensureSheetsAndStructure(
        sheetId,
        currentBalance: currentBalance,
        cycleStartDate: cycleStartDate,
        cycleEndDate: cycleEndDate,
      );

      return GoogleSheetsSyncSummary(
        totalLocalTransactions: transactions.length,
        newRowsAppended: toAppend.length,
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

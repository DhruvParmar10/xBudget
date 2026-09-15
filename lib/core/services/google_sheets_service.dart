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

/// Represents a Year and Month grouping key for monthwise sheet tabs (e.g. "September 2026").
class MonthKey implements Comparable<MonthKey> {
  final int year;
  final int month;

  const MonthKey(this.year, this.month);

  String get title => GoogleSheetsService.getMonthSheetTitle(year, month);

  @override
  int compareTo(MonthKey other) {
    if (year != other.year) return other.year.compareTo(year); // descending
    return other.month.compareTo(month); // descending
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthKey &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;

  @override
  String toString() => title;
}

/// Service to handle Google OAuth authentication, Drive spreadsheet discovery/creation,
/// and syncing transaction records along with an interactive visual Dashboard and Pie Chart.
class GoogleSheetsService {
  static const String defaultSpreadsheetTitle = 'BudgetApp_Data';
  static const String dashboardSheetTitle = 'Dashboard';
  static const String transactionsSheetTitle = 'Transactions';
  static const int defaultPieChartId = 1001;

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Formats year and month into human-readable sheet title (e.g. "September 2026").
  static String getMonthSheetTitle(int year, int month) {
    if (month < 1 || month > 12) return '$year-$month';
    return '${monthNames[month - 1]} $year';
  }

  /// Returns the effective MonthKey for a date, mapping any transaction
  /// occurring on the final day of a month into the following month's cycle
  /// (e.g., Aug 31 -> September 2026, Sept 30 -> October 2026).
  static MonthKey getEffectiveMonthKey(DateTime date) {
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    if (date.day == lastDay) {
      final nextMonth = DateTime(date.year, date.month + 1, 1);
      return MonthKey(nextMonth.year, nextMonth.month);
    }
    return MonthKey(date.year, date.month);
  }

  /// Returns the cycle date range for [monthKey] under the last-day shift rule
  /// (starts on the last day of previous month, ends on the day before last day of this month).
  static ({DateTime start, DateTime end}) getCycleDateRangeForMonth(MonthKey monthKey) {
    final start = DateTime(monthKey.year, monthKey.month, 0);
    final lastDayThisMonth = DateTime(monthKey.year, monthKey.month + 1, 0).day;
    final end = DateTime(monthKey.year, monthKey.month, lastDayThisMonth - 1);
    return (start: start, end: end);
  }

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
  /// If found, verifies its monthwise sheets structure.
  /// If not found, creates a new spreadsheet and initializes monthwise sheets.
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

      // 3. Set up monthwise sheets
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

  /// Ensures that monthwise sheets exist (e.g. "September 2026")
  /// and each sheet contains its visual Dashboard on top (Rows 1-23)
  /// and its Transactions table below (Rows 24+).
  Future<({int dashboardSheetId, int transactionsSheetId})?> _ensureSheetsAndStructure(
    String spreadsheetId, {
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
    List<TransactionEntity>? transactions,
  }) async {
    final ids = await _ensureMonthSheetsStructure(
      spreadsheetId,
      transactions: transactions ?? [],
      currentBalance: currentBalance,
      cycleStartDate: cycleStartDate,
      cycleEndDate: cycleEndDate,
    );
    final firstId = ids.isNotEmpty ? ids.values.first : 0;
    return (dashboardSheetId: firstId, transactionsSheetId: firstId);
  }

  /// Manages monthwise sheet creation, data population (Dashboard on top,
  /// Transactions below), chart embedding, and cleanup of legacy sheets.
  Future<Map<String, int>> _ensureMonthSheetsStructure(
    String spreadsheetId, {
    required List<TransactionEntity> transactions,
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
    DateTime? syncTime,
  }) async {
    final now = syncTime ?? DateTime.now();
    final Map<String, int> monthSheetIds = {};

    try {
      // 1. Partition transactions by effective MonthKey (last day of month -> next month)
      final Map<MonthKey, List<TransactionEntity>> grouped = {};
      for (final t in transactions) {
        final key = getEffectiveMonthKey(t.date);
        grouped.putIfAbsent(key, () => []).add(t);
      }

      // Always guarantee that the current active month tab is present
      final currentMonthKey = getEffectiveMonthKey(now);
      grouped.putIfAbsent(currentMonthKey, () => []);

      // Sort month keys descending (newest month first)
      final sortedMonthKeys = grouped.keys.toList()..sort();

      // 2. Inspect existing sheets in the spreadsheet
      final spreadsheet = await _sheetsApi!.spreadsheets.get(spreadsheetId);
      final existingSheets = spreadsheet.sheets ?? [];

      int maxSheetId = 0;
      final existingTitlesMap = <String, int>{};
      int? legacyDashboardId;
      int? legacyTransactionsId;
      int? sheet1Id;

      for (final s in existingSheets) {
        final title = s.properties?.title;
        final id = s.properties?.sheetId;
        if (id != null) {
          maxSheetId = math.max(maxSheetId, id);
          if (title != null) {
            existingTitlesMap[title] = id;
            if (title == dashboardSheetTitle) {
              legacyDashboardId = id;
            } else if (title == transactionsSheetTitle) {
              legacyTransactionsId = id;
            } else if (title == 'Sheet1') {
              sheet1Id = id;
            }
          }
        }
      }

      // 3. Add or rename sheets for each month
      final List<sheets.Request> sheetCreationRequests = [];
      bool sheet1Used = false;

      for (int i = 0; i < sortedMonthKeys.length; i++) {
        final monthKey = sortedMonthKeys[i];
        final title = monthKey.title;

        if (existingTitlesMap.containsKey(title)) {
          monthSheetIds[title] = existingTitlesMap[title]!;
        } else if (sheet1Id != null && !sheet1Used) {
          // Rename default 'Sheet1' to the first month title
          sheet1Used = true;
          monthSheetIds[title] = sheet1Id;
          sheetCreationRequests.add(
            sheets.Request(
              updateSheetProperties: sheets.UpdateSheetPropertiesRequest(
                properties: sheets.SheetProperties(
                  sheetId: sheet1Id,
                  title: title,
                  index: i,
                ),
                fields: 'title,index',
              ),
            ),
          );
        } else {
          maxSheetId++;
          final newId = maxSheetId;
          monthSheetIds[title] = newId;
          sheetCreationRequests.add(
            sheets.Request(
              addSheet: sheets.AddSheetRequest(
                properties: sheets.SheetProperties(
                  sheetId: newId,
                  title: title,
                  index: i,
                ),
              ),
            ),
          );
        }
      }

      if (sheetCreationRequests.isNotEmpty) {
        await _sheetsApi!.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(requests: sheetCreationRequests),
          spreadsheetId,
        );
      }

      // 4. Populate each month's sheet content & styling (Dashboard on top, Transactions below)
      for (int i = 0; i < sortedMonthKeys.length; i++) {
        final monthKey = sortedMonthKeys[i];
        final title = monthKey.title;
        final sheetId = monthSheetIds[title]!;
        final monthTxns = grouped[monthKey] ?? [];

        await _populateAndFormatMonthSheet(
          spreadsheetId: spreadsheetId,
          sheetId: sheetId,
          monthKey: monthKey,
          transactions: monthTxns,
          currentBalance: currentBalance,
          cycleStartDate: cycleStartDate,
          cycleEndDate: cycleEndDate,
          syncTime: now,
          sheetIndex: i,
        );
      }

      // 5. Clean up legacy 'Dashboard' and 'Transactions' sheets if present
      final List<sheets.Request> cleanupRequests = [];
      if (legacyDashboardId != null) {
        cleanupRequests.add(
          sheets.Request(
            deleteSheet: sheets.DeleteSheetRequest(sheetId: legacyDashboardId),
          ),
        );
      }
      if (legacyTransactionsId != null) {
        cleanupRequests.add(
          sheets.Request(
            deleteSheet: sheets.DeleteSheetRequest(sheetId: legacyTransactionsId),
          ),
        );
      }

      if (cleanupRequests.isNotEmpty) {
        try {
          await _sheetsApi!.spreadsheets.batchUpdate(
            sheets.BatchUpdateSpreadsheetRequest(requests: cleanupRequests),
            spreadsheetId,
          );
        } catch (e) {
          developer.log(
            'Notice: Legacy sheet cleanup skipped: $e',
            name: 'GoogleSheetsService',
          );
        }
      }

      return monthSheetIds;
    } catch (e, stackTrace) {
      developer.log(
        'Error ensuring month sheets and structure: $e',
        name: 'GoogleSheetsService',
        error: e,
        stackTrace: stackTrace,
      );
      return monthSheetIds;
    }
  }

  /// Builds and updates a single month's sheet:
  /// - Top part (Rows 1-23): Month Dashboard & Embedded Pie Chart
  /// - Bottom part (Rows 24+): Month Transactions table
  Future<void> _populateAndFormatMonthSheet({
    required String spreadsheetId,
    required int sheetId,
    required MonthKey monthKey,
    required List<TransactionEntity> transactions,
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
    required DateTime syncTime,
    required int sheetIndex,
  }) async {
    final title = monthKey.title;
    final currentEffectiveMonthKey = getEffectiveMonthKey(syncTime);
    final isCurrentMonth = (currentEffectiveMonthKey == monthKey);

    // Salary-aligned cycle: starts on the last day of previous month, ends on the day before the last day of this month
    final defaultCycleRange = getCycleDateRangeForMonth(monthKey);
    final periodStart =
        (isCurrentMonth && cycleStartDate != null) ? cycleStartDate : defaultCycleRange.start;
    final periodEnd =
        (isCurrentMonth && cycleEndDate != null) ? cycleEndDate : defaultCycleRange.end;

    final periodStartStr =
        '${periodStart.year}-${periodStart.month.toString().padLeft(2, '0')}-${periodStart.day.toString().padLeft(2, '0')}';
    final periodEndStr =
        '${periodEnd.year}-${periodEnd.month.toString().padLeft(2, '0')}-${periodEnd.day.toString().padLeft(2, '0')}';
    final timestampStr =
        '${syncTime.year}-${syncTime.month.toString().padLeft(2, '0')}-${syncTime.day.toString().padLeft(2, '0')} ${syncTime.hour.toString().padLeft(2, '0')}:${syncTime.minute.toString().padLeft(2, '0')}';

    final categories = BudgetCategory.values;
    final List<List<Object>> rows = [
      // Row 1: Banner Title
      ['xBudget Financial Dashboard - $title', '', '', '', '', '', ''],
      // Row 2: Subtitle / Timestamp
      ['Last Synced: $timestampStr', '', '', '', '', '', ''],
      // Row 3: Month Period
      ['Month Period:', periodStartStr, 'to', periodEndStr, '', '', ''],
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
      // Row 5: Monthly KPI Values
      [
        isCurrentMonth ? (currentBalance ?? 0.0) : 0.0,
        '',
        '=SUMIF(D27:D, "income", C27:C)',
        '',
        '=SUMIF(D27:D, "expense", C27:C)',
        '',
        '=C5-E5',
      ],
      // Row 6: Activity KPI Headers
      ['', '', 'Total Transactions', '', 'Expense Count', '', 'Income Count'],
      // Row 7: Activity KPI Values
      [
        '',
        '',
        '=COUNTA(G27:G)',
        '',
        '=COUNTIF(D27:D, "expense")',
        '',
        '=COUNTIF(D27:D, "income")',
      ],
      // Row 8: Spacer
      ['', '', '', '', '', '', ''],
      // Row 9: Category Breakdown Header
      ['Monthly Expense Category', 'Spend Amount', '', '', '', '', ''],
    ];

    // Rows 10..21: Categories breakdown with SUMIFS formulas scoped to transactions below
    for (int i = 0; i < categories.length; i++) {
      final rowNum = 10 + i;
      final cat = categories[i];
      rows.add([
        cat.displayName,
        '=SUMIFS(C\$27:C, B\$27:B, A$rowNum, D\$27:D, "expense")',
        '',
        '',
        '',
        '',
        '',
      ]);
    }

    // Row 22: Total Monthly Expenses
    final totalRowNum = 10 + categories.length;
    rows.add([
      'Total Monthly Expenses',
      '=SUM(B10:B${totalRowNum - 1})',
      '',
      '',
      '',
      '',
      '',
    ]);

    // Row 23: Spacer
    rows.add(['', '', '', '', '', '', '']);
    // Row 24: Spacer
    rows.add(['', '', '', '', '', '', '']);
    // Row 25: Transactions Section Title
    rows.add(['$title Transactions', '', '', '', '', '', '']);
    // Row 26: Transactions Table Column Headers
    rows.add([
      'Date',
      'Category',
      'Amount',
      'Type',
      'Merchant',
      'Notes',
      'Transaction ID',
    ]);

    // Rows 27+: Sorted transactions for this month
    final sortedTxns = List<TransactionEntity>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final t in sortedTxns) {
      final dateStr =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      rows.add([
        dateStr,
        t.category.displayName,
        t.amount,
        t.transactionType,
        t.merchant,
        t.note ?? '',
        t.id,
      ]);
    }

    // 1. Clear previous content to avoid ghost rows
    try {
      await _sheetsApi!.spreadsheets.values.clear(
        sheets.ClearValuesRequest(),
        spreadsheetId,
        '$title!A1:Z',
      );
    } catch (_) {}

    // 2. Write values to the sheet
    await _sheetsApi!.spreadsheets.values.update(
      sheets.ValueRange(values: rows),
      spreadsheetId,
      '$title!A1',
      valueInputOption: 'USER_ENTERED',
    );

    // 3. Formatting & Pie Chart batch update
    final List<sheets.Request> requests = [];

    // Tab index ordering
    requests.add(
      sheets.Request(
        updateSheetProperties: sheets.UpdateSheetPropertiesRequest(
          properties: sheets.SheetProperties(
            sheetId: sheetId,
            index: sheetIndex,
          ),
          fields: 'index',
        ),
      ),
    );

    // Title Banner (Row 1)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 0,
            endRowIndex: 1,
            startColumnIndex: 0,
            endColumnIndex: 7,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              backgroundColor: sheets.Color(red: 0.12, green: 0.16, blue: 0.23),
              textFormat: sheets.TextFormat(
                bold: true,
                fontSize: 14,
                foregroundColor: sheets.Color(red: 1.0, green: 1.0, blue: 1.0),
              ),
              horizontalAlignment: 'LEFT',
            ),
          ),
          fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
        ),
      ),
    );

    // Subtitle (Row 2)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
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
                foregroundColor: sheets.Color(red: 0.45, green: 0.45, blue: 0.45),
              ),
            ),
          ),
          fields: 'userEnteredFormat(textFormat)',
        ),
      ),
    );

    // Period Range (Row 3)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
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
                foregroundColor: sheets.Color(red: 0.35, green: 0.40, blue: 0.48),
              ),
            ),
          ),
          fields: 'userEnteredFormat(textFormat)',
        ),
      ),
    );
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 2,
            endRowIndex: 3,
            startColumnIndex: 1,
            endColumnIndex: 4,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              backgroundColor: sheets.Color(red: 0.94, green: 0.96, blue: 0.99),
              textFormat: sheets.TextFormat(
                bold: true,
                fontSize: 9,
                foregroundColor: sheets.Color(red: 0.15, green: 0.35, blue: 0.65),
              ),
              horizontalAlignment: 'CENTER',
            ),
          ),
          fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
        ),
      ),
    );

    // Monthly KPI Headers (Row 4)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 3,
            endRowIndex: 4,
            startColumnIndex: 0,
            endColumnIndex: 7,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              backgroundColor: sheets.Color(red: 0.93, green: 0.95, blue: 0.98),
              textFormat: sheets.TextFormat(
                bold: true,
                fontSize: 10,
                foregroundColor: sheets.Color(red: 0.18, green: 0.24, blue: 0.32),
              ),
              horizontalAlignment: 'CENTER',
            ),
          ),
          fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
        ),
      ),
    );

    // Monthly KPI Values (Row 5)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
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

    // Activity KPI Headers (Row 6)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 5,
            endRowIndex: 6,
            startColumnIndex: 2,
            endColumnIndex: 7,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              backgroundColor: sheets.Color(red: 0.95, green: 0.96, blue: 0.98),
              textFormat: sheets.TextFormat(
                bold: true,
                fontSize: 10,
                foregroundColor: sheets.Color(red: 0.25, green: 0.30, blue: 0.38),
              ),
              horizontalAlignment: 'CENTER',
            ),
          ),
          fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
        ),
      ),
    );

    // Activity KPI Values (Row 7)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
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
                pattern: '#,##0',
              ),
              horizontalAlignment: 'CENTER',
            ),
          ),
          fields: 'userEnteredFormat(textFormat,numberFormat,horizontalAlignment)',
        ),
      ),
    );

    // Category Breakdown Header (Row 9)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 8,
            endRowIndex: 9,
            startColumnIndex: 0,
            endColumnIndex: 2,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              backgroundColor: sheets.Color(red: 0.20, green: 0.28, blue: 0.38),
              textFormat: sheets.TextFormat(
                bold: true,
                fontSize: 11,
                foregroundColor: sheets.Color(red: 1.0, green: 1.0, blue: 1.0),
              ),
            ),
          ),
          fields: 'userEnteredFormat(backgroundColor,textFormat)',
        ),
      ),
    );

    // Category Amounts Formatting (Rows 10..21, Col B)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 9,
            endRowIndex: totalRowNum - 1,
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

    // Category Total Row (Row 22)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: totalRowNum - 1,
            endRowIndex: totalRowNum,
            startColumnIndex: 0,
            endColumnIndex: 2,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              backgroundColor: sheets.Color(red: 0.94, green: 0.95, blue: 0.97),
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

    // Transactions Section Banner (Row 25)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 24,
            endRowIndex: 25,
            startColumnIndex: 0,
            endColumnIndex: 7,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              backgroundColor: sheets.Color(red: 0.94, green: 0.96, blue: 0.99),
              textFormat: sheets.TextFormat(
                bold: true,
                fontSize: 11,
                foregroundColor: sheets.Color(red: 0.12, green: 0.16, blue: 0.23),
              ),
              horizontalAlignment: 'LEFT',
            ),
          ),
          fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
        ),
      ),
    );

    // Transactions Table Column Headers (Row 26)
    requests.add(
      sheets.Request(
        repeatCell: sheets.RepeatCellRequest(
          range: sheets.GridRange(
            sheetId: sheetId,
            startRowIndex: 25,
            endRowIndex: 26,
            startColumnIndex: 0,
            endColumnIndex: 7,
          ),
          cell: sheets.CellData(
            userEnteredFormat: sheets.CellFormat(
              backgroundColor: sheets.Color(red: 0.90, green: 0.92, blue: 0.95),
              textFormat: sheets.TextFormat(
                bold: true,
                fontSize: 10,
                foregroundColor: sheets.Color(red: 0.12, green: 0.16, blue: 0.23),
              ),
              horizontalAlignment: 'CENTER',
            ),
          ),
          fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
        ),
      ),
    );

    // Format Transactions Data Rows (Rows 27+)
    if (sortedTxns.isNotEmpty) {
      final txEndRow = 26 + sortedTxns.length;

      // Col A: Date (centered)
      requests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: sheetId,
              startRowIndex: 26,
              endRowIndex: txEndRow,
              startColumnIndex: 0,
              endColumnIndex: 1,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                horizontalAlignment: 'CENTER',
              ),
            ),
            fields: 'userEnteredFormat(horizontalAlignment)',
          ),
        ),
      );

      // Col C: Amount (number format #,##0.00, right-aligned)
      requests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: sheetId,
              startRowIndex: 26,
              endRowIndex: txEndRow,
              startColumnIndex: 2,
              endColumnIndex: 3,
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

      // Col D: Type (centered)
      requests.add(
        sheets.Request(
          repeatCell: sheets.RepeatCellRequest(
            range: sheets.GridRange(
              sheetId: sheetId,
              startRowIndex: 26,
              endRowIndex: txEndRow,
              startColumnIndex: 3,
              endColumnIndex: 4,
            ),
            cell: sheets.CellData(
              userEnteredFormat: sheets.CellFormat(
                horizontalAlignment: 'CENTER',
              ),
            ),
            fields: 'userEnteredFormat(horizontalAlignment)',
          ),
        ),
      );
    }

    // Column widths
    final columnWidths = [190, 140, 160, 100, 160, 180, 180];
    for (int col = 0; col < columnWidths.length; col++) {
      requests.add(
        sheets.Request(
          updateDimensionProperties: sheets.UpdateDimensionPropertiesRequest(
            range: sheets.DimensionRange(
              sheetId: sheetId,
              dimension: 'COLUMNS',
              startIndex: col,
              endIndex: col + 1,
            ),
            properties: sheets.DimensionProperties(pixelSize: columnWidths[col]),
            fields: 'pixelSize',
          ),
        ),
      );
    }

    // 4. Check / Insert Embedded Pie Chart
    final currentSpreadsheet = await _sheetsApi!.spreadsheets.get(spreadsheetId);
    final currentSheet = currentSpreadsheet.sheets?.firstWhere(
      (s) => s.properties?.sheetId == sheetId,
      orElse: () => sheets.Sheet(),
    );

    final chartId = 1000 + sheetId;
    final hasPieChart = currentSheet?.charts?.any(
          (c) => c.chartId == chartId || c.spec?.pieChart != null,
        ) ??
        false;

    if (!hasPieChart) {
      final pieChart = sheets.EmbeddedChart(
        chartId: chartId,
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
                    sheetId: sheetId,
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
                    sheetId: sheetId,
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
              sheetId: sheetId,
              rowIndex: 8,
              columnIndex: 3,
            ),
            widthPixels: 520,
            heightPixels: 350,
          ),
        ),
      );

      requests.add(
        sheets.Request(
          addChart: sheets.AddChartRequest(
            chart: pieChart,
          ),
        ),
      );
    }

    if (requests.isNotEmpty) {
      await _sheetsApi!.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(requests: requests),
        spreadsheetId,
      );
    }
  }

  /// Appends a single transaction to its respective month sheet.
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
      final txnDate = DateTime.tryParse(date) ?? DateTime.now();
      final monthKey = getEffectiveMonthKey(txnDate);
      final monthSheetTitle = monthKey.title;

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
        '$monthSheetTitle!A26',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );

      developer.log(
        'Appended single transaction to $monthSheetTitle sheet successfully.',
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

  /// Synchronizes transactions to Google Sheets organized monthwise.
  /// Each month gets its own sheet tab with visual Dashboard on top and Transactions below.
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

      await _ensureMonthSheetsStructure(
        sheetId,
        transactions: transactions,
        currentBalance: currentBalance,
        cycleStartDate: cycleStartDate,
        cycleEndDate: cycleEndDate,
        syncTime: now,
      );

      return GoogleSheetsSyncSummary(
        totalLocalTransactions: transactions.length,
        newRowsAppended: transactions.length,
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

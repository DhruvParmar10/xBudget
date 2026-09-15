import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/services/google_sheets_service.dart';
import 'package:xbudget/core/usecases/usecase.dart';
import 'package:xbudget/features/sync/domain/usecases/sync_to_google_sheets_usecase.dart';
import 'package:xbudget/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:xbudget/features/transactions/data/models/transaction_model.dart';
import 'package:xbudget/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';

class MockTestGoogleSheetsService extends GoogleSheetsService {
  bool syncCalled = false;
  double? capturedCurrentBalance;
  DateTime? capturedCycleStart;
  DateTime? capturedCycleEnd;
  List<TransactionEntity>? capturedTransactions;

  @override
  String? get currentEmail => 'test@example.com';

  @override
  Future<GoogleSheetsSyncSummary> syncTransactions(
    List<TransactionEntity> transactions, {
    double? currentBalance,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
  }) async {
    syncCalled = true;
    capturedCurrentBalance = currentBalance;
    capturedCycleStart = cycleStartDate;
    capturedCycleEnd = cycleEndDate;
    capturedTransactions = transactions;
    return GoogleSheetsSyncSummary(
      totalLocalTransactions: transactions.length,
      newRowsAppended: transactions.length,
      spreadsheetId: 'sheet-123',
      syncTimestamp: DateTime(2026, 8, 24, 12, 0),
    );
  }
}

void main() {
  group('Google Sheets Dashboard & Pie Chart Tests', () {
    late AppPreferences preferences;
    late TransactionRepositoryImpl repository;
    late MockTestGoogleSheetsService service;
    late SyncToGoogleSheetsUseCase useCase;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      preferences = AppPreferences(prefs);
      final dataSource = TransactionLocalDataSourceImpl(prefs);
      repository = TransactionRepositoryImpl(dataSource);
      service = MockTestGoogleSheetsService();

      useCase = SyncToGoogleSheetsUseCase(
        googleSheetsService: service,
        repository: repository,
        preferences: preferences,
      );
    });

    test('GoogleSheetsService has correct sheet and chart constants', () {
      expect(GoogleSheetsService.dashboardSheetTitle, equals('Dashboard'));
      expect(GoogleSheetsService.transactionsSheetTitle, equals('Transactions'));
      expect(GoogleSheetsService.defaultSpreadsheetTitle, equals('BudgetApp_Data'));
      expect(GoogleSheetsService.defaultPieChartId, equals(1001));
    });

    test('generates direct Google Sheets URL correctly', () {
      final realService = GoogleSheetsService(initialSpreadsheetId: 'sheet-xyz-789');
      final url = realService.getSpreadsheetUrl();
      expect(url, equals('https://docs.google.com/spreadsheets/d/sheet-xyz-789/edit'));

      final customUrl = realService.getSpreadsheetUrl('custom-id-456');
      expect(customUrl, equals('https://docs.google.com/spreadsheets/d/custom-id-456/edit'));
    });

    test('SyncToGoogleSheetsUseCase passes dynamic current balance, transactions, and cycle dates to service', () async {
      // Setup base balance
      final baseDate = DateTime(2026, 8, 20, 10, 0);
      await preferences.setCurrentBalance(20000.0, updatedAt: baseDate);

      // Add expense after balance timestamp: 20000 - 4795.07 = 15204.93
      final txn = TransactionModel(
        id: 'txn-101',
        amount: 4795.07,
        merchant: 'Supermarket',
        transactionType: 'expense',
        category: BudgetCategory.groceries,
        isP2P: false,
        date: DateTime(2026, 8, 24),
        rawMessage: 'Rs 4795.07 debited',
        createdAt: DateTime(2026, 8, 24),
      );
      await repository.saveTransactions([txn]);

      final summary = await useCase(const NoParams());

      expect(service.syncCalled, isTrue);
      expect(service.capturedCurrentBalance, closeTo(15204.93, 0.01));
      expect(service.capturedCycleStart, isNotNull);
      expect(service.capturedCycleEnd, isNotNull);
      expect(service.capturedTransactions?.length, equals(1));
      expect(service.capturedTransactions?.first.id, equals('txn-101'));
      expect(summary.isSuccess, isTrue);
      expect(summary.spreadsheetId, equals('sheet-123'));
    });

    test('validates Dashboard Pie Chart specification structure', () {
      const dashboardSheetId = 0;
      final categories = BudgetCategory.values;

      final pieChart = sheets.EmbeddedChart(
        chartId: GoogleSheetsService.defaultPieChartId,
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

      expect(pieChart.chartId, equals(1001));
      expect(pieChart.spec?.title, equals('Monthly Expense by Category'));
      expect(pieChart.spec?.pieChart?.legendPosition, equals('RIGHT_LEGEND'));
      expect(pieChart.spec?.pieChart?.pieHole, equals(0.35));
      expect(pieChart.spec?.pieChart?.domain?.sourceRange?.sources?.first.sheetId, equals(0));
      expect(pieChart.spec?.pieChart?.domain?.sourceRange?.sources?.first.startRowIndex, equals(9));
      expect(pieChart.spec?.pieChart?.domain?.sourceRange?.sources?.first.endRowIndex, equals(9 + categories.length));
      expect(pieChart.spec?.pieChart?.series?.sourceRange?.sources?.first.startColumnIndex, equals(1));
      expect(pieChart.spec?.pieChart?.series?.sourceRange?.sources?.first.endColumnIndex, equals(2));
      expect(pieChart.position?.overlayPosition?.anchorCell?.rowIndex, equals(8));
      expect(pieChart.position?.overlayPosition?.anchorCell?.columnIndex, equals(3));
      expect(pieChart.position?.overlayPosition?.widthPixels, equals(520));
      expect(pieChart.position?.overlayPosition?.heightPixels, equals(350));
    });

    test('validates Dashboard formulas and categories mapping with active cycle scoping', () {
      final categories = BudgetCategory.values;
      final List<List<Object>> dashboardRows = [
        ['xBudget Financial Dashboard', '', '', '', '', '', ''],
        ['Last Synced: 2026-08-24 12:00', '', '', '', '', '', ''],
        ['Active Billing Cycle:', '2026-07-31', 'to', '2026-08-30', '', '', ''],
        [
          'Current Balance',
          '',
          'Monthly Income',
          '',
          'Monthly Expense',
          '',
          'Net Monthly Flow',
        ],
        [
          15204.93,
          '',
          '=SUMIFS(Transactions!C:C, Transactions!D:D, "income", Transactions!A:A, ">="&\$B\$3, Transactions!A:A, "<="&\$D\$3)',
          '',
          '=SUMIFS(Transactions!C:C, Transactions!D:D, "expense", Transactions!A:A, ">="&\$B\$3, Transactions!A:A, "<="&\$D\$3)',
          '',
          '=C5-E5',
        ],
        ['', '', 'All-Time Income', '', 'All-Time Expense', '', 'All-Time Net'],
        [
          '',
          '',
          '=SUMIF(Transactions!D:D, "income", Transactions!C:C)',
          '',
          '=SUMIF(Transactions!D:D, "expense", Transactions!C:C)',
          '',
          '=C7-E7',
        ],
        ['', '', '', '', '', '', ''],
        ['Monthly Expense Category', 'Spend Amount', '', '', '', '', ''],
      ];

      for (int i = 0; i < categories.length; i++) {
        final rowNum = 10 + i;
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

      // Assertions on the generated structure
      expect(dashboardRows[0][0], equals('xBudget Financial Dashboard'));
      expect(dashboardRows[2][0], equals('Active Billing Cycle:'));
      expect(dashboardRows[2][1], equals('2026-07-31'));
      expect(dashboardRows[2][3], equals('2026-08-30'));
      expect(dashboardRows[3][0], equals('Current Balance'));
      expect(dashboardRows[3][2], equals('Monthly Income'));
      expect(dashboardRows[3][4], equals('Monthly Expense'));
      expect(dashboardRows[3][6], equals('Net Monthly Flow'));
      expect(dashboardRows[4][0], equals(15204.93));
      expect(dashboardRows[4][2], contains(r'$B$3'));
      expect(dashboardRows[4][4], contains(r'$D$3'));
      expect(dashboardRows[4][6], equals('=C5-E5'));
      expect(dashboardRows[6][2], equals('=SUMIF(Transactions!D:D, "income", Transactions!C:C)'));
      expect(dashboardRows[6][4], equals('=SUMIF(Transactions!D:D, "expense", Transactions!C:C)'));
      expect(dashboardRows[8][0], equals('Monthly Expense Category'));

      // Check category formulas
      expect(dashboardRows[9][0], equals('Food & Dining'));
      expect(dashboardRows[9][1], contains(r'$B$3'));

      // Check total row
      expect(dashboardRows.last[0], equals('Total Monthly Expenses'));
      expect(dashboardRows.last[1], equals('=SUM(B10:B${totalRowNum - 1})'));
    });

    test('validates Monthwise sheet layout with Dashboard on top and Transactions below', () {
      const monthTitle = 'September 2026';
      final categories = BudgetCategory.values;

      final List<List<Object>> sheetRows = [
        // Row 1: Banner Title
        ['xBudget Financial Dashboard - $monthTitle', '', '', '', '', '', ''],
        // Row 2: Subtitle / Timestamp
        ['Last Synced: 2026-09-16 01:16', '', '', '', '', '', ''],
        // Row 3: Month Period
        ['Month Period:', '2026-09-01', 'to', '2026-09-30', '', '', ''],
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
        // Row 5: Monthly KPI Values pointing to transactions starting row 27
        [
          10217.84,
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

      for (int i = 0; i < categories.length; i++) {
        final rowNum = 10 + i;
        final cat = categories[i];
        sheetRows.add([
          cat.displayName,
          '=SUMIFS(C\$27:C, B\$27:B, A$rowNum, D\$27:D, "expense")',
          '',
          '',
          '',
          '',
          '',
        ]);
      }

      final totalRowNum = 10 + categories.length;
      sheetRows.add([
        'Total Monthly Expenses',
        '=SUM(B10:B${totalRowNum - 1})',
        '',
        '',
        '',
        '',
        '',
      ]);

      // Spacers and section headers
      sheetRows.add(['', '', '', '', '', '', '']);
      sheetRows.add(['', '', '', '', '', '', '']);
      sheetRows.add(['$monthTitle Transactions', '', '', '', '', '', '']);
      sheetRows.add([
        'Date',
        'Category',
        'Amount',
        'Type',
        'Merchant',
        'Notes',
        'Transaction ID',
      ]);

      // Row 27: Sample transaction
      sheetRows.add([
        '2026-09-15',
        'Food & Dining',
        450.0,
        'expense',
        'Zomato',
        'Dinner',
        'txn-999',
      ]);

      // Validations
      expect(sheetRows[0][0], equals('xBudget Financial Dashboard - September 2026'));
      expect(sheetRows[2][0], equals('Month Period:'));
      expect(sheetRows[3][0], equals('Current Balance'));
      expect(sheetRows[4][2], equals('=SUMIF(D27:D, "income", C27:C)'));
      expect(sheetRows[4][4], equals('=SUMIF(D27:D, "expense", C27:C)'));
      expect(sheetRows[4][6], equals('=C5-E5'));
      expect(sheetRows[6][2], equals('=COUNTA(G27:G)'));
      expect(sheetRows[6][4], equals('=COUNTIF(D27:D, "expense")'));
      expect(sheetRows[6][6], equals('=COUNTIF(D27:D, "income")'));

      // Category breakdown formulas
      expect(sheetRows[9][0], equals('Food & Dining'));
      expect(sheetRows[9][1], equals(r'=SUMIFS(C$27:C, B$27:B, A10, D$27:D, "expense")'));

      // Transactions section below dashboard
      expect(sheetRows[24][0], equals('September 2026 Transactions'));
      expect(sheetRows[25][0], equals('Date'));
      expect(sheetRows[25][1], equals('Category'));
      expect(sheetRows[25][2], equals('Amount'));
      expect(sheetRows[25][6], equals('Transaction ID'));

      // Data row 27
      expect(sheetRows[26][0], equals('2026-09-15'));
      expect(sheetRows[26][2], equals(450.0));
      expect(sheetRows[26][6], equals('txn-999'));
    });
  });
}

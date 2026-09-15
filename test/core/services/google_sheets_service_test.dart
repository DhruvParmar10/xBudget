import 'package:flutter_test/flutter_test.dart';
import 'package:xbudget/core/services/google_sheets_service.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';

void main() {
  group('GoogleSheetsService Tests', () {
    late GoogleSheetsService service;

    setUp(() {
      service = GoogleSheetsService();
    });

    test('should have correct default spreadsheet title and scopes', () {
      expect(GoogleSheetsService.defaultSpreadsheetTitle, equals('BudgetApp_Data'));
      expect(GoogleSheetsService.requiredScopes, contains('https://www.googleapis.com/auth/drive.file'));
      expect(GoogleSheetsService.requiredScopes, contains('https://www.googleapis.com/auth/spreadsheets'));
    });

    test('should manage spreadsheetId getter and setter correctly', () {
      expect(service.spreadsheetId, isNull);

      service.setSpreadsheetId('sheet-12345');
      expect(service.spreadsheetId, equals('sheet-12345'));

      final url = service.getSpreadsheetUrl();
      expect(url, equals('https://docs.google.com/spreadsheets/d/sheet-12345/edit'));

      service.setSpreadsheetId(null);
      expect(service.spreadsheetId, isNull);
      expect(service.getSpreadsheetUrl(), isNull);
    });

    test('should construct explicit spreadsheet URL when ID provided', () {
      final url = service.getSpreadsheetUrl('custom_sheet_id');
      expect(url, equals('https://docs.google.com/spreadsheets/d/custom_sheet_id/edit'));
    });

    test('GoogleSheetsSyncSummary returns isSuccess true when no error', () {
      final summary = GoogleSheetsSyncSummary(
        totalLocalTransactions: 10,
        newRowsAppended: 5,
        spreadsheetId: 'sheet-xyz',
        syncTimestamp: DateTime(2026, 8, 21),
      );

      expect(summary.isSuccess, isTrue);
      expect(summary.totalLocalTransactions, equals(10));
      expect(summary.newRowsAppended, equals(5));
      expect(summary.spreadsheetId, equals('sheet-xyz'));
    });

    test('GoogleSheetsSyncSummary returns isSuccess false when error message present', () {
      final summary = GoogleSheetsSyncSummary(
        totalLocalTransactions: 0,
        newRowsAppended: 0,
        spreadsheetId: '',
        syncTimestamp: DateTime(2026, 8, 21),
        errorMessage: 'Network timeout',
      );

      expect(summary.isSuccess, isFalse);
      expect(summary.errorMessage, equals('Network timeout'));
    });

    test('signOut clears internal spreadsheetId', () async {
      final serviceWithId = GoogleSheetsService(initialSpreadsheetId: 'initial_id');
      expect(serviceWithId.spreadsheetId, equals('initial_id'));

      await serviceWithId.signOut();
      expect(serviceWithId.spreadsheetId, isNull);
    });
  });

  group('TransactionEntity Google Sheet formatting', () {
    test('transaction entity has all necessary attributes for sheet row', () {
      final txn = TransactionEntity(
        id: 'txn-abc-123',
        amount: 350.0,
        merchant: 'Swiggy',
        transactionType: 'expense',
        category: BudgetCategory.food,
        isP2P: false,
        date: DateTime(2026, 8, 21, 14, 30),
        rawMessage: 'Rs 350 debited for Swiggy',
        note: 'Lunch order',
        createdAt: DateTime(2026, 8, 21, 14, 31),
      );

      final dateStr =
          '${txn.date.year}-${txn.date.month.toString().padLeft(2, '0')}-${txn.date.day.toString().padLeft(2, '0')}';
      final row = [
        dateStr,
        txn.category.displayName,
        txn.amount,
        txn.transactionType,
        txn.merchant,
        txn.note ?? '',
        txn.id,
      ];

      expect(row[0], equals('2026-08-21'));
      expect(row[1], equals('Food & Dining'));
      expect(row[2], equals(350.0));
      expect(row[3], equals('expense'));
      expect(row[4], equals('Swiggy'));
      expect(row[5], equals('Lunch order'));
      expect(row[6], equals('txn-abc-123'));
    });
  });

  group('MonthKey & Sheet Tab Tests', () {
    test('getMonthSheetTitle formats months correctly', () {
      expect(GoogleSheetsService.getMonthSheetTitle(2026, 9), equals('September 2026'));
      expect(GoogleSheetsService.getMonthSheetTitle(2026, 8), equals('August 2026'));
      expect(GoogleSheetsService.getMonthSheetTitle(2026, 1), equals('January 2026'));
      expect(GoogleSheetsService.getMonthSheetTitle(2026, 12), equals('December 2026'));
    });

    test('MonthKey sorts in descending order (newest month first)', () {
      final sept2026 = const MonthKey(2026, 9);
      final aug2026 = const MonthKey(2026, 8);
      final dec2025 = const MonthKey(2025, 12);
      final jan2026 = const MonthKey(2026, 1);

      final list = [dec2025, sept2026, jan2026, aug2026]..sort();

      expect(list, equals([sept2026, aug2026, jan2026, dec2025]));
      expect(sept2026.title, equals('September 2026'));
      expect(aug2026.title, equals('August 2026'));
    });

    test('MonthKey equality and hashCode', () {
      final key1 = const MonthKey(2026, 9);
      final key2 = const MonthKey(2026, 9);
      final key3 = const MonthKey(2026, 8);

      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));
      expect(key1, isNot(equals(key3)));
    });

    test('getEffectiveMonthKey maps final day of month to the next month', () {
      // August 31 (salary day) -> September 2026
      expect(
        GoogleSheetsService.getEffectiveMonthKey(DateTime(2026, 8, 31)),
        equals(const MonthKey(2026, 9)),
      );

      // August 30 -> August 2026
      expect(
        GoogleSheetsService.getEffectiveMonthKey(DateTime(2026, 8, 30)),
        equals(const MonthKey(2026, 8)),
      );

      // September 1 -> September 2026
      expect(
        GoogleSheetsService.getEffectiveMonthKey(DateTime(2026, 9, 1)),
        equals(const MonthKey(2026, 9)),
      );

      // September 30 -> October 2026
      expect(
        GoogleSheetsService.getEffectiveMonthKey(DateTime(2026, 9, 30)),
        equals(const MonthKey(2026, 10)),
      );

      // February 28 in non-leap year -> March 2026
      expect(
        GoogleSheetsService.getEffectiveMonthKey(DateTime(2026, 2, 28)),
        equals(const MonthKey(2026, 3)),
      );

      // February 27 -> February 2026
      expect(
        GoogleSheetsService.getEffectiveMonthKey(DateTime(2026, 2, 27)),
        equals(const MonthKey(2026, 2)),
      );

      // February 29 in leap year -> March 2024
      expect(
        GoogleSheetsService.getEffectiveMonthKey(DateTime(2024, 2, 29)),
        equals(const MonthKey(2024, 3)),
      );

      // December 31 -> January of following year
      expect(
        GoogleSheetsService.getEffectiveMonthKey(DateTime(2026, 12, 31)),
        equals(const MonthKey(2027, 1)),
      );
    });

    test('getCycleDateRangeForMonth computes salary cycle bounds', () {
      // September 2026 cycle: Aug 31 to Sept 29
      final septCycle = GoogleSheetsService.getCycleDateRangeForMonth(const MonthKey(2026, 9));
      expect(septCycle.start, equals(DateTime(2026, 8, 31, 0, 0, 0)));
      expect(septCycle.end, equals(DateTime(2026, 9, 29, 23, 59, 59, 999)));

      // August 2026 cycle: Jul 31 to Aug 30
      final augCycle = GoogleSheetsService.getCycleDateRangeForMonth(const MonthKey(2026, 8));
      expect(augCycle.start, equals(DateTime(2026, 7, 31, 0, 0, 0)));
      expect(augCycle.end, equals(DateTime(2026, 8, 30, 23, 59, 59, 999)));

      // January 2026 cycle: Dec 31, 2025 to Jan 30, 2026
      final janCycle = GoogleSheetsService.getCycleDateRangeForMonth(const MonthKey(2026, 1));
      expect(janCycle.start, equals(DateTime(2025, 12, 31, 0, 0, 0)));
      expect(janCycle.end, equals(DateTime(2026, 1, 30, 23, 59, 59, 999)));
    });

    test('getEffectiveMonthKey with CycleMode.calendar keeps dates in their calendar month', () {
      // Under calendar mode, Aug 31 is still August 2026
      expect(
        GoogleSheetsService.getEffectiveMonthKey(
          DateTime(2026, 8, 31),
          cycleMode: CycleMode.calendar,
        ),
        equals(const MonthKey(2026, 8)),
      );

      // Sept 1 is September 2026
      expect(
        GoogleSheetsService.getEffectiveMonthKey(
          DateTime(2026, 9, 1),
          cycleMode: CycleMode.calendar,
        ),
        equals(const MonthKey(2026, 9)),
      );

      final septRange = GoogleSheetsService.getCycleDateRangeForMonth(
        const MonthKey(2026, 9),
        cycleMode: CycleMode.calendar,
      );
      expect(septRange.start, equals(DateTime(2026, 9, 1, 0, 0, 0)));
      expect(septRange.end, equals(DateTime(2026, 9, 30, 23, 59, 59, 999)));
    });

    test('getEffectiveMonthKey with CycleMode.custom (25th to 24th) maps correctly', () {
      // Aug 25 (after start day) -> belongs to September 2026 cycle
      expect(
        GoogleSheetsService.getEffectiveMonthKey(
          DateTime(2026, 8, 25),
          cycleMode: CycleMode.custom,
          cycleStartDay: 25,
          cycleEndDay: 24,
        ),
        equals(const MonthKey(2026, 9)),
      );

      // Aug 24 (before start day) -> belongs to August 2026 cycle
      expect(
        GoogleSheetsService.getEffectiveMonthKey(
          DateTime(2026, 8, 24),
          cycleMode: CycleMode.custom,
          cycleStartDay: 25,
          cycleEndDay: 24,
        ),
        equals(const MonthKey(2026, 8)),
      );

      // September range for 25th-24th cycle
      final septRange = GoogleSheetsService.getCycleDateRangeForMonth(
        const MonthKey(2026, 9),
        cycleMode: CycleMode.custom,
        cycleStartDay: 25,
        cycleEndDay: 24,
      );
      expect(septRange.start, equals(DateTime(2026, 8, 25, 0, 0, 0)));
      expect(septRange.end, equals(DateTime(2026, 9, 24, 23, 59, 59, 999)));
    });
  });
}

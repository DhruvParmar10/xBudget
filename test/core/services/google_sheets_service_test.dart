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
}

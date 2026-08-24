import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/di/injection_container.dart';
import 'package:xbudget/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:xbudget/main.dart';

void main() {
  testWidgets('xBudget HomeScreen renders Current Balance and summary metrics',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that our app renders the title and balance section
    expect(find.text('XBUDGET'), findsOneWidget);
    expect(find.text('CURRENT BALANCE'), findsOneWidget);
    expect(find.text('Monthly Expense'), findsWidgets);
    expect(find.text('Monthly Income'), findsOneWidget);
    expect(find.text('Net Flow'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);

    // Verify wireframe sections
    await tester.scrollUntilVisible(
      find.text('Last 10 Expenses'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Last 10 Expenses'), findsOneWidget);

    // Verify Bottom Navigation Bar items
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('xBudget BottomNavigationBar navigates between tabs',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap "Transactions" nav item
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    expect(find.text('All Expenses & Transactions'), findsOneWidget);

    // Tap "Settings" nav item
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Google Sheets Sync'), findsOneWidget);
    expect(find.text('Connect Google Account'), findsOneWidget);
    expect(find.text('Sync SMS Inbox'), findsOneWidget);

    // Tap "HOME" nav item
    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
    expect(find.text('CURRENT BALANCE'), findsOneWidget);
  });

  testWidgets('xBudget Note Balance modal updates balance correctly',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);
    final appPreferences = sl<AppPreferences>();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap "Update"
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    // Verify modal sheet appears
    expect(find.text('Note Current Balance'), findsOneWidget);
    expect(find.text('Quick Adjustments'), findsOneWidget);

    // Enter balance in TextField
    await tester.enterText(find.byType(TextField), '30000');
    await tester.pumpAndSettle();

    // Tap quick adjustment "+₹1,000"
    await tester.tap(find.text('+₹1,000'));
    await tester.pumpAndSettle();

    // Tap "Save Balance"
    await tester.tap(find.text('Save Balance'));
    await tester.pumpAndSettle();

    // Verify balance is updated on home screen
    expect(find.text('₹31000.00'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    expect(appPreferences.currentBalance, equals(31000.0));
    expect(appPreferences.balanceSource, equals('manual'));
  });

  testWidgets('xBudget Note Balance modal can clear balance',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);
    final appPreferences = sl<AppPreferences>();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap "Update" to open modal
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    // Tap "Clear" button in modal
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    // Verify balance is cleared
    expect(find.text('Note Balance'), findsOneWidget);
    expect(find.text('₹ --.--'), findsOneWidget);
    expect(appPreferences.currentBalance, isNull);
  });

  testWidgets('xBudget Monthly Billing Cycle setting modal allows changing cycle configuration',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);
    final appPreferences = sl<AppPreferences>();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Navigate to Settings
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Verify Monthly Billing Cycle tile
    expect(find.text('Monthly Billing Cycle'), findsOneWidget);

    // Tap to open bottom sheet
    await tester.tap(find.text('Monthly Billing Cycle'));
    await tester.pumpAndSettle();

    // Verify modal options
    expect(find.text('31st to 30th (1-Day Offset)'), findsOneWidget);
    expect(find.text('1st to End of Month (Calendar)'), findsOneWidget);
    expect(find.text('1st to 1st (Full Month Span)'), findsOneWidget);
    expect(find.text('Custom Date Range'), findsOneWidget);
    expect(find.text('ACTIVE CYCLE PERIOD'), findsOneWidget);

    // Select "1st to End of Month (Calendar)"
    await tester.ensureVisible(find.text('1st to End of Month (Calendar)'));
    await tester.tap(find.text('1st to End of Month (Calendar)'));
    await tester.pumpAndSettle();

    // Tap Save Configuration
    await tester.ensureVisible(find.text('Save Configuration'));
    await tester.tap(find.text('Save Configuration'));
    await tester.pumpAndSettle();

    // Verify preference updated
    expect(appPreferences.cycleMode.name, equals('calendar'));
  });

  testWidgets('xBudget Add Transaction modal adds expense and deducts from Current Balance',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);
    final appPreferences = sl<AppPreferences>();

    // Set initial balance of 20,000 at a fixed earlier timestamp
    final baseTime = DateTime.now().subtract(const Duration(minutes: 5));
    await appPreferences.setCurrentBalance(20000.0, source: 'manual', updatedAt: baseTime);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify initial balance
    expect(find.text('₹20000.00'), findsOneWidget);

    // Tap "Add Transaction" FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify modal appears
    expect(find.text('Deducts from Current Balance'), findsOneWidget);

    // Enter amount 2500
    await tester.enterText(find.byType(TextField).first, '2500');
    await tester.pumpAndSettle();

    // Tap "Record Expense"
    await tester.ensureVisible(find.text('Record Expense'));
    await tester.tap(find.text('Record Expense'));
    await tester.pumpAndSettle();

    // Verify balance is deducted: 20000 - 2500 = 17500.00
    expect(find.text('₹17500.00'), findsOneWidget);
  });

  testWidgets('xBudget Add Transaction modal adds income and adds to Current Balance',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);
    final appPreferences = sl<AppPreferences>();

    // Set initial balance of 10,000 at a fixed earlier timestamp
    final baseTime = DateTime.now().subtract(const Duration(minutes: 5));
    await appPreferences.setCurrentBalance(10000.0, source: 'manual', updatedAt: baseTime);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify initial balance
    expect(find.text('₹10000.00'), findsOneWidget);

    // Tap "Add Transaction" FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Switch to "Income (+)"
    await tester.tap(find.text('Income (+)'));
    await tester.pumpAndSettle();

    expect(find.text('Adds to Current Balance'), findsOneWidget);

    // Enter amount 5000
    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.pumpAndSettle();

    // Tap "Record Income"
    await tester.ensureVisible(find.text('Record Income'));
    await tester.tap(find.text('Record Income'));
    await tester.pumpAndSettle();

    // Verify balance is increased: 10000 + 5000 = 15000.00
    expect(find.text('₹15000.00'), findsOneWidget);
  });

  testWidgets('xBudget real-time category change reflects immediately in UI without refresh',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 1. Add a transaction via FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Fill Merchant: "Starbucks"
    await tester.enterText(find.byType(TextField).at(1), 'Starbucks');
    await tester.pumpAndSettle();

    // Fill Amount: "350"
    await tester.enterText(find.byType(TextField).first, '350');
    await tester.pumpAndSettle();

    // Tap "Record Expense"
    await tester.ensureVisible(find.text('Record Expense'));
    await tester.tap(find.text('Record Expense'));
    await tester.pumpAndSettle();

    // 2. Navigate to Transactions Tab
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    // Verify the transaction is visible with initial category "Food & Dining"
    final starbucksTile = find.ancestor(
      of: find.text('Starbucks'),
      matching: find.byType(TransactionTile),
    );
    expect(starbucksTile, findsOneWidget);
    expect(
      find.descendant(of: starbucksTile, matching: find.textContaining('Food & Dining •')),
      findsOneWidget,
    );

    // 3. Tap on the transaction to open the bottom sheet
    await tester.tap(find.text('Starbucks'));
    await tester.pumpAndSettle();

    // Bottom sheet is visible with categories
    expect(find.text('Change Category:'), findsOneWidget);

    // 4. Tap "Shopping" category chip
    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();

    // 5. Verify the modal closed and the category updated immediately to "Shopping" in real-time
    expect(find.text('Change Category:'), findsNothing);
    expect(
      find.descendant(of: starbucksTile, matching: find.textContaining('Shopping •')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: starbucksTile, matching: find.textContaining('Food & Dining •')),
      findsNothing,
    );
  });
}

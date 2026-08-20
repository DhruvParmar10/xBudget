import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/di/injection_container.dart';
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
    expect(find.text('xBudget'), findsOneWidget);
    expect(find.text('CURRENT BALANCE'), findsOneWidget);
    expect(find.text('Monthly Expense'), findsOneWidget);
    expect(find.text('Monthly Income'), findsOneWidget);
    expect(find.text('Net Flow'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);

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
}

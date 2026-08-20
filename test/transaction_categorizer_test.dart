import 'package:flutter_test/flutter_test.dart';
import 'package:xbudget/core/utils/parsed_transaction.dart';
import 'package:xbudget/core/utils/transaction_categorizer.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';

void main() {
  group('TransactionCategorizer Tests', () {
    final testDate = DateTime(2026, 8, 20);

    ParsedTransaction createTxn({
      required String merchant,
      double amount = 100.0,
      String transactionType = 'expense',
      bool isP2P = false,
      String rawMessage = '',
    }) {
      return ParsedTransaction(
        amount: amount,
        merchant: merchant,
        transactionType: transactionType,
        isP2P: isP2P,
        date: testDate,
        rawMessage: rawMessage.isNotEmpty ? rawMessage : 'Paid to $merchant',
      );
    }

    test('should categorize food & dining merchants correctly', () {
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Swiggy')),
        equals(BudgetCategory.food),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Zomato')),
        equals(BudgetCategory.food),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Starbucks Cafe')),
        equals(BudgetCategory.food),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'McDonalds')),
        equals(BudgetCategory.food),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Amul Ice Cream Parlour')),
        equals(BudgetCategory.food),
      );
    });

    test('should categorize grocery merchants correctly', () {
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Blinkit')),
        equals(BudgetCategory.groceries),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Zepto Marketplace')),
        equals(BudgetCategory.groceries),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'BigBasket')),
        equals(BudgetCategory.groceries),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'DMart Supermarket')),
        equals(BudgetCategory.groceries),
      );
    });

    test('should categorize transport and fuel merchants correctly', () {
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Uber Rides')),
        equals(BudgetCategory.transport),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Ola Cabs')),
        equals(BudgetCategory.transport),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Indian Oil Petrol')),
        equals(BudgetCategory.transport),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'IRCTC Train')),
        equals(BudgetCategory.transport),
      );
    });

    test('should categorize shopping merchants correctly', () {
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Amazon Pay')),
        equals(BudgetCategory.shopping),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Flipkart')),
        equals(BudgetCategory.shopping),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Myntra Fashion')),
        equals(BudgetCategory.shopping),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Zara India')),
        equals(BudgetCategory.shopping),
      );
    });

    test('should categorize bills and utilities correctly', () {
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Airtel Prepaid')),
        equals(BudgetCategory.bills),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Bescom Electricity')),
        equals(BudgetCategory.bills),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Jio Fiber')),
        equals(BudgetCategory.bills),
      );
    });

    test('should categorize entertainment subscriptions and movies correctly', () {
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Netflix')),
        equals(BudgetCategory.entertainment),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Spotify India')),
        equals(BudgetCategory.entertainment),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'BookMyShow Cinema')),
        equals(BudgetCategory.entertainment),
      );
    });

    test('should categorize salary and income correctly', () {
      expect(
        TransactionCategorizer.categorize(
          createTxn(
            merchant: 'Tech Corp Payroll',
            transactionType: 'income',
            rawMessage: 'Your A/c is credited with Rs 1,00,000 for August Salary',
          ),
        ),
        equals(BudgetCategory.salary),
      );
    });

    test('should categorize investments correctly', () {
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Zerodha Broking')),
        equals(BudgetCategory.investment),
      );
      expect(
        TransactionCategorizer.categorize(createTxn(merchant: 'Groww Mutual Fund')),
        equals(BudgetCategory.investment),
      );
    });

    test('should route generic P2P transfer to p2pTransfer category', () {
      final p2pTxn = createTxn(
        merchant: 'Rahul Sharma',
        isP2P: true,
        rawMessage: 'Rs 500 debited from A/c; trf to Rahul Sharma via UPI',
      );

      expect(
        TransactionCategorizer.categorize(p2pTxn),
        equals(BudgetCategory.p2pTransfer),
      );
    });

    test('should prioritize user custom rules over default heuristics', () {
      final customRules = {
        'rahul sharma': BudgetCategory.rent,
        'local grocery': BudgetCategory.groceries,
      };

      final p2pRentTxn = createTxn(
        merchant: 'Rahul Sharma',
        isP2P: true,
        rawMessage: 'Rs 25,000 debited; trf to Rahul Sharma',
      );

      // Even though isP2P is true, user rule maps it to Rent
      expect(
        TransactionCategorizer.categorize(p2pRentTxn, userRules: customRules),
        equals(BudgetCategory.rent),
      );
    });

    test('should fallback to uncategorized for unknown merchants', () {
      final unknownTxn = createTxn(merchant: 'Unknown Vendor 9876');

      expect(
        TransactionCategorizer.categorize(unknownTxn),
        equals(BudgetCategory.uncategorized),
      );
    });
  });
}

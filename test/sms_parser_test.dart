import 'package:flutter_test/flutter_test.dart';
import 'package:xbudget/core/utils/bank_parser_strategy.dart';
import 'package:xbudget/core/utils/parsed_transaction.dart';
import 'package:xbudget/core/utils/sms_parser.dart';
import 'package:xbudget/core/utils/strategies/icici_parser_strategy.dart';

void main() {
  group('IciciParserStrategy Tests', () {
    late IciciParserStrategy strategy;
    final testDate = DateTime(2026, 8, 20, 14, 30);

    setUp(() {
      strategy = IciciParserStrategy();
    });

    test('should identify ICICI bank name', () {
      expect(strategy.bankName, equals('ICICI'));
    });

    test('should return true for eligible ICICI debit SMS from bank sender', () {
      const sender = 'VM-ICICIB';
      const body =
          'Dear Customer, Rs 141.00 debited from A/c XX123 on 20-Aug-26; SWIGGY credited. Avl Bal Rs 5,420.00';

      expect(strategy.isEligible(sender, body), isTrue);
    });

    test('should return true for eligible ICICI credit SMS with bank in body', () {
      const sender = 'AD-BANK';
      const body =
          'ICICI Bank: Your A/c XX123 is credited with Rs 5,000.00 on 20-Aug-26. Avl Bal Rs 15,000.00';

      expect(strategy.isEligible(sender, body), isTrue);
    });

    test('should return false for OTP or non-transactional messages', () {
      const sender = 'VM-ICICIB';
      const body =
          'Your One Time Password (OTP) for ICICI Bank NetBanking login is 839201. Do not share it with anyone.';

      expect(strategy.isEligible(sender, body), isFalse);
    });

    test('should parse standard ICICI debit SMS with merchant and balance', () {
      const body =
          'Dear Customer, Rs 141.00 debited from A/c XX123 on 20-Aug-26; SWIGGY credited. Avl Bal Rs 5,420.00';

      final result = strategy.parse(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(141.00));
      expect(result.merchant, equals('Swiggy'));
      expect(result.transactionType, equals('expense'));
      expect(result.isP2P, isFalse);
      expect(result.date, equals(testDate));
      expect(result.balance, equals(5420.00));
    });

    test('should extract available balance from various balance formats', () {
      const body1 = 'Avl. Bal: INR 25,000.50. Rs 750.00 spent on ICICI Card XX1002 at Cafe Coffee Day.';
      final res1 = strategy.parse(body1, testDate);
      expect(res1?.balance, equals(25000.50));

      const body2 = 'Your A/c XX123 is credited with Rs 50,000.00 on 20-Aug-26. Total Bal: Rs.75,000.00';
      final res2 = strategy.parse(body2, testDate);
      expect(res2?.balance, equals(75000.00));
    });

    test('should correctly extract transaction amount even when balance is mentioned first', () {
      const body =
          'Avl Bal Rs 12,500.00. Dear Customer, Rs 350.00 debited from A/c XX123; Blinkit credited.';

      final result = strategy.parse(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(350.00));
      expect(result.merchant, equals('Blinkit'));
      expect(result.transactionType, equals('expense'));
    });

    test('should extract transaction amount when available limit is mentioned first', () {
      const body =
          'Available limit is INR 50,000.00. Your Account XX987 has been debited by INR 2,499.00 on 15-Feb-24; Apple Store debited.';

      final result = strategy.parse(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(2499.00));
      expect(result.merchant, equals('Apple Store'));
      expect(result.transactionType, equals('expense'));
    });

    test('should extract transaction amount with "debited from A/c for Rs"', () {
      const body =
          'Total Bal: Rs.45,000.00. ICICI Bank Acct XX123 debited from A/c XX123 for Rs.350 on 12-Jan-24; Swiggy debited.';

      final result = strategy.parse(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(350.00));
      expect(result.merchant, equals('Swiggy'));
    });

    test('should extract spent amount on card with Avl Bal at beginning', () {
      const body =
          'Avl. Bal: INR 25,000.50. Rs 750.00 spent on ICICI Card XX1002 at Cafe Coffee Day.';

      final result = strategy.parse(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(750.00));
      expect(result.merchant, equals('Cafe Coffee Day'));
      expect(result.transactionType, equals('expense'));
    });

    test('should parse debit with amount after debited keyword and fallback payee', () {
      const body =
          'Acct XX123 debited with INR 1,250.50 on 20-Aug-26 paid to Zomato via UPI. Bal: INR 10,000';

      final result = strategy.parse(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(1250.50));
      expect(result.merchant, equals('Zomato'));
      expect(result.transactionType, equals('expense'));
      expect(result.isP2P, isFalse);
    });

    test('should parse ICICI credit income transaction', () {
      const body =
          'Your A/c XX123 is credited with Rs 50,000.00 on 20-Aug-26 by salary transfer. Avl Bal Rs 75,000.00';

      final result = strategy.parse(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(50000.00));
      expect(result.transactionType, equals('income'));
    });

    test('should flag P2P transfer correctly', () {
      const body =
          'Dear Customer, Rs 500.00 debited from A/c XX123; trf to Rahul Sharma via UPI. Avl Bal Rs 2,000';

      final result = strategy.parse(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(500.00));
      expect(result.isP2P, isTrue);
    });
  });

  group('Composite SmsParser Coordinator Tests', () {
    final testDate = DateTime(2026, 8, 20, 14, 30);

    test('should parse eligible SMS using default ICICI strategy', () {
      final parser = SmsParser();
      const sender = 'VM-ICICIB';
      const body =
          'Dear Customer, Rs 299.00 debited from A/c XX123 on 20-Aug-26; Uber debited. Avl Bal Rs 3,000.00';

      expect(parser.isEligibleTransactionSms(sender, body), isTrue);

      final result = parser.parse(
        sender: sender,
        body: body,
        timestamp: testDate,
      );

      expect(result, isNotNull);
      expect(result!.amount, equals(299.00));
      expect(result.merchant, equals('Uber'));
      expect(result.transactionType, equals('expense'));
    });

    test('should return null for unsupported bank or non-transaction SMS', () {
      final parser = SmsParser();
      const sender = 'VK-HDFCBK';
      const body = 'Your OTP for login is 123456';

      expect(parser.isEligibleTransactionSms(sender, body), isFalse);

      final result = parser.parse(
        sender: sender,
        body: body,
        timestamp: testDate,
      );

      expect(result, isNull);
    });

    test('should allow custom bank strategies to be registered', () {
      // Mock / custom strategy for HDFC
      final customStrategy = _MockHdfcStrategy();
      final parser = SmsParser(strategies: [
        IciciParserStrategy(),
        customStrategy,
      ]);

      expect(parser.strategies.length, equals(2));

      const sender = 'VK-HDFCBK';
      const body = 'HDFC Bank: Rs 800 debited from card ending 4567 at AMAZON';

      expect(parser.isEligibleTransactionSms(sender, body), isTrue);

      final result = parser.parse(
        sender: sender,
        body: body,
        timestamp: testDate,
      );

      expect(result, isNotNull);
      expect(result!.amount, equals(800.00));
      expect(result.merchant, equals('Amazon'));
    });
  });
}

class _MockHdfcStrategy implements BankParserStrategy {
  @override
  String get bankName => 'HDFC';

  @override
  bool isEligible(String sender, String body) {
    return sender.toLowerCase().contains('hdfc') ||
        body.toLowerCase().contains('hdfc');
  }

  @override
  ParsedTransaction? parse(String body, DateTime timestamp) {
    return ParsedTransaction(
      amount: 800.00,
      merchant: 'Amazon',
      transactionType: 'expense',
      isP2P: false,
      date: timestamp,
      rawMessage: body,
    );
  }
}

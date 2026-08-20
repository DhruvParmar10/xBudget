import '../bank_parser_strategy.dart';
import '../parsed_transaction.dart';

/// Strategy implementation for ICICI Bank transaction SMS messages.
class IciciParserStrategy implements BankParserStrategy {
  @override
  String get bankName => 'ICICI';

  // ---------------------------------------------------------------------------
  // REGEX PATTERNS & ANCHORS
  // ---------------------------------------------------------------------------

  // Fast Pass Guard Filters
  static final RegExp _bankNameRegex = RegExp(
    r'icici\s*bank',
    caseSensitive: false,
  );
  static final RegExp _bankSenderRegex = RegExp(r'icici', caseSensitive: false);
  static final RegExp _debitRegex = RegExp(
    r'\b(?:debited|spent|withdrawn|transferred|paid|sent)\b',
    caseSensitive: false,
  );
  static final RegExp _creditRegex = RegExp(
    r'\b(?:credited|refunded|received|deposited)\b',
    caseSensitive: false,
  );

  // Amount Anchors & Balance Filters:
  // 1. Anchored to verbs (e.g. "Rs 141.00 debited", "debited from A/c XX for Rs 350", "INR 1,250 credited")
  static final RegExp _anchoredAmountRegex = RegExp(
    r'(?:(?:Rs\.?|INR)\s*([\d,]+(?:\.\d{2})?)\s*(?:has been|is|was)?\s*(?:debited|credited|spent|transferred|withdrawn|paid|used))|'
    r'(?:(?:debited|credited|spent|transferred|withdrawn|paid|used)\s+(?:(?:from|to|in)\s+[^,;.]+?\s+)?(?:by|for|with|of)?\s*(?:Rs\.?|INR)\s*([\d,]+(?:\.\d{2})?))',
    caseSensitive: false,
  );

  // Balance Pattern: Matches balance/limit text so it can be stripped before fallback extraction
  // e.g. "Avl Bal Rs 5,420.00", "Available Balance: INR 10,000", "Total Bal: Rs.45,000", "Bal is Rs 1,800", "Available limit is INR 50,000"
  static final RegExp _balancePattern = RegExp(
    r'(?:avl(?:ail)?(?:\.|\s+)?bal(?:ance)?|total\s+bal(?:ance)?|a\/c\s+bal(?:ance)?|bal(?:ance)?(?:\s+is)?|limit)\s*(?::|=|is)?\s*(?:Rs\.?|INR)?\s*[\d,]+(?:\.\d{2})?',
    caseSensitive: false,
  );

  // Balance Extraction Pattern: Specifically extracts the available balance amount
  static final RegExp _balanceExtractRegex = RegExp(
    r'(?:avl(?:ail)?(?:\.|\s+)?bal(?:ance)?|total\s+bal(?:ance)?|a\/c\s+bal(?:ance)?|bal(?:ance)?(?:\s+is)?)\s*(?::|=|is)?\s*(?:Rs\.?|INR)?\s*([\d,]+(?:\.\d{2})?)',
    caseSensitive: false,
  );

  // General Amount Fallback: Matches "Rs 141.00", "INR 1,250.50", "Rs.500"
  static final RegExp _generalAmountRegex = RegExp(
    r'(?:Rs\.?|INR)\s*([\d,]+(?:\.\d{2})?)',
    caseSensitive: false,
  );

  // ICICI Payee Target: Captures text between ';' and 'credited/debited'
  // e.g. "; SWIGGY credited." -> SWIGGY or "; Uber debited." -> Uber
  static final RegExp _iciciPayeeRegex = RegExp(
    r';\s*([^;]+?)\s+(?:credited|debited)',
    caseSensitive: false,
  );

  // Fallback Payee Target: Captures text after "paid to", "at", or "trf to"
  static final RegExp _fallbackPayeeRegex = RegExp(
    r'(?:paid to|at|trf to|sent to)\s+([A-Za-z0-9\s&]+?)(?:\.|\s+via|\s+UPI|\s+on|\s*$)',
    caseSensitive: false,
  );

  // P2P & Merchant Detection Signals
  static final RegExp _p2pSignalRegex = RegExp(
    r'\b(?:trf to|sent to|vpa|transfer to)\b',
    caseSensitive: false,
  );

  static final List<String> _knownMerchants = [
    'swiggy',
    'zomato',
    'uber',
    'ola',
    'amazon',
    'flipkart',
    'blinkit',
    'zepto',
    'pvt ltd',
    'llp',
    'store',
    'amul',
    'pharmacy',
    'petrol',
  ];

  // ---------------------------------------------------------------------------
  // STRATEGY METHODS
  // ---------------------------------------------------------------------------

  @override
  bool isEligible(String sender, String body) {
    final isIcici =
        _bankSenderRegex.hasMatch(sender) || _bankNameRegex.hasMatch(body);
    final hasAction = _debitRegex.hasMatch(body) || _creditRegex.hasMatch(body);

    return isIcici && hasAction;
  }

  @override
  ParsedTransaction? parse(String body, DateTime timestamp) {
    // 1. Determine Transaction Type
    final isDebit = _debitRegex.hasMatch(body);
    final isCredit = _creditRegex.hasMatch(body);

    if (!isDebit && !isCredit) return null;
    final String transactionType = isDebit ? 'expense' : 'income';

    // 2. Extract Amount
    final double? amount = _extractAmount(body);
    if (amount == null) return null;

    // 3. Extract & Clean Merchant/Payee
    final rawPayee = _extractRawPayee(body);
    final cleanedPayee = _cleanPayee(rawPayee);

    // 4. Differentiate P2P vs P2M
    final isP2P = _checkIfP2P(cleanedPayee, body);

    // 5. Extract Balance if present
    final double? balance = _extractBalance(body);

    return ParsedTransaction(
      amount: amount,
      merchant: cleanedPayee,
      transactionType: transactionType,
      isP2P: isP2P,
      date: timestamp,
      rawMessage: body,
      balance: balance,
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER METHODS
  // ---------------------------------------------------------------------------

  double? _extractBalance(String body) {
    final match = _balanceExtractRegex.firstMatch(body);
    if (match != null && match.group(1) != null) {
      final balStr = match.group(1)!.replaceAll(',', '');
      return double.tryParse(balStr);
    }
    return null;
  }

  double? _extractAmount(String body) {
    // Layer 1: Try verb-anchored match first (highest precision)
    final anchoredMatch = _anchoredAmountRegex.firstMatch(body);
    if (anchoredMatch != null) {
      final amountStr = (anchoredMatch.group(1) ?? anchoredMatch.group(2))
          ?.replaceAll(',', '');
      final amount = double.tryParse(amountStr ?? '');
      if (amount != null) return amount;
    }

    // Layer 2: Strip any balance / limit phrases to prevent balance collision in fallback
    final bodyWithoutBalance = body.replaceAll(_balancePattern, '');

    // Layer 3: Match general currency pattern on sanitized body
    final generalMatch = _generalAmountRegex.firstMatch(bodyWithoutBalance);
    if (generalMatch != null) {
      final amountStr = generalMatch.group(1)?.replaceAll(',', '');
      return double.tryParse(amountStr ?? '');
    }

    return null;
  }

  String _extractRawPayee(String body) {
    // Primary ICICI Pattern Match
    final primaryMatch = _iciciPayeeRegex.firstMatch(body);
    if (primaryMatch != null && primaryMatch.group(1) != null) {
      return primaryMatch.group(1)!.trim();
    }

    // Secondary Generic Match
    final fallbackMatch = _fallbackPayeeRegex.firstMatch(body);
    if (fallbackMatch != null && fallbackMatch.group(1) != null) {
      return fallbackMatch.group(1)!.trim();
    }

    return 'Unknown Payee';
  }

  String _cleanPayee(String raw) {
    String text = raw
        .replaceAll(
          RegExp(r'^(UPI:|INFO\*|REF:|ORDER:)', caseSensitive: false),
          '',
        )
        .trim();

    // Standardize casing to Title Case (e.g., SWIGGY -> Swiggy)
    if (text.isNotEmpty && text == text.toUpperCase()) {
      return text
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
    }

    return text;
  }

  bool _checkIfP2P(String merchantName, String body) {
    final lowerMerchant = merchantName.toLowerCase();
    final lowerBody = body.toLowerCase();

    // If it contains known merchant keywords, it's NOT P2P
    for (final merchant in _knownMerchants) {
      if (lowerMerchant.contains(merchant)) {
        return false;
      }
    }

    // Check for explicit transfer phrasing
    if (_p2pSignalRegex.hasMatch(lowerBody)) {
      return true;
    }

    return false;
  }
}

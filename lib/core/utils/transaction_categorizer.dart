import '../../domain/entities/budget_category.dart';
import 'parsed_transaction.dart';

/// Intelligent category mapper that assigns [BudgetCategory] to transactions
/// using rules, keyword heuristics, P2P detection, and user custom rules.
class TransactionCategorizer {
  // ---------------------------------------------------------------------------
  // KEYWORD DICTIONARIES
  // ---------------------------------------------------------------------------

  static const Map<BudgetCategory, List<String>> _categoryKeywords = {
    BudgetCategory.food: [
      'swiggy',
      'zomato',
      'mcdonalds',
      'starbucks',
      'kfc',
      'dominos',
      'pizza',
      'burger',
      'cafe',
      'coffee',
      'chai',
      'restaurant',
      'subway',
      'dunkin',
      'barbeque',
      'haldiram',
      'amul',
      'bakery',
      'eats',
      'dineline',
    ],
    BudgetCategory.groceries: [
      'blinkit',
      'zepto',
      'instamart',
      'bigbasket',
      'dmart',
      'supermarket',
      'grofers',
      'nature basket',
      'spencer',
      'more retail',
      'milk',
      'vegetable',
      'fruit',
      'dairy',
      'kirana',
      'provision',
    ],
    BudgetCategory.transport: [
      'uber',
      'ola',
      'rapido',
      'metro',
      'petrol',
      'fuel',
      'irctc',
      'makemytrip',
      'redbus',
      'yulu',
      'indian oil',
      'hpcl',
      'bpcl',
      'shell',
      'toll',
      'fastag',
      'parking',
      'auto',
      'cab',
      'railway',
    ],
    BudgetCategory.shopping: [
      'amazon',
      'flipkart',
      'myntra',
      'zara',
      'h&m',
      'nykaa',
      'ajio',
      'tata cliq',
      'meesho',
      'croma',
      'reliance digital',
      'decathlon',
      'uniqlo',
      'urban company',
      'lenskart',
      'westside',
      'pantaloons',
      'shoppers stop',
    ],
    BudgetCategory.bills: [
      'airtel',
      'jio',
      'vi',
      'vodafone',
      'bescom',
      'electricity',
      'broadband',
      'tatasky',
      'dth',
      'water',
      'gas',
      'billdesk',
      'cred',
      'act fibernet',
      'recharge',
      'cesc',
      'mahavitaran',
    ],
    BudgetCategory.entertainment: [
      'netflix',
      'spotify',
      'prime',
      'hotstar',
      'bookmyshow',
      'pvr',
      'inox',
      'youtube',
      'apple.com/bill',
      'disney',
      'cinema',
      'movie',
      'gaming',
      'steam',
      'playstation',
    ],
    BudgetCategory.health: [
      'apollo',
      'pharmeasy',
      '1mg',
      'medplus',
      'hospital',
      'clinic',
      'pharmacy',
      'cult.fit',
      'gym',
      'diagnostic',
      'doctor',
      'practo',
      'chemist',
      'healthcare',
    ],
    BudgetCategory.rent: [
      'rent',
      'landlord',
      'nobroker',
      'housing',
      'society maintenance',
      'maintenance fee',
    ],
    BudgetCategory.investment: [
      'zerodha',
      'groww',
      'upstox',
      'kuvera',
      'mutual fund',
      'etmoney',
      'indmoney',
      'coin',
      'smallcase',
      'sip',
      'deposit',
      'shares',
    ],
    BudgetCategory.salary: [
      'salary',
      'payroll',
      'wages',
      'stipend',
      'bonus',
      'reimbursement',
    ],
  };

  // ---------------------------------------------------------------------------
  // CATEGORIZATION LOGIC
  // ---------------------------------------------------------------------------

  /// Determines the [BudgetCategory] for a given [ParsedTransaction].
  ///
  /// Priority order:
  /// 1. User custom rules ([userRules]) matching merchant name / VPA.
  /// 2. Income signals (e.g. salary).
  /// 3. P2P transfers (routes to [BudgetCategory.p2pTransfer] if no custom rule).
  /// 4. Known merchant keyword heuristics.
  /// 5. Fallback to [BudgetCategory.uncategorized].
  static BudgetCategory categorize(
    ParsedTransaction txn, {
    Map<String, BudgetCategory>? userRules,
  }) {
    final lowerMerchant = txn.merchant.toLowerCase().trim();
    final lowerRaw = txn.rawMessage.toLowerCase();

    // 1. Check user-defined custom rules first
    if (userRules != null && userRules.isNotEmpty) {
      for (final entry in userRules.entries) {
        final ruleKey = entry.key.toLowerCase().trim();
        if (lowerMerchant.contains(ruleKey) || lowerRaw.contains(ruleKey)) {
          return entry.value;
        }
      }
    }

    // 2. Handle income transactions
    if (txn.transactionType.toLowerCase() == 'income') {
      for (final salaryKw in _categoryKeywords[BudgetCategory.salary]!) {
        if (lowerMerchant.contains(salaryKw) || lowerRaw.contains(salaryKw)) {
          return BudgetCategory.salary;
        }
      }
      for (final invKw in _categoryKeywords[BudgetCategory.investment]!) {
        if (lowerMerchant.contains(invKw) || lowerRaw.contains(invKw)) {
          return BudgetCategory.investment;
        }
      }
      return BudgetCategory.uncategorized;
    }

    // 3. Handle P2P transfers (Requires manual review unless matched by custom rule)
    if (txn.isP2P) {
      return BudgetCategory.p2pTransfer;
    }

    // 4. Keyword matching against known merchants & categories
    for (final entry in _categoryKeywords.entries) {
      // Skip income-only categories for expenses
      if (entry.key == BudgetCategory.salary) continue;

      for (final keyword in entry.value) {
        if (lowerMerchant.contains(keyword) || lowerRaw.contains(keyword)) {
          return entry.key;
        }
      }
    }

    // 5. Default fallback
    return BudgetCategory.uncategorized;
  }
}

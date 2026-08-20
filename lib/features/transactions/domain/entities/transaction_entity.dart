import 'budget_category.dart';

/// Pure domain entity representing a financial transaction.
class TransactionEntity {
  /// Deterministic unique identifier (SHA-256 hash) for deduplication.
  final String id;

  /// Transaction amount in local currency (INR).
  final double amount;

  /// Merchant or Payee name.
  final String merchant;

  /// Type of transaction: 'expense' or 'income'.
  final String transactionType;

  /// Assigned budget category.
  final BudgetCategory category;

  /// Indicates if this is a Peer-to-Peer transfer (e.g. friend/family) vs merchant.
  final bool isP2P;

  /// Date and time when the transaction occurred (from SMS timestamp).
  final DateTime date;

  /// Original raw SMS message body.
  final String rawMessage;

  /// Whether the user explicitly reviewed/categorized this transaction.
  final bool isUserCategorized;

  /// Optional user notes.
  final String? note;

  /// Local timestamp when the transaction was parsed & saved.
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.transactionType,
    required this.category,
    required this.isP2P,
    required this.date,
    required this.rawMessage,
    this.isUserCategorized = false,
    this.note,
    required this.createdAt,
  });

  bool get isExpense => transactionType.toLowerCase() == 'expense';
  bool get isIncome => transactionType.toLowerCase() == 'income';

  TransactionEntity copyWith({
    String? id,
    double? amount,
    String? merchant,
    String? transactionType,
    BudgetCategory? category,
    bool? isP2P,
    DateTime? date,
    String? rawMessage,
    bool? isUserCategorized,
    String? note,
    DateTime? createdAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      isP2P: isP2P ?? this.isP2P,
      date: date ?? this.date,
      rawMessage: rawMessage ?? this.rawMessage,
      isUserCategorized: isUserCategorized ?? this.isUserCategorized,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransactionEntity(id: $id, amount: ₹$amount, merchant: "$merchant", category: ${category.name}, type: $transactionType, isP2P: $isP2P, date: $date)';
  }
}

import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../core/utils/parsed_transaction.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/entities/transaction_entity.dart';

/// Data model for [TransactionEntity] with JSON serialization and deterministic ID generation.
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.merchant,
    required super.transactionType,
    required super.category,
    required super.isP2P,
    required super.date,
    required super.rawMessage,
    super.isUserCategorized = false,
    super.note,
    required super.createdAt,
  });

  /// Generates a deterministic SHA-256 hash ID based on transaction parameters.
  /// Ensures identical transactions produce the exact same ID for deduplication.
  static String generateId({
    required double amount,
    required String merchant,
    required DateTime date,
    required String rawMessage,
  }) {
    final cleanMerchant = merchant.toLowerCase().trim();
    final cleanMessage = rawMessage.trim();
    // Normalize date to seconds/timestamp to avoid millisecond discrepancies
    final dateKey = date.millisecondsSinceEpoch;

    final rawKey = '$amount|$cleanMerchant|$dateKey|$cleanMessage';
    return sha256.convert(utf8.encode(rawKey)).toString();
  }

  /// Creates a [TransactionModel] from a [ParsedTransaction] and assigned [BudgetCategory].
  factory TransactionModel.fromParsedTransaction(
    ParsedTransaction parsed,
    BudgetCategory category, {
    bool isUserCategorized = false,
    String? note,
    DateTime? createdAt,
  }) {
    final id = generateId(
      amount: parsed.amount,
      merchant: parsed.merchant,
      date: parsed.date,
      rawMessage: parsed.rawMessage,
    );

    return TransactionModel(
      id: id,
      amount: parsed.amount,
      merchant: parsed.merchant,
      transactionType: parsed.transactionType,
      category: category,
      isP2P: parsed.isP2P,
      date: parsed.date,
      rawMessage: parsed.rawMessage,
      isUserCategorized: isUserCategorized,
      note: note,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Converts a [TransactionEntity] to a [TransactionModel].
  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      amount: entity.amount,
      merchant: entity.merchant,
      transactionType: entity.transactionType,
      category: entity.category,
      isP2P: entity.isP2P,
      date: entity.date,
      rawMessage: entity.rawMessage,
      isUserCategorized: entity.isUserCategorized,
      note: entity.note,
      createdAt: entity.createdAt,
    );
  }

  /// Deserializes a JSON map into a [TransactionModel].
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      merchant: json['merchant'] as String,
      transactionType: json['transactionType'] as String? ?? 'expense',
      category: BudgetCategory.fromString(json['category'] as String?),
      isP2P: json['isP2P'] as bool? ?? false,
      date: DateTime.parse(json['date'] as String),
      rawMessage: json['rawMessage'] as String? ?? '',
      isUserCategorized: json['isUserCategorized'] as bool? ?? false,
      note: json['note'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Serializes the model into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'transactionType': transactionType,
      'category': category.name,
      'isP2P': isP2P,
      'date': date.toIso8601String(),
      'rawMessage': rawMessage,
      'isUserCategorized': isUserCategorized,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

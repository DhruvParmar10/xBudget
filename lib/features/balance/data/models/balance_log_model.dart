import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../domain/entities/balance_log_entity.dart';

class BalanceLogModel extends BalanceLogEntity {
  const BalanceLogModel({
    required super.id,
    required super.timestamp,
    required super.previousBalance,
    required super.adjustmentAmount,
    required super.resultingBalance,
    super.source = 'manual',
    super.note,
    required super.createdAt,
  });

  /// Helper to generate a unique ID using timestamp and parameters.
  static String generateId({
    required DateTime timestamp,
    required double adjustmentAmount,
    required String source,
  }) {
    final rawKey = '${timestamp.millisecondsSinceEpoch}|$adjustmentAmount|$source|${DateTime.now().microsecondsSinceEpoch}';
    return sha256.convert(utf8.encode(rawKey)).toString();
  }

  factory BalanceLogModel.fromEntity(BalanceLogEntity entity) {
    return BalanceLogModel(
      id: entity.id,
      timestamp: entity.timestamp,
      previousBalance: entity.previousBalance,
      adjustmentAmount: entity.adjustmentAmount,
      resultingBalance: entity.resultingBalance,
      source: entity.source,
      note: entity.note,
      createdAt: entity.createdAt,
    );
  }

  factory BalanceLogModel.fromJson(Map<String, dynamic> json) {
    return BalanceLogModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      previousBalance: (json['previousBalance'] as num).toDouble(),
      adjustmentAmount: (json['adjustmentAmount'] as num).toDouble(),
      resultingBalance: (json['resultingBalance'] as num).toDouble(),
      source: json['source'] as String? ?? 'manual',
      note: json['note'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'previousBalance': previousBalance,
      'adjustmentAmount': adjustmentAmount,
      'resultingBalance': resultingBalance,
      'source': source,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

import 'package:equatable/equatable.dart';

/// Pure domain entity representing an audit log entry for a balance change or adjustment.
class BalanceLogEntity extends Equatable {
  final String id;
  final DateTime timestamp;
  final double previousBalance;
  /// Positive for credits/additions, negative for debits/subtractions.
  final double adjustmentAmount;
  final double resultingBalance;
  /// Source of the change: 'manual', 'sms', or 'opening'.
  final String source;
  final String? note;
  final DateTime createdAt;

  const BalanceLogEntity({
    required this.id,
    required this.timestamp,
    required this.previousBalance,
    required this.adjustmentAmount,
    required this.resultingBalance,
    this.source = 'manual',
    this.note,
    required this.createdAt,
  });

  bool get isAddition => adjustmentAmount >= 0;
  bool get isSubtraction => adjustmentAmount < 0;

  BalanceLogEntity copyWith({
    String? id,
    DateTime? timestamp,
    double? previousBalance,
    double? adjustmentAmount,
    double? resultingBalance,
    String? source,
    String? note,
    DateTime? createdAt,
  }) {
    return BalanceLogEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      previousBalance: previousBalance ?? this.previousBalance,
      adjustmentAmount: adjustmentAmount ?? this.adjustmentAmount,
      resultingBalance: resultingBalance ?? this.resultingBalance,
      source: source ?? this.source,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        previousBalance,
        adjustmentAmount,
        resultingBalance,
        source,
        note,
        createdAt,
      ];
}

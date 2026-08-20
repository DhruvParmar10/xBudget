import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_event.dart';

class TransactionDetailsBottomSheet extends StatelessWidget {
  final TransactionEntity txn;

  const TransactionDetailsBottomSheet({
    super.key,
    required this.txn,
  });

  static Future<void> show(BuildContext context, TransactionEntity txn) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<TransactionBloc>(),
        child: TransactionDetailsBottomSheet(txn: txn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                txn.merchant,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${txn.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: txn.isExpense ? Colors.redAccent : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Date: ${txn.date.day}/${txn.date.month}/${txn.date.year} ${txn.date.hour.toString().padLeft(2, '0')}:${txn.date.minute.toString().padLeft(2, '0')}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          const Text(
            'Change Category:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BudgetCategory.values.map((cat) {
              final isSelected = txn.category == cat;
              return ChoiceChip(
                label: Text(cat.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    context.read<TransactionBloc>().add(
                          UpdateCategoryEvent(
                            transactionId: txn.id,
                            category: cat,
                          ),
                        );
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Raw SMS Message:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              txn.rawMessage,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Deduplication ID: ${txn.id.substring(0, 16)}...',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

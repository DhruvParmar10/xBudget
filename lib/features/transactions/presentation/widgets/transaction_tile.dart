import 'package:flutter/material.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';
import 'category_ui_helper.dart';
import 'transaction_details_bottom_sheet.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity txn;

  const TransactionTile({
    super.key,
    required this.txn,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryUiHelper.getColor(txn.category);
    final catIcon = CategoryUiHelper.getIcon(txn.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => TransactionDetailsBottomSheet.show(context, txn),
        leading: CircleAvatar(
          backgroundColor: catColor.withValues(alpha: 0.15),
          child: Icon(catIcon, color: catColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                txn.merchant,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (txn.isP2P)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.deepPurple.shade200,
                  ),
                ),
                child: Text(
                  'P2P',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
            if (txn.isUserCategorized)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Edited',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${txn.category.displayName} • ${txn.date.day}/${txn.date.month}/${txn.date.year}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Text(
          '${txn.isExpense ? '-' : '+'}₹${txn.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: txn.isExpense ? Colors.redAccent : Colors.green,
          ),
        ),
      ),
    );
  }
}

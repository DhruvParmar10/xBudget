import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_state.dart';
import 'empty_transactions_view.dart';
import 'transaction_tile.dart';

class TransactionListView extends StatelessWidget {
  const TransactionListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is TransactionError) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        final transactions = state is TransactionLoaded ? state.transactions : [];

        if (transactions.isEmpty) {
          return const EmptyTransactionsView();
        }

        return Column(
          children: transactions.map((txn) => TransactionTile(txn: txn)).toList(),
        );
      },
    );
  }
}

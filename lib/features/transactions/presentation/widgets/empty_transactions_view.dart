import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_event.dart';

class EmptyTransactionsView extends StatelessWidget {
  const EmptyTransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Sync SMS" to parse your inbox, or tap ⚡ to load sample ICICI SMS.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<SyncBloc>().add(const InjectSampleSmsEvent());
            },
            icon: const Icon(Icons.flash_on),
            label: const Text('Load Sample ICICI SMS'),
          ),
        ],
      ),
    );
  }
}

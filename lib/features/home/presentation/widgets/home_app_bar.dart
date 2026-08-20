import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_event.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_state.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _showClearDataDialog(BuildContext context) async {
    final syncBloc = context.read<SyncBloc>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Storage?'),
        content: const Text(
          'This will clear all transactions, user rules, and the sync timestamp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      syncBloc.add(const ResetAllDataEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final isLoading = state is SyncInProgress;

        return AppBar(
          title: const Text(
            'xBudget',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'Sync SMS',
              icon: const Icon(Icons.sync),
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<SyncBloc>().add(const TriggerSmsSyncEvent());
                    },
            ),
            IconButton(
              tooltip: 'Clear Data',
              icon: const Icon(Icons.delete_outline),
              onPressed: isLoading ? null : () => _showClearDataDialog(context),
            ),
          ],
        );
      },
    );
  }
}

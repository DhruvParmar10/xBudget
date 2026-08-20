import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_event.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_state.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final isLoading = state is SyncInProgress;

        return AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'XBUDGET',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: 4.0,
              color: AppColors.cream,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh / Sync SMS',
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cream,
                      ),
                    )
                  : const Icon(Icons.refresh, color: AppColors.cream),
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<SyncBloc>().add(const TriggerSmsSyncEvent());
                    },
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}


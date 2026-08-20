import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_state.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        String? message;
        Color bgColor = Colors.blue.shade50;
        Color textColor = Colors.blue.shade900;

        if (state is SyncInProgress) {
          if (!state.isAutoSync) {
            message = state.message;
          }
        } else if (state is SyncSuccess) {
          message = state.message;
          bgColor = Colors.teal.shade50;
          textColor = Colors.teal.shade900;
        } else if (state is SyncFailure) {
          message = state.errorMessage;
          bgColor = Colors.red.shade50;
          textColor = Colors.red.shade900;
        }

        if (message == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_bloc.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_event.dart';
import 'package:xbudget/features/balance/presentation/widgets/balance_hero_card.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_event.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_state.dart';
import 'package:xbudget/features/sync/presentation/widgets/sync_status_banner.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:xbudget/features/transactions/presentation/widgets/category_filter_chips.dart';
import 'package:xbudget/features/transactions/presentation/widgets/transaction_list_view.dart';
import 'package:xbudget/features/home/presentation/widgets/home_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data through BLoCs
    context.read<BalanceBloc>().add(const LoadBalanceEvent());
    context.read<TransactionBloc>().add(const LoadTransactionsEvent());
    // Auto-sync SMS on app launch
    context.read<SyncBloc>().add(const TriggerSmsSyncEvent(isAutoSync: true));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SyncBloc, SyncState>(
          listener: (context, state) {
            if (state is SyncSuccess) {
              // Reload transactions and balance after sync or storage reset
              context.read<TransactionBloc>().add(const LoadTransactionsEvent());
              context.read<BalanceBloc>().add(const LoadBalanceEvent());
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: const HomeAppBar(),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<SyncBloc>().add(const TriggerSmsSyncEvent());
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Hero Balance & Financial Summary Card
              const BalanceHeroCard(),

              // Sync Status Banner (if active)
              const SyncStatusBanner(),

              const SizedBox(height: 16),

              // Category Filter Chips
              const CategoryFilterChips(),

              const SizedBox(height: 16),

              // Transaction Section Header
              BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  final count = state is TransactionLoaded ? state.transactions.length : 0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$count items',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),

              // Transaction Feed
              const TransactionListView(),
            ],
          ),
        ),
      ),
    );
  }
}

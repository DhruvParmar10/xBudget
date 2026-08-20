import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_bloc.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_event.dart';
import 'package:xbudget/features/balance/presentation/widgets/balance_hero_card.dart';
import 'package:xbudget/features/home/presentation/widgets/category_breakdown_list.dart';
import 'package:xbudget/features/home/presentation/widgets/expense_pie_chart.dart';
import 'package:xbudget/features/home/presentation/widgets/home_app_bar.dart';
import 'package:xbudget/features/home/presentation/widgets/recent_expenses_section.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_event.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_state.dart';
import 'package:xbudget/features/sync/presentation/widgets/sync_status_banner.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:xbudget/features/transactions/presentation/widgets/category_filter_chips.dart';
import 'package:xbudget/features/transactions/presentation/widgets/transaction_list_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 1; // Default to 'HOME'

  @override
  void initState() {
    super.initState();
    // Initialize data through BLoCs
    context.read<BalanceBloc>().add(const LoadBalanceEvent());
    context.read<TransactionBloc>().add(const LoadTransactionsEvent());
    // Auto-sync SMS on app launch
    context.read<SyncBloc>().add(const TriggerSmsSyncEvent(isAutoSync: true));
  }

  void _onNavBarTapped(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  Widget _buildHomeDashboard() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        context.read<SyncBloc>().add(const TriggerSmsSyncEvent());
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Current Balance & Financial Summary
          const BalanceHeroCard(),

          // 2. Sync Status Banner (if active)
          const SyncStatusBanner(),

          const Divider(color: AppColors.divider, height: 28),

          // 3. Monthly Expense Pie Chart with Category Breakdown
          const ExpensePieChart(),

          const Divider(color: AppColors.divider, height: 28),

          // 4. Category Breakdown List ($25000 per category)
          const CategoryBreakdownList(),

          const Divider(color: AppColors.divider, height: 28),

          // 5. Last 10 Expenses
          RecentExpensesSection(
            onSeeMore: () => _onNavBarTapped(0),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildExpensesView() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        context.read<SyncBloc>().add(const TriggerSmsSyncEvent());
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const Text(
            'All Expenses & Transactions',
            style: TextStyle(
              color: AppColors.cream,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const CategoryFilterChips(),
          const SizedBox(height: 16),
          const TransactionListView(),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.cream,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: AppColors.surfaceLight.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.sync, color: AppColors.primary),
                title: const Text('Sync SMS Inbox', style: TextStyle(color: AppColors.cream)),
                subtitle: const Text('Parse transactions from bank messages', style: TextStyle(color: AppColors.onSurfaceVariant)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.cream),
                onTap: () {
                  context.read<SyncBloc>().add(const TriggerSmsSyncEvent());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Syncing SMS inbox...')),
                  );
                },
              ),
              const Divider(color: AppColors.border, height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.expense),
                title: const Text('Reset Storage', style: TextStyle(color: AppColors.expense)),
                subtitle: const Text('Clear all cached transactions and preferences', style: TextStyle(color: AppColors.onSurfaceVariant)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.cream),
                onTap: () {
                  context.read<SyncBloc>().add(const ResetAllDataEvent());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data cleared.')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
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
        backgroundColor: AppColors.background,
        appBar: const HomeAppBar(),
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildExpensesView(),
            _buildHomeDashboard(),
            _buildSettingsView(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: _onNavBarTapped,
          backgroundColor: AppColors.navBarBackground,
          selectedItemColor: AppColors.navBarSelected,
          unselectedItemColor: AppColors.navBarUnselected,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

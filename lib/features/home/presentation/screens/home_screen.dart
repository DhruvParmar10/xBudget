import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/database/migration_service.dart';
import 'package:xbudget/core/di/injection_container.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/core/utils/cycle_date_util.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_bloc.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_event.dart';
import 'package:xbudget/features/balance/presentation/widgets/balance_hero_card.dart';
import 'package:xbudget/features/home/presentation/widgets/category_breakdown_list.dart';
import 'package:xbudget/features/home/presentation/widgets/expense_pie_chart.dart';
import 'package:xbudget/features/home/presentation/widgets/home_app_bar.dart';
import 'package:xbudget/features/home/presentation/widgets/monthly_cycle_settings_bottom_sheet.dart';
import 'package:xbudget/features/home/presentation/widgets/recent_expenses_section.dart';
import 'package:xbudget/features/sync/presentation/bloc/google_sheets_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/google_sheets_event.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_event.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_state.dart';
import 'package:xbudget/features/sync/presentation/widgets/sync_status_banner.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:xbudget/features/transactions/presentation/widgets/add_transaction_bottom_sheet.dart';
import 'package:xbudget/features/transactions/presentation/widgets/category_filter_chips.dart';
import 'package:xbudget/features/transactions/presentation/widgets/transaction_list_view.dart';
import 'package:xbudget/features/home/presentation/widgets/google_sheets_sync_card.dart';

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
    // Check Google authentication status
    context.read<GoogleSheetsBloc>().add(const CheckGoogleSheetsAuthEvent());
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

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTransactionsView() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        context.read<SyncBloc>().add(const TriggerSmsSyncEvent());
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Expenses & Transactions',
                style: TextStyle(
                  color: AppColors.cream,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                tooltip: 'Add Transaction',
                onPressed: () => AddTransactionBottomSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const CategoryFilterChips(),
          const SizedBox(height: 16),
          const TransactionListView(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    final prefs = sl.isRegistered<AppPreferences>() ? sl<AppPreferences>() : null;
    final cycleDesc = prefs != null
        ? CycleDateUtil.getCycleDescription(
            mode: prefs.cycleMode,
            startDay: prefs.cycleStartDay,
            endDay: prefs.cycleEndDay,
          )
        : '31st to 30th (1-day offset)';

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
        const GoogleSheetsSyncCard(),
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
                leading: const Icon(Icons.calendar_month, color: AppColors.primary),
                title: const Text('Monthly Billing Cycle', style: TextStyle(color: AppColors.cream)),
                subtitle: Text(
                  cycleDesc,
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.cream),
                onTap: () async {
                  await MonthlyCycleSettingsBottomSheet.show(context);
                  setState(() {});
                  if (mounted) {
                    context.read<TransactionBloc>().add(const LoadTransactionsEvent());
                  }
                },
              ),
              const Divider(color: AppColors.divider, height: 1),
              ListTile(
                leading: const Icon(Icons.sync, color: AppColors.primary),
                title: const Text('Sync SMS Inbox', style: TextStyle(color: AppColors.cream)),
                subtitle: const Text('Scan device inbox for new SMS messages', style: TextStyle(color: AppColors.onSurfaceVariant)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.cream),
                onTap: () {
                  context.read<SyncBloc>().add(const TriggerSmsSyncEvent());
                },
              ),
              const Divider(color: AppColors.divider, height: 1),
              _buildLegacyStorageTile(context),
              const Divider(color: AppColors.divider, height: 1),
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

  Widget _buildLegacyStorageTile(BuildContext context) {
    final prefs = sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null;
    if (prefs == null) return const SizedBox.shrink();

    final hasBackup = MigrationService.hasLegacyBackup(prefs);
    final counts = MigrationService.getLegacyBackupCounts(prefs);

    return ListTile(
      leading: Icon(
        hasBackup ? Icons.cleaning_services : Icons.storage_rounded,
        color: hasBackup ? AppColors.caramelOrange : AppColors.income,
      ),
      title: const Text(
        'Legacy Backup Storage',
        style: TextStyle(color: AppColors.cream),
      ),
      subtitle: Text(
        hasBackup
            ? 'Legacy backup found (${counts.$1} txns, ${counts.$2} logs). Tap to reclaim storage.'
            : 'Storage optimized. All data runs on SQLite.',
        style: const TextStyle(color: AppColors.onSurfaceVariant),
      ),
      trailing: hasBackup
          ? const Icon(Icons.delete_sweep, color: AppColors.caramelOrange)
          : const Icon(Icons.check_circle_outline, color: AppColors.income),
      onTap: hasBackup
          ? () => _showReclaimStorageDialog(context, prefs, counts)
          : null,
    );
  }

  void _showReclaimStorageDialog(
    BuildContext context,
    SharedPreferences prefs,
    (int, int) counts,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Reclaim Legacy Storage',
          style: TextStyle(color: AppColors.cream, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your data has been safely migrated to the new SQLite database. '
          'Reclaiming will permanently remove the legacy SharedPreferences backup '
          '(${counts.$1} transactions and ${counts.$2} balance logs) to free up storage.\n\n'
          'Are you sure you want to proceed?',
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.cream)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.caramelOrange,
              foregroundColor: AppColors.cream,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await MigrationService.reclaimLegacyStorage(prefs);
              if (!mounted) return;
              setState(() {});
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Legacy storage successfully reclaimed!'),
                ),
              );
            },
            child: const Text('Reclaim Storage'),
          ),
        ],
      ),
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
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionLoaded) {
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
            _buildTransactionsView(),
            _buildHomeDashboard(),
            _buildSettingsView(),
          ],
        ),
        floatingActionButton: _currentNavIndex != 2
            ? FloatingActionButton.extended(
                onPressed: () => AddTransactionBottomSheet.show(context),
                backgroundColor: AppColors.caramelOrange,
                foregroundColor: AppColors.cream,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Transaction',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: _onNavBarTapped,
          backgroundColor: AppColors.navBarBackground,
          selectedItemColor: AppColors.navBarSelected,
          unselectedItemColor: AppColors.navBarUnselected,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Transactions',
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

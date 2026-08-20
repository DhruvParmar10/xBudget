import 'package:flutter/material.dart';
import '../../core/constants/app_preferences.dart';
import '../../core/services/sms_sync_service.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';

class HomeScreen extends StatefulWidget {
  final TransactionRepository repository;
  final AppPreferences preferences;
  final SmsSyncService syncService;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.preferences,
    required this.syncService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  List<TransactionEntity> _transactions = [];
  Map<BudgetCategory, double> _categorySpend = {};
  double _totalExpense = 0.0;
  double _totalIncome = 0.0;
  double? _currentBalance;
  DateTime? _balanceUpdatedAt;
  String _balanceSource = 'manual';
  BudgetCategory? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-sync on app open checking timestamps
    _performSync(isAutoSync: true);
  }

  Future<void> _loadData() async {
    final txns = await widget.repository.getTransactions(
      category: _selectedCategoryFilter,
    );
    final breakdown = await widget.repository.getSpendByCategory();
    final expense = await widget.repository.getTotalSpend();

    final allTxns = await widget.repository.getTransactions();
    final income = allTxns
        .where((t) => t.isIncome)
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final currentBal = widget.preferences.currentBalance;
    final balUpdated = widget.preferences.balanceUpdatedAt;
    final balSrc = widget.preferences.balanceSource;

    if (mounted) {
      setState(() {
        _transactions = txns;
        _categorySpend = breakdown;
        _totalExpense = expense;
        _totalIncome = income;
        _currentBalance = currentBal;
        _balanceUpdatedAt = balUpdated;
        _balanceSource = balSrc;
      });
    }
  }

  Future<void> _performSync({
    bool isAutoSync = false,
    bool forceInitial = false,
  }) async {
    setState(() {
      _isLoading = true;
      if (!isAutoSync) _statusMessage = 'Syncing SMS...';
    });

    final result = await widget.syncService.syncSms(
      forceInitialLookback: forceInitial,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _statusMessage =
              'Synced ${result.totalSmsFound} SMS (${result.newTransactionsAdded} new)';
        } else {
          _statusMessage = result.errorMessage;
        }
      });
      await _loadData();
    }
  }

  Future<void> _injectSampleData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading past 2 months sample ICICI SMS...';
    });

    final result = await widget.syncService.injectSampleMessages();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage =
            'Loaded ${result.totalSmsFound} SMS (${result.newTransactionsAdded} added)';
      });
      await _loadData();
    }
  }

  Future<void> _clearAllData() async {
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
      await widget.preferences.clearAll();
      final all = await widget.repository.getTransactions();
      for (final t in all) {
        await widget.repository.deleteTransaction(t.id);
      }
      if (mounted) {
        setState(() {
          _statusMessage = 'Storage reset successfully';
        });
        await _loadData();
      }
    }
  }

  void _showTransactionDetails(TransactionEntity txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                    onSelected: (selected) async {
                      if (selected) {
                        await widget.repository.updateTransactionCategory(
                          txn.id,
                          cat,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        _loadData();
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
      },
    );
  }

  void _showNoteBalanceModal() {
    final textController = TextEditingController(
      text: _currentBalance != null ? _currentBalance!.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            void applyDelta(double delta) {
              final currentVal = double.tryParse(textController.text) ?? 0.0;
              final newVal = (currentVal + delta).clamp(0.0, 999999999.0);
              textController.text = newVal.toStringAsFixed(2);
              setModalState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Note Current Balance',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Update your day-to-day available funds',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Adjustments',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 14, color: Colors.green),
                          label: const Text('+₹500'),
                          onPressed: () => applyDelta(500),
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 14, color: Colors.green),
                          label: const Text('+₹1,000'),
                          onPressed: () => applyDelta(1000),
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 14, color: Colors.green),
                          label: const Text('+₹5,000'),
                          onPressed: () => applyDelta(5000),
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          avatar: const Icon(Icons.remove, size: 14, color: Colors.redAccent),
                          label: const Text('-₹500'),
                          onPressed: () => applyDelta(-500),
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          avatar: const Icon(Icons.remove, size: 14, color: Colors.redAccent),
                          label: const Text('-₹1,000'),
                          onPressed: () => applyDelta(-1000),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_currentBalance != null)
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await widget.preferences.clearCurrentBalance();
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Current balance cleared'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                      if (_currentBalance != null) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final val = double.tryParse(textController.text.trim());
                            if (val != null) {
                              await widget.preferences.setCurrentBalance(
                                val,
                                source: 'manual',
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Balance updated to ₹${val.toStringAsFixed(2)}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          label: const Text('Save Balance'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return 'Never';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  IconData _getCategoryIcon(BudgetCategory cat) {
    switch (cat) {
      case BudgetCategory.food:
        return Icons.restaurant;
      case BudgetCategory.groceries:
        return Icons.shopping_basket;
      case BudgetCategory.transport:
        return Icons.directions_car;
      case BudgetCategory.shopping:
        return Icons.shopping_bag;
      case BudgetCategory.bills:
        return Icons.receipt_long;
      case BudgetCategory.entertainment:
        return Icons.movie;
      case BudgetCategory.health:
        return Icons.medical_services;
      case BudgetCategory.rent:
        return Icons.home;
      case BudgetCategory.investment:
        return Icons.trending_up;
      case BudgetCategory.salary:
        return Icons.account_balance_wallet;
      case BudgetCategory.p2pTransfer:
        return Icons.swap_horiz;
      case BudgetCategory.uncategorized:
        return Icons.category;
    }
  }

  Color _getCategoryColor(BudgetCategory cat) {
    switch (cat) {
      case BudgetCategory.food:
        return Colors.orange;
      case BudgetCategory.groceries:
        return Colors.green;
      case BudgetCategory.transport:
        return Colors.blue;
      case BudgetCategory.shopping:
        return Colors.purple;
      case BudgetCategory.bills:
        return Colors.amber.shade700;
      case BudgetCategory.entertainment:
        return Colors.pink;
      case BudgetCategory.health:
        return Colors.teal;
      case BudgetCategory.rent:
        return Colors.indigo;
      case BudgetCategory.investment:
        return Colors.cyan;
      case BudgetCategory.salary:
        return Colors.green.shade700;
      case BudgetCategory.p2pTransfer:
        return Colors.deepPurple;
      case BudgetCategory.uncategorized:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastSync = widget.preferences.lastSyncTimestamp;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'xBudget',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Load Sample SMS',
            icon: const Icon(Icons.flash_on),
            onPressed: _isLoading ? null : _injectSampleData,
          ),
          IconButton(
            tooltip: 'Sync SMS',
            icon: const Icon(Icons.sync),
            onPressed: _isLoading ? null : () => _performSync(),
          ),
          IconButton(
            tooltip: 'Clear Data',
            icon: const Icon(Icons.delete_outline),
            onPressed: _isLoading ? null : _clearAllData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _performSync(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // -----------------------------------------------------------------
            // HERO CURRENT BALANCE & SUMMARY CARD
            // -----------------------------------------------------------------
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                      Theme.of(context).colorScheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Label, Source badge, and Note/Update Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CURRENT BALANCE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (_currentBalance != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _balanceSource == 'sms'
                                      ? Colors.teal.shade50
                                      : Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _balanceSource == 'sms'
                                        ? Colors.teal.shade200
                                        : Colors.indigo.shade200,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  _balanceSource == 'sms' ? 'SMS' : 'Manual',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: _balanceSource == 'sms'
                                        ? Colors.teal.shade800
                                        : Colors.indigo.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        InkWell(
                          onTap: _showNoteBalanceModal,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _currentBalance != null ? Icons.edit_outlined : Icons.add,
                                  size: 13,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentBalance != null ? 'Update' : 'Note Balance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Hero Balance Amount
                    GestureDetector(
                      onTap: _showNoteBalanceModal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentBalance != null)
                            Text(
                              '₹${_currentBalance!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            )
                          else
                            Row(
                              children: [
                                Text(
                                  '₹ --.--',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(Tap to note balance)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          if (_balanceUpdatedAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                'Updated: ${_formatTimestamp(_balanceUpdatedAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const Divider(height: 24),

                    // Income & Expense & Net Cash Flow Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_downward, size: 13, color: Colors.redAccent.shade700),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'Total Expense',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${_totalExpense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_upward, size: 13, color: Colors.green.shade700),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'Total Income',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${_totalIncome.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    (_totalIncome - _totalExpense) >= 0
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    size: 13,
                                    color: (_totalIncome - _totalExpense) >= 0
                                        ? Colors.teal
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'Net Flow',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(_totalIncome - _totalExpense) >= 0 ? '+' : ''}₹${(_totalIncome - _totalExpense).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: (_totalIncome - _totalExpense) >= 0
                                      ? Colors.teal.shade700
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 13,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Last Sync: ${_formatTimestamp(lastSync)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (_isLoading)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // CATEGORY FILTER CHIPS
            // -----------------------------------------------------------------
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All (${_transactions.length})'),
                    selected: _selectedCategoryFilter == null,
                    onSelected: (_) {
                      setState(() => _selectedCategoryFilter = null);
                      _loadData();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...BudgetCategory.values.map((cat) {
                    final spend = _categorySpend[cat] ?? 0.0;
                    final isSelected = _selectedCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: Icon(
                          _getCategoryIcon(cat),
                          size: 16,
                          color: isSelected ? Colors.white : _getCategoryColor(cat),
                        ),
                        label: Text(
                          spend > 0
                              ? '${cat.displayName} (₹${spend.toStringAsFixed(0)})'
                              : cat.displayName,
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryFilter = selected ? cat : null;
                          });
                          _loadData();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // TRANSACTION FEED
            // -----------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_transactions.length} items',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_transactions.isEmpty && !_isLoading)
              Container(
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
                      onPressed: _injectSampleData,
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Load Sample ICICI SMS'),
                    ),
                  ],
                ),
              ),

            ..._transactions.map((txn) {
              final catColor = _getCategoryColor(txn.category);
              final catIcon = _getCategoryIcon(txn.category);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () => _showTransactionDetails(txn),
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
            }),
          ],
        ),
      ),
    );
  }
}

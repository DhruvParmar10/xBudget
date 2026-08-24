import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_event.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  const AddTransactionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<TransactionBloc>(),
        child: const AddTransactionBottomSheet(),
      ),
    );
  }

  @override
  State<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  String _transactionType = 'expense'; // 'expense' or 'income'
  BudgetCategory _selectedCategory = BudgetCategory.food;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String type) {
    setState(() {
      _transactionType = type;
      if (type == 'income' && _selectedCategory == BudgetCategory.food) {
        _selectedCategory = BudgetCategory.salary;
      } else if (type == 'expense' && _selectedCategory == BudgetCategory.salary) {
        _selectedCategory = BudgetCategory.food;
      }
    });
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.cream,
              surface: AppColors.surface,
              onSurface: AppColors.cream,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final now = DateTime.now();
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          now.hour,
          now.minute,
        );
      });
    }
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final merchant = _merchantController.text.trim().isEmpty
        ? (_transactionType == 'income' ? 'Income' : 'Expense')
        : _merchantController.text.trim();

    context.read<TransactionBloc>().add(
          AddTransactionEvent(
            amount: amount,
            merchant: merchant,
            transactionType: _transactionType,
            category: _selectedCategory,
            date: _selectedDate,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          ),
        );

    Navigator.pop(context);

    final sign = _transactionType == 'expense' ? '-' : '+';
    final action = _transactionType == 'expense' ? 'Expense deducted' : 'Income added';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action: $sign₹${amount.toStringAsFixed(2)} ($merchant)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _transactionType == 'expense';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isExpense ? AppColors.expense : AppColors.income).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isExpense ? AppColors.expense : AppColors.income,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Transaction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cream,
                          ),
                        ),
                        Text(
                          isExpense ? 'Deducts from Current Balance' : 'Adds to Current Balance',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.cream),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Expense / Income Segment Switcher
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged('expense'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isExpense ? AppColors.expense.withValues(alpha: 0.3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isExpense ? Border.all(color: AppColors.expense) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Expense (-)',
                          style: TextStyle(
                            color: isExpense ? AppColors.cream : AppColors.onSurfaceVariant,
                            fontWeight: isExpense ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged('income'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isExpense ? AppColors.income.withValues(alpha: 0.3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: !isExpense ? Border.all(color: AppColors.income) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Income (+)',
                          style: TextStyle(
                            color: !isExpense ? AppColors.cream : AppColors.onSurfaceVariant,
                            fontWeight: !isExpense ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Amount Input Field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isExpense ? AppColors.expense : AppColors.income,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    isExpense ? '-₹' : '+₹',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isExpense ? AppColors.expense : AppColors.income,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '0.00',
                hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isExpense ? AppColors.expense : AppColors.income,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 14),

            // Merchant / Title Input Field
            TextField(
              controller: _merchantController,
              style: const TextStyle(color: AppColors.cream),
              decoration: InputDecoration(
                labelText: isExpense ? 'Merchant / Description' : 'Income Source / Description',
                labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                hintText: isExpense ? 'e.g. Swiggy, Groceries, Tea' : 'e.g. Salary, Client payment',
                hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceLight.withValues(alpha: 0.4),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            const SizedBox(height: 14),

            // Date & Time Picker Row
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.cream),
                    const SizedBox(width: 8),
                    Text(
                      'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(color: AppColors.cream, fontSize: 13),
                    ),
                    const Spacer(),
                    const Text('Change', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Category Selection Chips
            const Text(
              'Category',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.cream),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BudgetCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                final catColor = AppColors.getCategoryColor(cat);
                return ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor: catColor,
                    radius: 5,
                  ),
                  backgroundColor: AppColors.surfaceLight,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.cream : AppColors.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  label: Text(cat.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                style: FilledButton.styleFrom(
                  backgroundColor: isExpense ? AppColors.caramelOrange : AppColors.income,
                  foregroundColor: AppColors.cream,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveTransaction,
                label: Text(
                  isExpense ? 'Record Expense' : 'Record Income',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

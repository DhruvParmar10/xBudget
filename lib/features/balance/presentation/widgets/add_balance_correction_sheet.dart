import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import '../../data/models/balance_log_model.dart';
import '../../domain/entities/balance_log_entity.dart';
import '../bloc/balance_bloc.dart';
import '../bloc/balance_event.dart';
import '../bloc/balance_state.dart';

class AddBalanceCorrectionSheet extends StatefulWidget {
  const AddBalanceCorrectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<BalanceBloc>(),
        child: const AddBalanceCorrectionSheet(),
      ),
    );
  }

  @override
  State<AddBalanceCorrectionSheet> createState() =>
      _AddBalanceCorrectionSheetState();
}

class _AddBalanceCorrectionSheetState extends State<AddBalanceCorrectionSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isAddition = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onSave() {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }

    final balanceState = context.read<BalanceBloc>().state;
    final currentBal =
        balanceState is BalanceLoaded ? (balanceState.currentBalance ?? 0.0) : 0.0;

    final now = DateTime.now();
    final adjustment = _isAddition ? parsed : -parsed;
    final resulting = currentBal + adjustment;

    final id = BalanceLogModel.generateId(
      timestamp: now,
      adjustmentAmount: adjustment,
      source: 'manual',
    );

    final log = BalanceLogEntity(
      id: id,
      timestamp: now,
      previousBalance: currentBal,
      adjustmentAmount: adjustment,
      resultingBalance: resulting,
      source: 'manual',
      note: _noteController.text.trim().isEmpty
          ? (_isAddition ? 'Manual Credit' : 'Manual Debit')
          : _noteController.text.trim(),
      createdAt: now,
    );

    context.read<BalanceBloc>().add(AddBalanceLogEvent(log));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Balance adjusted by ${_isAddition ? "+₹" : "-₹"}${parsed.toStringAsFixed(2)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Add Balance Correction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cream,
                    ),
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
          // Type selector (+ / -)
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 16, color: AppColors.income),
                      SizedBox(width: 4),
                      Text('Add (+)'),
                    ],
                  ),
                  selected: _isAddition,
                  selectedColor: AppColors.surfaceLight,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: _isAddition ? AppColors.income : AppColors.border,
                    width: _isAddition ? 1.5 : 1.0,
                  ),
                  labelStyle: TextStyle(
                    color: _isAddition
                        ? AppColors.income
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    setState(() => _isAddition = true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove, size: 16, color: AppColors.expense),
                      SizedBox(width: 4),
                      Text('Subtract (-)'),
                    ],
                  ),
                  selected: !_isAddition,
                  selectedColor: AppColors.surfaceLight,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: !_isAddition ? AppColors.expense : AppColors.border,
                    width: !_isAddition ? 1.5 : 1.0,
                  ),
                  labelStyle: TextStyle(
                    color: !_isAddition
                        ? AppColors.expense
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    setState(() => _isAddition = false);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.cream,
            ),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cream,
                  ),
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              labelText: 'Correction Amount',
              labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
              hintText: '5000.00',
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: AppColors.cream),
            decoration: InputDecoration(
              labelText: 'Reason / Note (optional)',
              labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
              hintText: 'e.g. Cash payment, ATM withdrawal, typo fix',
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Add Correction Log'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.cream,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _onSave,
            ),
          ),
        ],
      ),
    );
  }
}

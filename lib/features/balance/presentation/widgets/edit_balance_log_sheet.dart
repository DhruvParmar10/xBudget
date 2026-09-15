import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import '../../domain/entities/balance_log_entity.dart';
import '../bloc/balance_bloc.dart';
import '../bloc/balance_event.dart';

class EditBalanceLogSheet extends StatefulWidget {
  final BalanceLogEntity log;

  const EditBalanceLogSheet({super.key, required this.log});

  static Future<void> show(BuildContext context, BalanceLogEntity log) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<BalanceBloc>(),
        child: EditBalanceLogSheet(log: log),
      ),
    );
  }

  @override
  State<EditBalanceLogSheet> createState() => _EditBalanceLogSheetState();
}

class _EditBalanceLogSheetState extends State<EditBalanceLogSheet> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late bool _isAddition;

  @override
  void initState() {
    super.initState();
    _isAddition = widget.log.adjustmentAmount >= 0;
    _amountController = TextEditingController(
      text: widget.log.adjustmentAmount.abs().toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: widget.log.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onSave() {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final newAdjustment = _isAddition ? parsed : -parsed;
    final newResulting = widget.log.previousBalance + newAdjustment;
    final updatedLog = widget.log.copyWith(
      adjustmentAmount: newAdjustment,
      resultingBalance: newResulting,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    context.read<BalanceBloc>().add(UpdateBalanceLogEvent(updatedLog));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Balance log updated'),
        duration: Duration(seconds: 2),
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
                  Icon(Icons.edit_note, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Correct Balance Log',
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
                      Text('Addition (+)'),
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
                    color: _isAddition ? AppColors.income : AppColors.onSurfaceVariant,
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
                      Text('Subtraction (-)'),
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
                    color: !_isAddition ? AppColors.expense : AppColors.onSurfaceVariant,
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
          // Amount Field
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
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              labelText: 'Adjustment Amount',
              labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
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
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          // Note field
          TextField(
            controller: _noteController,
            style: const TextStyle(color: AppColors.cream),
            decoration: InputDecoration(
              labelText: 'Reason / Note',
              labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
              hintText: 'e.g. Cash expense, correction',
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
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
              label: const Text('Save Correction'),
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

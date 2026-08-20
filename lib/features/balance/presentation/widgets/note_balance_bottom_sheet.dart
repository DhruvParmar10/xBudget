import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import '../bloc/balance_bloc.dart';
import '../bloc/balance_event.dart';
import '../bloc/balance_state.dart';

class NoteBalanceBottomSheet extends StatefulWidget {
  const NoteBalanceBottomSheet({super.key});

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
        child: const NoteBalanceBottomSheet(),
      ),
    );
  }

  @override
  State<NoteBalanceBottomSheet> createState() => _NoteBalanceBottomSheetState();
}

class _NoteBalanceBottomSheetState extends State<NoteBalanceBottomSheet> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final balanceState = context.read<BalanceBloc>().state;
    final currentBal = balanceState is BalanceLoaded ? balanceState.currentBalance : null;
    _textController = TextEditingController(
      text: currentBal != null ? currentBal.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _applyDelta(double delta) {
    final currentVal = double.tryParse(_textController.text) ?? 0.0;
    final newVal = (currentVal + delta).clamp(0.0, 999999999.0);
    _textController.text = newVal.toStringAsFixed(2);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        final currentBal = state is BalanceLoaded ? state.currentBalance : null;

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.primary,
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
                              color: AppColors.cream,
                            ),
                          ),
                          Text(
                            'Update your day-to-day available funds',
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
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
              const SizedBox(height: 20),
              TextField(
                controller: _textController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cream,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cream,
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quick Adjustments',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      backgroundColor: AppColors.surfaceLight,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: const TextStyle(color: AppColors.cream),
                      avatar: const Icon(Icons.add, size: 14, color: AppColors.income),
                      label: const Text('+₹500'),
                      onPressed: () => _applyDelta(500),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      backgroundColor: AppColors.surfaceLight,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: const TextStyle(color: AppColors.cream),
                      avatar: const Icon(Icons.add, size: 14, color: AppColors.income),
                      label: const Text('+₹1,000'),
                      onPressed: () => _applyDelta(1000),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      backgroundColor: AppColors.surfaceLight,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: const TextStyle(color: AppColors.cream),
                      avatar: const Icon(Icons.add, size: 14, color: AppColors.income),
                      label: const Text('+₹5,000'),
                      onPressed: () => _applyDelta(5000),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      backgroundColor: AppColors.surfaceLight,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: const TextStyle(color: AppColors.cream),
                      avatar: const Icon(Icons.remove, size: 14, color: AppColors.expense),
                      label: const Text('-₹500'),
                      onPressed: () => _applyDelta(-500),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      backgroundColor: AppColors.surfaceLight,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: const TextStyle(color: AppColors.cream),
                      avatar: const Icon(Icons.remove, size: 14, color: AppColors.expense),
                      label: const Text('-₹1,000'),
                      onPressed: () => _applyDelta(-1000),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (currentBal != null)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cream,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          context.read<BalanceBloc>().add(const ClearBalanceEvent());
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Current balance cleared'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                  if (currentBal != null) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.cream,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final val = double.tryParse(_textController.text.trim());
                        if (val != null) {
                          context.read<BalanceBloc>().add(
                                UpdateBalanceEvent(
                                  balance: val,
                                  source: 'manual',
                                  updatedAt: DateTime.now(),
                                ),
                              );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Balance updated to ₹${val.toStringAsFixed(2)}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
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
  }
}


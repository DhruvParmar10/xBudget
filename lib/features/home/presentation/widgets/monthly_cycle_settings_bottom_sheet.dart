import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/di/injection_container.dart';
import 'package:xbudget/core/theme/app_colors.dart';
import 'package:xbudget/core/utils/cycle_date_util.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_event.dart';

class MonthlyCycleSettingsBottomSheet extends StatefulWidget {
  const MonthlyCycleSettingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<TransactionBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: const MonthlyCycleSettingsBottomSheet(),
      ),
    );
  }

  @override
  State<MonthlyCycleSettingsBottomSheet> createState() =>
      _MonthlyCycleSettingsBottomSheetState();
}

class _MonthlyCycleSettingsBottomSheetState
    extends State<MonthlyCycleSettingsBottomSheet> {
  late final AppPreferences _preferences;
  late CycleMode _selectedMode;
  late int _startDay;
  late int _endDay;

  @override
  void initState() {
    super.initState();
    _preferences = sl.isRegistered<AppPreferences>()
        ? sl<AppPreferences>()
        : AppPreferences(sl<SharedPreferences>());
    _selectedMode = _preferences.cycleMode;
    _startDay = _preferences.cycleStartDay;
    _endDay = _preferences.cycleEndDay;
  }

  void _saveConfiguration() async {
    await _preferences.setCycleConfig(
      mode: _selectedMode,
      startDay: _startDay,
      endDay: _endDay,
    );

    if (mounted) {
      context.read<TransactionBloc>().add(const LoadTransactionsEvent());
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cycle updated: ${CycleDateUtil.getCycleDescription(mode: _selectedMode, startDay: _startDay, endDay: _endDay)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildPresetTile({
    required String title,
    required String subtitle,
    required CycleMode mode,
    int? defaultStart,
    int? defaultEnd,
  }) {
    final isSelected = _selectedMode == mode &&
        (mode != CycleMode.sameDaySpan || (_startDay == (defaultStart ?? 1) && _endDay == (defaultEnd ?? 1)));

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
          if (defaultStart != null) _startDay = defaultStart;
          if (defaultEnd != null) _endDay = defaultEnd;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceLight.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.cream : AppColors.cream.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRange = CycleDateUtil.getCycleRange(
      mode: _selectedMode,
      startDay: _startDay,
      endDay: _endDay,
    );

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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Billing Cycle',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.cream,
                              ),
                            ),
                            Text(
                              'Set start & end dates for monthly tracking',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.cream),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Live Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timelapse,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACTIVE CYCLE PERIOD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${CycleDateUtil.formatShortDate(currentRange.start)}  →  ${CycleDateUtil.formatShortDate(currentRange.end)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Select Preset or Custom',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Presets
            _buildPresetTile(
              title: '31st to 30th (1-Day Offset)',
              subtitle: 'Last day of previous month to day before month end',
              mode: CycleMode.offset31To30,
              defaultStart: 31,
              defaultEnd: 30,
            ),
            _buildPresetTile(
              title: '1st to End of Month (Calendar)',
              subtitle: '1st of month to 30th/31st (Standard calendar)',
              mode: CycleMode.calendar,
              defaultStart: 1,
              defaultEnd: 31,
            ),
            _buildPresetTile(
              title: '1st to 1st (Full Month Span)',
              subtitle: '1st of month to 1st of next month',
              mode: CycleMode.sameDaySpan,
              defaultStart: 1,
              defaultEnd: 1,
            ),
            _buildPresetTile(
              title: 'Custom Date Range',
              subtitle: 'Choose any specific start and end days',
              mode: CycleMode.custom,
            ),

            // Custom Pickers Section (when custom is selected)
            if (_selectedMode == CycleMode.custom) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configure Custom Days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Day',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                initialValue: _startDay,
                                dropdownColor: AppColors.surfaceLight,
                                style: const TextStyle(
                                  color: AppColors.cream,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                                items: List.generate(31, (i) => i + 1)
                                    .map(
                                      (day) => DropdownMenuItem(
                                        value: day,
                                        child: Text(CycleDateUtil.getOrdinal(day)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _startDay = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Day',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                initialValue: _endDay,
                                dropdownColor: AppColors.surfaceLight,
                                style: const TextStyle(
                                  color: AppColors.cream,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                                items: List.generate(31, (i) => i + 1)
                                    .map(
                                      (day) => DropdownMenuItem(
                                        value: day,
                                        child: Text(CycleDateUtil.getOrdinal(day)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _endDay = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
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
                    onPressed: _saveConfiguration,
                    label: const Text('Save Configuration'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

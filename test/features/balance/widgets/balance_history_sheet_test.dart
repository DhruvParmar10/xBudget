import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/features/balance/data/datasources/balance_log_local_datasource.dart';
import 'package:xbudget/features/balance/data/repositories/balance_log_repository_impl.dart';
import 'package:xbudget/features/balance/domain/entities/balance_log_entity.dart';
import 'package:xbudget/features/balance/domain/repositories/balance_log_repository.dart';
import 'package:xbudget/features/balance/domain/usecases/add_balance_log_usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/clear_balance_usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/delete_balance_log_usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/get_balance_usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/set_balance_usecase.dart';
import 'package:xbudget/features/balance/domain/usecases/update_balance_log_usecase.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_bloc.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_event.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_state.dart';
import 'package:xbudget/features/balance/presentation/widgets/balance_history_sheet.dart';

void main() {
  late AppPreferences preferences;
  late BalanceLogRepository balanceLogRepository;
  late BalanceBloc balanceBloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    preferences = AppPreferences(prefs);
    balanceLogRepository = BalanceLogRepositoryImpl(
      localDataSource: BalanceLogLocalDataSourceImpl(prefs),
    );
    final getBalanceUseCase = GetBalanceUseCase(
      preferences: preferences,
      balanceLogRepository: balanceLogRepository,
    );
    final setBalanceUseCase = SetBalanceUseCase(
      preferences: preferences,
      balanceLogRepository: balanceLogRepository,
    );
    final clearBalanceUseCase = ClearBalanceUseCase(
      preferences: preferences,
      balanceLogRepository: balanceLogRepository,
    );
    final addBalanceLogUseCase = AddBalanceLogUseCase(balanceLogRepository);
    final updateBalanceLogUseCase = UpdateBalanceLogUseCase(balanceLogRepository);
    final deleteBalanceLogUseCase = DeleteBalanceLogUseCase(balanceLogRepository);

    balanceBloc = BalanceBloc(
      getBalanceUseCase: getBalanceUseCase,
      setBalanceUseCase: setBalanceUseCase,
      clearBalanceUseCase: clearBalanceUseCase,
      addBalanceLogUseCase: addBalanceLogUseCase,
      updateBalanceLogUseCase: updateBalanceLogUseCase,
      deleteBalanceLogUseCase: deleteBalanceLogUseCase,
    );
  });

  tearDown(() {
    balanceBloc.close();
  });

  testWidgets('BalanceHistorySheet displays visual equation and log details', (tester) async {
    final now = DateTime(2026, 8, 24, 10, 0);
    final openingLog = BalanceLogEntity(
      id: 'log_1',
      timestamp: now,
      previousBalance: 0.0,
      adjustmentAmount: 25000.0,
      resultingBalance: 25000.0,
      source: 'opening',
      note: 'Opening Balance',
      createdAt: now,
    );
    final adjLog = BalanceLogEntity(
      id: 'log_2',
      timestamp: now.add(const Duration(hours: 2)),
      previousBalance: 25000.0,
      adjustmentAmount: -5000.0,
      resultingBalance: 20000.0,
      source: 'manual',
      note: 'Cash paid to friend',
      createdAt: now.add(const Duration(hours: 2)),
    );

    await balanceLogRepository.addBalanceLog(openingLog);
    await balanceLogRepository.addBalanceLog(adjLog);

    balanceBloc.add(const LoadBalanceEvent());
    await tester.runAsync(() async {
      await balanceBloc.stream.firstWhere((s) => s is BalanceLoaded);
    });
    expect(balanceBloc.state, isA<BalanceLoaded>());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: balanceBloc,
            child: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => BalanceHistorySheet.show(ctx),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify title and summary banner
    expect(find.text('Balance Logs & Audit'), findsOneWidget);
    expect(find.text('CALCULATED BALANCE'), findsOneWidget);
    expect(find.text('₹20000.00'), findsWidgets);

    // Verify visual equation: ₹25000.00 - ₹5000.00 = ₹20000.00
    expect(find.text('₹25000.00'), findsNWidgets(2));
    expect(find.text('-'), findsOneWidget);
    expect(find.text('₹5000.00'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('Cash paid to friend'), findsOneWidget);

    // Verify Opening Balance log
    expect(find.text('Opening Balance: '), findsOneWidget);
  });
}

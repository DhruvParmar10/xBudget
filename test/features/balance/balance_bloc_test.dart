import 'package:bloc_test/bloc_test.dart';
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

void main() {
  late AppPreferences preferences;
  late BalanceLogRepository balanceLogRepository;
  late GetBalanceUseCase getBalanceUseCase;
  late SetBalanceUseCase setBalanceUseCase;
  late ClearBalanceUseCase clearBalanceUseCase;
  late AddBalanceLogUseCase addBalanceLogUseCase;
  late UpdateBalanceLogUseCase updateBalanceLogUseCase;
  late DeleteBalanceLogUseCase deleteBalanceLogUseCase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    preferences = AppPreferences(prefs);
    balanceLogRepository = BalanceLogRepositoryImpl(
      localDataSource: BalanceLogLocalDataSourceImpl(prefs),
    );
    getBalanceUseCase = GetBalanceUseCase(
      preferences: preferences,
      balanceLogRepository: balanceLogRepository,
    );
    setBalanceUseCase = SetBalanceUseCase(
      preferences: preferences,
      balanceLogRepository: balanceLogRepository,
    );
    clearBalanceUseCase = ClearBalanceUseCase(
      preferences: preferences,
      balanceLogRepository: balanceLogRepository,
    );
    addBalanceLogUseCase = AddBalanceLogUseCase(balanceLogRepository);
    updateBalanceLogUseCase = UpdateBalanceLogUseCase(balanceLogRepository);
    deleteBalanceLogUseCase = DeleteBalanceLogUseCase(balanceLogRepository);
  });

  BalanceBloc buildBloc() => BalanceBloc(
        getBalanceUseCase: getBalanceUseCase,
        setBalanceUseCase: setBalanceUseCase,
        clearBalanceUseCase: clearBalanceUseCase,
        addBalanceLogUseCase: addBalanceLogUseCase,
        updateBalanceLogUseCase: updateBalanceLogUseCase,
        deleteBalanceLogUseCase: deleteBalanceLogUseCase,
      );

  group('BalanceBloc Tests', () {
    test('initial state is BalanceInitial', () {
      expect(buildBloc().state, equals(const BalanceInitial()));
    });

    blocTest<BalanceBloc, BalanceState>(
      'emits [BalanceLoading, BalanceLoaded] when LoadBalanceEvent is added',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadBalanceEvent()),
      expect: () => [
        const BalanceLoading(),
        const BalanceLoaded(
          currentBalance: null,
          balanceUpdatedAt: null,
          balanceSource: 'manual',
          balanceLogs: [],
        ),
      ],
    );

    blocTest<BalanceBloc, BalanceState>(
      'emits BalanceLoaded with opening log when UpdateBalanceEvent is added initially',
      build: buildBloc,
      act: (bloc) => bloc.add(
        UpdateBalanceEvent(
          balance: 25000.0,
          source: 'manual',
          updatedAt: DateTime(2026, 8, 24, 10, 0),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state, isA<BalanceLoaded>());
        final state = bloc.state as BalanceLoaded;
        expect(state.currentBalance, equals(25000.0));
        expect(state.balanceLogs.length, equals(1));
        expect(state.balanceLogs.first.adjustmentAmount, equals(25000.0));
      },
    );

    blocTest<BalanceBloc, BalanceState>(
      'correctly adds adjustment log and recalculates balance',
      build: buildBloc,
      seed: () => const BalanceLoaded(
        currentBalance: 25000.0,
        balanceUpdatedAt: null,
        balanceSource: 'manual',
        balanceLogs: [],
      ),
      setUp: () async {
        await setBalanceUseCase(
          SetBalanceParams(
            balance: 25000.0,
            updatedAt: DateTime(2026, 8, 24, 10, 0),
          ),
        );
      },
      act: (bloc) {
        final now = DateTime(2026, 8, 24, 11, 0);
        bloc.add(
          AddBalanceLogEvent(
            BalanceLogEntity(
              id: 'adj_1',
              timestamp: now,
              previousBalance: 25000.0,
              adjustmentAmount: -5000.0,
              resultingBalance: 20000.0,
              source: 'manual',
              note: 'Cash expense',
              createdAt: now,
            ),
          ),
        );
      },
      verify: (bloc) {
        final state = bloc.state as BalanceLoaded;
        expect(state.currentBalance, equals(20000.0));
        expect(state.balanceLogs.length, equals(2));
      },
    );

    blocTest<BalanceBloc, BalanceState>(
      'deletes balance log and rolls back calculated balance',
      build: buildBloc,
      setUp: () async {
        await setBalanceUseCase(
          SetBalanceParams(
            balance: 25000.0,
            updatedAt: DateTime(2026, 8, 24, 10, 0),
          ),
        );
        await addBalanceLogUseCase(
          BalanceLogEntity(
            id: 'to_delete',
            timestamp: DateTime(2026, 8, 24, 11, 0),
            previousBalance: 25000.0,
            adjustmentAmount: -5000.0,
            resultingBalance: 20000.0,
            source: 'manual',
            note: 'Mistake',
            createdAt: DateTime.now(),
          ),
        );
      },
      act: (bloc) => bloc.add(const DeleteBalanceLogEvent('to_delete')),
      verify: (bloc) {
        final state = bloc.state as BalanceLoaded;
        // Balance rolls back to 25000
        expect(state.currentBalance, equals(25000.0));
        expect(state.balanceLogs.length, equals(1));
      },
    );

    blocTest<BalanceBloc, BalanceState>(
      'clears balance and logs on ClearBalanceEvent',
      build: buildBloc,
      setUp: () async {
        await setBalanceUseCase(
          SetBalanceParams(
            balance: 25000.0,
            updatedAt: DateTime(2026, 8, 24, 10, 0),
          ),
        );
      },
      act: (bloc) => bloc.add(const ClearBalanceEvent()),
      verify: (bloc) {
        final state = bloc.state as BalanceLoaded;
        expect(state.currentBalance, isNull);
        expect(state.balanceLogs, isEmpty);
      },
    );
  });
}

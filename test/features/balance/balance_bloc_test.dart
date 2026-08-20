import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/constants/app_preferences.dart';
import 'package:xbudget/core/di/injection_container.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_bloc.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_event.dart';
import 'package:xbudget/features/balance/presentation/bloc/balance_state.dart';

void main() {
  late AppPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);
    preferences = sl<AppPreferences>();
  });

  group('BalanceBloc Tests', () {
    test('initial state is BalanceInitial', () {
      final bloc = sl<BalanceBloc>();
      expect(bloc.state, equals(const BalanceInitial()));
    });

    blocTest<BalanceBloc, BalanceState>(
      'emits BalanceLoaded when LoadBalanceEvent is added',
      build: () => sl<BalanceBloc>(),
      act: (bloc) => bloc.add(const LoadBalanceEvent()),
      expect: () => [
        const BalanceLoaded(
          currentBalance: null,
          balanceUpdatedAt: null,
          balanceSource: 'manual',
        ),
      ],
    );

    blocTest<BalanceBloc, BalanceState>(
      'updates balance when UpdateBalanceEvent is added',
      build: () => sl<BalanceBloc>(),
      act: (bloc) => bloc.add(
        const UpdateBalanceEvent(
          balance: 25000.0,
          source: 'manual',
        ),
      ),
      expect: () => [
        isA<BalanceLoaded>()
            .having((s) => s.currentBalance, 'currentBalance', 25000.0)
            .having((s) => s.balanceSource, 'balanceSource', 'manual'),
      ],
      verify: (_) {
        expect(preferences.currentBalance, equals(25000.0));
      },
    );

    blocTest<BalanceBloc, BalanceState>(
      'clears balance when ClearBalanceEvent is added',
      build: () => sl<BalanceBloc>(),
      setUp: () async {
        await preferences.setCurrentBalance(10000.0);
      },
      act: (bloc) => bloc.add(const ClearBalanceEvent()),
      expect: () => [
        isA<BalanceLoaded>()
            .having((s) => s.currentBalance, 'currentBalance', isNull)
            .having((s) => s.balanceUpdatedAt, 'balanceUpdatedAt', isNull),
      ],
      verify: (_) {
        expect(preferences.currentBalance, isNull);
      },
    );
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/di/injection_container.dart';
import 'package:xbudget/domain/repositories/transaction_repository.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_event.dart';
import 'package:xbudget/features/sync/presentation/bloc/sync_state.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);
  });

  group('SyncBloc Tests', () {
    test('initial state is SyncInitial', () {
      final bloc = sl<SyncBloc>();
      expect(bloc.state, isA<SyncInitial>());
    });

    blocTest<SyncBloc, SyncState>(
      'emits [SyncInProgress, SyncSuccess] when InjectSampleSmsEvent is added',
      build: () => sl<SyncBloc>(),
      act: (bloc) => bloc.add(const InjectSampleSmsEvent()),
      expect: () => [
        isA<SyncInProgress>(),
        isA<SyncSuccess>().having((s) => s.syncResult?.isSuccess, 'isSuccess', true),
      ],
      verify: (_) async {
        final repo = sl<TransactionRepository>();
        final txns = await repo.getTransactions();
        expect(txns.isNotEmpty, isTrue);
      },
    );

    blocTest<SyncBloc, SyncState>(
      'emits [SyncInProgress, SyncSuccess] when ResetAllDataEvent is added',
      build: () => sl<SyncBloc>(),
      act: (bloc) => bloc.add(const ResetAllDataEvent()),
      expect: () => [
        isA<SyncInProgress>(),
        isA<SyncSuccess>().having((s) => s.message, 'message', 'Storage reset successfully'),
      ],
    );
  });
}

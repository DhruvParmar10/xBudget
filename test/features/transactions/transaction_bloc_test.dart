import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbudget/core/di/injection_container.dart';
import 'package:xbudget/features/transactions/domain/entities/budget_category.dart';
import 'package:xbudget/features/transactions/domain/entities/transaction_entity.dart';
import 'package:xbudget/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:xbudget/features/transactions/presentation/bloc/transaction_state.dart';

void main() {
  late TransactionRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initDependencies(mockPrefs: prefs);
    repository = sl<TransactionRepository>();
  });

  TransactionEntity createTxn({
    required String id,
    required String merchant,
    required double amount,
    BudgetCategory category = BudgetCategory.food,
    String transactionType = 'expense',
    DateTime? date,
  }) {
    return TransactionEntity(
      id: id,
      amount: amount,
      merchant: merchant,
      transactionType: transactionType,
      category: category,
      isP2P: false,
      date: date ?? DateTime.now(),
      rawMessage: 'Paid $amount to $merchant',
      createdAt: DateTime.now(),
    );
  }

  group('TransactionBloc Tests', () {
    test('initial state is TransactionInitial', () {
      final bloc = sl<TransactionBloc>();
      expect(bloc.state, equals(const TransactionInitial()));
    });

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionLoaded] when LoadTransactionsEvent is added',
      build: () => sl<TransactionBloc>(),
      setUp: () async {
        await repository.saveTransaction(
          createTxn(id: '1', merchant: 'Swiggy', amount: 200.0),
        );
        await repository.saveTransaction(
          createTxn(
            id: '2',
            merchant: 'Salary',
            amount: 50000.0,
            transactionType: 'income',
            category: BudgetCategory.salary,
          ),
        );
      },
      act: (bloc) => bloc.add(const LoadTransactionsEvent()),
      expect: () => [
        const TransactionLoading(),
        isA<TransactionLoaded>()
            .having((s) => s.transactions.length, 'transactions.length', 2)
            .having((s) => s.totalExpense, 'totalExpense', 200.0)
            .having((s) => s.totalIncome, 'totalIncome', 50000.0)
            .having((s) => s.netFlow, 'netFlow', 49800.0),
      ],
    );


    blocTest<TransactionBloc, TransactionState>(
      'filters transactions when FilterCategoryEvent is added',
      build: () => sl<TransactionBloc>(),
      setUp: () async {
        await repository.saveTransaction(
          createTxn(id: '1', merchant: 'Swiggy', amount: 200.0, category: BudgetCategory.food),
        );
        await repository.saveTransaction(
          createTxn(id: '2', merchant: 'Uber', amount: 150.0, category: BudgetCategory.transport),
        );
      },
      act: (bloc) => bloc.add(const FilterCategoryEvent(BudgetCategory.transport)),
      expect: () => [
        isA<TransactionLoaded>()
            .having((s) => s.transactions.length, 'transactions.length', 1)
            .having((s) => s.transactions.first.merchant, 'merchant', 'Uber')
            .having((s) => s.selectedCategory, 'selectedCategory', BudgetCategory.transport),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'updates transaction category when UpdateCategoryEvent is added',
      build: () => sl<TransactionBloc>(),
      setUp: () async {
        await repository.saveTransaction(
          createTxn(id: '1', merchant: 'Local Mart', amount: 100.0, category: BudgetCategory.uncategorized),
        );
      },
      act: (bloc) => bloc.add(
        const UpdateCategoryEvent(
          transactionId: '1',
          category: BudgetCategory.groceries,
        ),
      ),
      expect: () => [
        isA<TransactionLoaded>()
            .having((s) => s.transactions.first.category, 'category', BudgetCategory.groceries),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'deletes transaction when DeleteTransactionEvent is added',
      build: () => sl<TransactionBloc>(),
      setUp: () async {
        await repository.saveTransaction(
          createTxn(id: '1', merchant: 'Swiggy', amount: 200.0),
        );
      },
      act: (bloc) => bloc.add(const DeleteTransactionEvent('1')),
      expect: () => [
        isA<TransactionLoaded>()
            .having((s) => s.transactions.isEmpty, 'transactions.isEmpty', true)
            .having((s) => s.totalExpense, 'totalExpense', 0.0),
      ],
    );
  });
}

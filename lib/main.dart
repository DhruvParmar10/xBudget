import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/balance/presentation/bloc/balance_bloc.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final TransactionBloc? transactionBloc;
  final BalanceBloc? balanceBloc;
  final SyncBloc? syncBloc;

  const MyApp({
    super.key,
    this.transactionBloc,
    this.balanceBloc,
    this.syncBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionBloc>(
          create: (_) => transactionBloc ?? sl<TransactionBloc>(),
        ),
        BlocProvider<BalanceBloc>(
          create: (_) => balanceBloc ?? sl<BalanceBloc>(),
        ),
        BlocProvider<SyncBloc>(
          create: (_) => syncBloc ?? sl<SyncBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'xBudget',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}


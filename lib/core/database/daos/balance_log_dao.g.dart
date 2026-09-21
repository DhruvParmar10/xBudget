// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_log_dao.dart';

// ignore_for_file: type=lint
mixin _$BalanceLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $BalanceLogsTable get balanceLogs => attachedDatabase.balanceLogs;
  BalanceLogDaoManager get managers => BalanceLogDaoManager(this);
}

class BalanceLogDaoManager {
  final _$BalanceLogDaoMixin _db;
  BalanceLogDaoManager(this._db);
  $$BalanceLogsTableTableManager get balanceLogs =>
      $$BalanceLogsTableTableManager(_db.attachedDatabase, _db.balanceLogs);
}

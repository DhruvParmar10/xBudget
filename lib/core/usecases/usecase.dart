import 'package:equatable/equatable.dart';

/// Base class for all UseCases in Clean Architecture.
abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Helper class for use cases that require no parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

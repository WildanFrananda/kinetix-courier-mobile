import 'package:kinetix_courier/core/failure.dart';

sealed class Result<T> {
  const Result();

  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) {
    return switch (this) {
      Ok<T>(:final T value) => onOk(value),
      Err<T>(:final Failure failure) => onErr(failure),
    };
  }
}

class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}

class Unit {
  const Unit._();

  static const Unit unit = Unit._();
}

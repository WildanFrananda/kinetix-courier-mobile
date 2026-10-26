import 'package:fleet_pulse_mobile/core/core.dart';

mixin RetryMixin {
  Future<Result<T>> retry<T>(
    Future<Result<T>> Function() action, {
    int? maxAttempts = 6,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 15),
    bool Function(Failure failure)? retryIf,
    bool Function()? stillWanted,
  }) async {
    Duration delay = initialDelay;
    Result<T> result = await action();
    int attempts = 1;

    while (maxAttempts == null || attempts < maxAttempts) {
      if (result case Ok<T>()) {
        return result;
      }

      final Failure failure = (result as Err<T>).failure;
      final bool again = retryIf?.call(failure) ?? _transient(failure);

      if (!again || !_wanted(stillWanted)) {
        return result;
      }

      await Future<void>.delayed(delay);

      if (!_wanted(stillWanted)) {
        return result;
      }

      final Duration next = delay * 2;
      delay = next > maxDelay ? maxDelay : next;
      result = await action();
      attempts++;
    }

    return result;
  }

  bool _wanted(bool Function()? stillWanted) => stillWanted?.call() ?? true;

  bool _transient(Failure f) => f is NetworkFailure || f is TimeoutFailure;
}

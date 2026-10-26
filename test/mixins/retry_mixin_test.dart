import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/mixins/retry_mixin.dart';
import 'package:flutter_test/flutter_test.dart';

class _Retrier with RetryMixin {}

void main() {
  final _Retrier sut = new _Retrier();

  test('returns Ok on first success', () {
    fakeAsync((async) {
      int calls = 0;
      Result<int>? result;
      unawaited(
        sut
            .retry<int>(() async {
              calls++;
              return const Ok<int>(1);
            })
            .then((r) => result = r),
      );
      async.flushMicrotasks();
      expect(calls, 1);
      expect(result, isA<Ok<int>>());
    });
  });

  test('retries transient failures then succeeds', () {
    fakeAsync((async) {
      int calls = 0;
      Result<int>? result;
      unawaited(
        sut
            .retry<int>(() async {
              calls++;
              return calls < 3
                  ? const Err<int>(NetworkFailure())
                  : const Ok<int>(7);
            })
            .then((r) => result = r),
      );
      async.elapse(const Duration(seconds: 30));
      expect(calls, 3);
      expect((result! as Ok<int>).value, 7);
    });
  });

  test('stops immediately on a terminal failure', () {
    fakeAsync((async) {
      int calls = 0;
      Result<int>? result;
      unawaited(
        sut
            .retry<int>(() async {
              calls++;
              return const Err<int>(ChannelFailure('invalid_transition'));
            })
            .then((r) => result = r),
      );
      async.elapse(const Duration(seconds: 30));
      expect(calls, 1);
      expect(result, isA<Err<int>>());
    });
  });

  test('gives up after maxAttempts', () {
    fakeAsync((async) {
      int calls = 0;
      sut.retry<int>(() async {
        calls++;
        return const Err<int>(NetworkFailure());
      }, maxAttempts: 4).ignore();
      async.elapse(const Duration(minutes: 5));
      expect(calls, 4);
    });
  });
  test('with no attempt limit it retries until answered', () {
    fakeAsync((FakeAsync async) {
      int calls = 0;
      Result<int>? result;

      sut
          .retry<int>(() async {
            calls++;

            return calls < 20
                ? const Err<int>(TimeoutFailure())
                : const Ok<int>(1);
          }, maxAttempts: null)
          .then((Result<int> r) => result = r)
          .ignore();
      async.elapse(const Duration(minutes: 10));

      expect(calls, 20);
      expect(result, isA<Ok<int>>());
    });
  });

  test('stops as soon as the caller no longer wants the answer', () {
    fakeAsync((FakeAsync async) {
      int calls = 0;
      bool wanted = true;
      Result<int>? result;

      sut
          .retry<int>(
            () async {
              calls++;

              return const Err<int>(NetworkFailure());
            },
            maxAttempts: null,
            stillWanted: () => wanted,
          )
          .then((Result<int> r) => result = r)
          .ignore();
      async.elapse(const Duration(seconds: 4));
      wanted = false;
      async.elapse(const Duration(minutes: 1));

      expect(calls, 3);
      expect((result! as Err<int>).failure, isA<NetworkFailure>());
    });
  });
}

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/connection_repository_impl.dart';
import 'package:fleet_pulse_mobile/services/auth/session_renewer.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChannel extends Mock implements ChannelClient {}

class _MockRenewer extends Mock implements SessionRenewer {}

void main() {
  late _MockChannel channel;
  late _MockRenewer renewer;
  late StreamController<void> refusals;
  late StreamController<ConnectionStatus> statuses;
  late ConnectionRepositoryImpl sut;

  const DriverSession signedIn = DriverSession(
    driverId: DriverId(1),
    token: 'expired-access',
    refreshToken: 'refresh-1',
  );
  const DriverSession renewed = DriverSession(
    driverId: DriverId(1),
    token: 'access-2',
    refreshToken: 'refresh-2',
  );

  final TelemetryPing ping = new TelemetryPing(
    latitude: 1,
    longitude: 2,
    recordedAt: DateTime.utc(2026),
  );

  setUpAll(() {
    registerFallbackValue(
      new TelemetryPing(
        latitude: 0,
        longitude: 0,
        recordedAt: DateTime.utc(2026),
      ),
    );
    registerFallbackValue(
      const DriverSession(
        driverId: DriverId(0),
        token: '',
        refreshToken: 'refresh-token',
      ),
    );
  });

  void build() {
    refusals = new StreamController<void>.broadcast();
    statuses = new StreamController<ConnectionStatus>.broadcast();
    when(() => channel.unauthorized).thenAnswer((_) => refusals.stream);
    when(() => channel.statusStream).thenAnswer((_) => statuses.stream);
    sut = new ConnectionRepositoryImpl(channel, renewer);
  }

  setUp(() {
    channel = new _MockChannel();
    renewer = new _MockRenewer();
    when(
      () => channel.connect(any(), wsBase: any(named: 'wsBase')),
    ).thenAnswer((_) async {});
    when(() => channel.disconnect()).thenAnswer((_) async {});
  });

  tearDown(() {
    unawaited(sut.dispose());
    unawaited(refusals.close());
    unawaited(statuses.close());
  });

  void renewsTo(Result<DriverSession> result) {
    when(() => renewer.renew()).thenAnswer((_) async => result);
  }

  test('sendPing ok maps to Ok', () async {
    build();
    when(
      () => channel.ping(any()),
    ).thenAnswer((_) async => const ChannelReply('ok', <String, dynamic>{}));
    expect(await sut.sendPing(ping), isA<Ok<Unit>>());
  });

  test('sendPing error reason maps to ChannelFailure', () async {
    build();
    when(() => channel.ping(any())).thenAnswer(
      (_) async => const ChannelReply('error', <String, dynamic>{
        'reason': 'invalid_telemetry',
      }),
    );
    final res = await sut.sendPing(ping);
    expect((res as Err<Unit>).failure, isA<ChannelFailure>());
  });

  test('sendPing ChannelException maps to NetworkFailure', () async {
    build();
    when(() => channel.ping(any())).thenThrow(const ChannelException('x'));
    final res = await sut.sendPing(ping);
    expect((res as Err<Unit>).failure, isA<NetworkFailure>());
  });

  test('setStatus ok maps to Ok', () async {
    build();
    when(
      () => channel.setStatus(any()),
    ).thenAnswer((_) async => const ChannelReply('ok', <String, dynamic>{}));
    expect(await sut.setStatus('online'), isA<Ok<Unit>>());
  });

  test('statusStream passes through the channel', () async {
    build();
    final Future<ConnectionStatus> first = sut.statusStream.first;
    statuses.add(ConnectionStatus.connected);
    expect(await first, ConnectionStatus.connected);
  });

  group('a refused socket', () {
    test('is reconnected with a renewed session, and nobody is signed out', () {
      fakeAsync((FakeAsync async) {
        build();
        renewsTo(const Ok<DriverSession>(renewed));
        bool expired = false;
        sut.sessionExpired.listen((_) => expired = true);

        unawaited(sut.connect(signedIn));
        refusals.add(null);
        async.flushMicrotasks();

        verify(
          () => channel.connect(renewed, wsBase: any(named: 'wsBase')),
        ).called(1);
        expect(expired, isFalse);
      });
    });

    test('signs the courier out when identity refuses the refresh token', () {
      fakeAsync((FakeAsync async) {
        build();
        renewsTo(const Err<DriverSession>(AuthFailure()));
        bool expired = false;
        sut.sessionExpired.listen((_) => expired = true);

        unawaited(sut.connect(signedIn));
        refusals.add(null);
        async.flushMicrotasks();

        expect(expired, isTrue);
        verifyNever(
          () => channel.connect(renewed, wsBase: any(named: 'wsBase')),
        );
      });
    });

    test('waits and tries again while identity cannot be reached', () {
      fakeAsync((FakeAsync async) {
        build();
        renewsTo(const Err<DriverSession>(NetworkFailure()));
        bool expired = false;
        sut.sessionExpired.listen((_) => expired = true);

        unawaited(sut.connect(signedIn));
        refusals.add(null);
        async.flushMicrotasks();
        verify(() => renewer.renew()).called(1);

        renewsTo(const Ok<DriverSession>(renewed));
        async.elapse(const Duration(seconds: 1));

        verify(() => renewer.renew()).called(1);
        verify(
          () => channel.connect(renewed, wsBase: any(named: 'wsBase')),
        ).called(1);
        expect(expired, isFalse);
      });
    });

    test('backs off, longer each time, up to the ceiling', () {
      fakeAsync((FakeAsync async) {
        build();
        renewsTo(const Err<DriverSession>(NetworkFailure()));

        unawaited(sut.connect(signedIn));
        refusals.add(null);
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 1))
          ..elapse(const Duration(seconds: 2))
          ..elapse(const Duration(seconds: 4));
        clearInteractions(renewer);

        async.elapse(const Duration(seconds: 7));
        verifyNever(() => renewer.renew());

        async.elapse(const Duration(seconds: 1));
        verify(() => renewer.renew()).called(1);

        async.elapse(const Duration(minutes: 5));
        verify(() => renewer.renew()).called(10);
      });
    });

    test(
      'again, right after a renewal, is a real refusal: the courier is signed out',
      () {
        fakeAsync((FakeAsync async) {
          build();
          renewsTo(const Ok<DriverSession>(renewed));
          bool expired = false;
          sut.sessionExpired.listen((_) => expired = true);

          unawaited(sut.connect(signedIn));
          refusals.add(null);
          async.flushMicrotasks();
          refusals.add(null);
          async.flushMicrotasks();

          expect(expired, isTrue);
          verify(() => renewer.renew()).called(1);
        });
      },
    );

    test('after a connection that held, is renewed again', () {
      fakeAsync((FakeAsync async) {
        build();
        renewsTo(const Ok<DriverSession>(renewed));
        bool expired = false;
        sut.sessionExpired.listen((_) => expired = true);

        unawaited(sut.connect(signedIn));
        refusals.add(null);
        async.flushMicrotasks();
        statuses.add(ConnectionStatus.connected);
        async.flushMicrotasks();
        refusals.add(null);
        async.flushMicrotasks();

        expect(expired, isFalse);
        verify(() => renewer.renew()).called(2);
      });
    });

    test('is left alone once the courier has disconnected', () {
      fakeAsync((FakeAsync async) {
        build();
        renewsTo(const Err<DriverSession>(NetworkFailure()));

        unawaited(sut.connect(signedIn));
        refusals.add(null);
        async.flushMicrotasks();
        unawaited(sut.disconnect());
        clearInteractions(renewer);

        async.elapse(const Duration(minutes: 1));
        refusals.add(null);
        async.flushMicrotasks();

        verifyNever(() => renewer.renew());
      });
    });

    test('is recovered at once when the app comes back to the foreground', () {
      fakeAsync((FakeAsync async) {
        build();
        renewsTo(const Err<DriverSession>(NetworkFailure()));

        unawaited(sut.connect(signedIn));
        refusals.add(null);
        async.flushMicrotasks();
        renewsTo(const Ok<DriverSession>(renewed));

        sut.onResume();
        async.flushMicrotasks();

        verify(
          () => channel.connect(renewed, wsBase: any(named: 'wsBase')),
        ).called(1);
        verifyNever(() => channel.reconnectNow());
      });
    });
  });

  test('onResume triggers reconnectNow', () {
    build();
    sut.onResume();
    verify(() => channel.reconnectNow()).called(1);
  });

  test('connect delegates to the channel with a wsBase', () async {
    build();
    when(
      () => channel.connect(any(), wsBase: any(named: 'wsBase')),
    ).thenAnswer((_) async {});
    await sut.connect(
      const DriverSession(driverId: DriverId(1), token: 't', refreshToken: 'r'),
    );
    verify(
      () => channel.connect(any(), wsBase: any(named: 'wsBase')),
    ).called(1);
  });
}

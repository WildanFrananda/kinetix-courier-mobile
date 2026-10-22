import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/connection_repository_impl.dart';
import 'package:fleet_pulse_mobile/services/auth/fleet_standing.dart';
import 'package:fleet_pulse_mobile/services/auth/session_renewer.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/state/session_end.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChannel extends Mock implements ChannelClient {}

class _MockRenewer extends Mock implements SessionRenewer {}

class _MockFleet extends Mock implements FleetStanding {}

void main() {
  late _MockChannel channel;
  late _MockRenewer renewer;
  late _MockFleet fleet;
  late StreamController<void> refusals;
  late StreamController<void> notApproved;
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
  const DriverProfile approved = DriverProfile(
    id: DriverId(1),
    vehiclePlate: 'B 1 ABC',
    capacityKg: 100,
    status: 'offline',
    active: true,
  );

  setUpAll(() {
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
    notApproved = new StreamController<void>.broadcast();
    statuses = new StreamController<ConnectionStatus>.broadcast();
    when(() => channel.refused).thenAnswer((_) => refusals.stream);
    when(() => channel.notApproved).thenAnswer((_) => notApproved.stream);
    when(() => channel.statusStream).thenAnswer((_) => statuses.stream);
    sut = new ConnectionRepositoryImpl(channel, renewer, fleet);
  }

  setUp(() {
    channel = new _MockChannel();
    renewer = new _MockRenewer();
    fleet = new _MockFleet();
    when(
      () => channel.connect(any(), wsBase: any(named: 'wsBase')),
    ).thenAnswer((_) async {});
    when(() => channel.disconnect()).thenAnswer((_) async {});
  });

  tearDown(() {
    unawaited(sut.dispose());
    unawaited(refusals.close());
    unawaited(notApproved.close());
    unawaited(statuses.close());
  });

  void renewsTo(Result<DriverSession> result) {
    when(() => renewer.renew()).thenAnswer((_) async => result);
  }

  void standsAs(Result<DriverProfile> result) {
    when(() => fleet.check(any())).thenAnswer((_) async => result);
  }

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
        final List<SessionEnd> ended = <SessionEnd>[];
        sut.sessionEnded.listen(ended.add);

        unawaited(sut.connect(signedIn));
        refusals.add(null);
        async.flushMicrotasks();

        verify(
          () => channel.connect(renewed, wsBase: any(named: 'wsBase')),
        ).called(1);
        expect(ended, isEmpty);
      });
    });

    test('signs the courier out when identity refuses the refresh token', () {
      fakeAsync((FakeAsync async) {
        build();
        renewsTo(const Err<DriverSession>(AuthFailure()));
        final List<SessionEnd> ended = <SessionEnd>[];
        sut.sessionEnded.listen(ended.add);

        unawaited(sut.connect(signedIn));
        refusals.add(null);
        async.flushMicrotasks();

        expect(ended.single, isA<SessionSignedOut>());
        verifyNever(
          () => channel.connect(renewed, wsBase: any(named: 'wsBase')),
        );
      });
    });

    test('waits and tries again while identity cannot be reached', () {
      fakeAsync((FakeAsync async) {
        build();
        renewsTo(const Err<DriverSession>(NetworkFailure()));
        final List<SessionEnd> ended = <SessionEnd>[];
        sut.sessionEnded.listen(ended.add);

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
        expect(ended, isEmpty);
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
      'again right after a renewal asks the fleet why, and a pending courier is sent to wait for approval',
      () {
        fakeAsync((FakeAsync async) {
          build();
          renewsTo(const Ok<DriverSession>(renewed));
          standsAs(const Err<DriverProfile>(PendingApprovalFailure()));
          final List<SessionEnd> ended = <SessionEnd>[];
          sut.sessionEnded.listen(ended.add);

          unawaited(sut.connect(signedIn));
          refusals.add(null);
          async.flushMicrotasks();
          refusals.add(null);
          async.flushMicrotasks();

          expect(ended.single, isA<SessionNotApproved>());
          verify(() => renewer.renew()).called(1);
          verify(() => fleet.check('access-2')).called(1);
        });
      },
    );

    for (final Failure refusal in <Failure>[
      const AuthFailure(),
      const RegistrationIncompleteFailure(),
    ]) {
      test(
        'again right after a renewal, with the fleet answering ${refusal.runtimeType}, signs the courier out',
        () {
          fakeAsync((FakeAsync async) {
            build();
            renewsTo(const Ok<DriverSession>(renewed));
            standsAs(new Err<DriverProfile>(refusal));
            final List<SessionEnd> ended = <SessionEnd>[];
            sut.sessionEnded.listen(ended.add);

            unawaited(sut.connect(signedIn));
            refusals.add(null);
            async.flushMicrotasks();
            refusals.add(null);
            async.flushMicrotasks();

            expect(ended.single, isA<SessionSignedOut>());
          });
        },
      );
    }

    test(
      'again right after a renewal, while the fleet cannot be asked, is retried and nobody is signed out',
      () {
        fakeAsync((FakeAsync async) {
          build();
          renewsTo(const Ok<DriverSession>(renewed));
          standsAs(const Err<DriverProfile>(NetworkFailure()));
          final List<SessionEnd> ended = <SessionEnd>[];
          sut.sessionEnded.listen(ended.add);

          unawaited(sut.connect(signedIn));
          refusals.add(null);
          async.flushMicrotasks();
          refusals.add(null);
          async.flushMicrotasks();
          clearInteractions(channel);

          async.elapse(const Duration(seconds: 1));

          verify(
            () => channel.connect(renewed, wsBase: any(named: 'wsBase')),
          ).called(1);
          expect(ended, isEmpty);
        });
      },
    );

    test(
      'again right after a renewal, with the fleet saying the courier may drive, is retried',
      () {
        fakeAsync((FakeAsync async) {
          build();
          renewsTo(const Ok<DriverSession>(renewed));
          standsAs(const Ok<DriverProfile>(approved));
          final List<SessionEnd> ended = <SessionEnd>[];
          sut.sessionEnded.listen(ended.add);

          unawaited(sut.connect(signedIn));
          refusals.add(null);
          async.flushMicrotasks();
          refusals.add(null);
          async
            ..flushMicrotasks()
            ..elapse(const Duration(seconds: 1));

          expect(ended, isEmpty);
          verify(() => renewer.renew()).called(1);
        });
      },
    );

    test('after a connection that held, is renewed again', () {
      fakeAsync((FakeAsync async) {
        build();
        renewsTo(const Ok<DriverSession>(renewed));
        final List<SessionEnd> ended = <SessionEnd>[];
        sut.sessionEnded.listen(ended.add);

        unawaited(sut.connect(signedIn));
        refusals.add(null);
        async.flushMicrotasks();
        statuses.add(ConnectionStatus.connected);
        async.flushMicrotasks();
        refusals.add(null);
        async.flushMicrotasks();

        expect(ended, isEmpty);
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

  test(
    'a join refused as pending approval sends the courier to wait, without renewing',
    () {
      fakeAsync((FakeAsync async) {
        build();
        final List<SessionEnd> ended = <SessionEnd>[];
        sut.sessionEnded.listen(ended.add);

        unawaited(sut.connect(signedIn));
        notApproved.add(null);
        async.flushMicrotasks();

        expect(ended.single, isA<SessionNotApproved>());
        verifyNever(() => renewer.renew());
      });
    },
  );

  test('onResume triggers reconnectNow', () {
    build();
    sut.onResume();
    verify(() => channel.reconnectNow()).called(1);
  });

  test('connect delegates to the channel with a wsBase', () async {
    build();
    await sut.connect(
      const DriverSession(driverId: DriverId(1), token: 't', refreshToken: 'r'),
    );
    verify(
      () => channel.connect(any(), wsBase: any(named: 'wsBase')),
    ).called(1);
  });
}

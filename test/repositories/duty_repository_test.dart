import 'dart:async';
import 'dart:collection';

import 'package:fake_async/fake_async.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/duty_repository_impl.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_exception.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_reply.dart';
import 'package:fleet_pulse_mobile/services/location/location_service.dart';
import 'package:fleet_pulse_mobile/services/offline/offline_position_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocation extends Mock implements LocationService {}

class _MockChannel extends Mock implements ChannelClient {}

const DriverId _courier = DriverId(1);

class _MemoryStore implements OfflinePositionStore {
  final Map<DriverId, SplayTreeMap<int, TelemetryPing>> owners =
      <DriverId, SplayTreeMap<int, TelemetryPing>>{};

  SplayTreeMap<int, TelemetryPing> get entries => of(_courier);

  SplayTreeMap<int, TelemetryPing> of(DriverId owner) =>
      owners.putIfAbsent(owner, SplayTreeMap<int, TelemetryPing>.new);

  @override
  int get capacity => OfflinePositionStore.defaultCapacity;

  @override
  Future<int> count() async => owners.values.fold<int>(
    0,
    (int total, SplayTreeMap<int, TelemetryPing> kept) => total + kept.length,
  );

  @override
  Future<void> add(DriverId owner, TelemetryPing ping) async {
    of(owner)[ping.recordedAt.microsecondsSinceEpoch] = ping;
  }

  @override
  Future<List<TelemetryPing>> oldest(DriverId owner, int limit) async =>
      of(owner).values.take(limit).toList();

  @override
  Future<void> remove(DriverId owner, Iterable<TelemetryPing> pings) async {
    for (final TelemetryPing ping in pings) {
      of(owner).remove(ping.recordedAt.microsecondsSinceEpoch);
    }
  }

  @override
  Future<int> discardRecordedBefore(DateTime cutoff) async {
    int discarded = 0;

    for (final SplayTreeMap<int, TelemetryPing> kept in owners.values) {
      final int before = kept.length;

      kept.removeWhere(
        (int key, TelemetryPing _) => key < cutoff.microsecondsSinceEpoch,
      );
      discarded += before - kept.length;
    }

    return discarded;
  }
}

final DateTime _fixTime = DateTime.utc(2026, 10, 21, 8);
final DateTime _now = _fixTime.add(const Duration(minutes: 1));

void inFakeTime(void Function(FakeAsync async) body) {
  fakeAsync(body, initialTime: _now);
}

Position _pos(double lat, double lng, {DateTime? at}) => new Position(
  latitude: lat,
  longitude: lng,
  timestamp: at ?? _fixTime,
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 90,
  headingAccuracy: 1,
  speed: 10,
  speedAccuracy: 1,
);

ChannelReply _status(String status) =>
    new ChannelReply('ok', <String, dynamic>{'status': status});

ChannelReply _refusal(String reason) =>
    new ChannelReply('error', <String, dynamic>{'reason': reason});

const ChannelReply _ok = ChannelReply('ok', <String, dynamic>{});

ChannelReply _settled(int count) => new ChannelReply('ok', <String, dynamic>{
  'stored': <int>[for (int i = 0; i < count; i++) i],
  'duplicates': <int>[],
  'refused': <Map<String, dynamic>>[],
});

void main() {
  late _MockLocation location;
  late _MockChannel channel;
  late StreamController<Position> positions;
  late StreamController<ConnectionStatus> connection;
  late ConnectionStatus connected;
  late _MemoryStore offline;
  late DutyRepositoryImpl sut;

  setUpAll(() {
    registerFallbackValue(
      new TelemetryPing(latitude: 0, longitude: 0, recordedAt: _fixTime),
    );
    registerFallbackValue(<TelemetryPing>[]);
    registerFallbackValue(_courier);
  });

  setUp(() {
    location = new _MockLocation();
    channel = new _MockChannel();
    positions = new StreamController<Position>.broadcast();
    connection = new StreamController<ConnectionStatus>.broadcast();
    connected = ConnectionStatus.connected;
    offline = new _MemoryStore();

    when(
      () => location.ensurePermission(background: any(named: 'background')),
    ).thenAnswer((_) async => LocationPermissionStatus.granted);
    when(
      () => location.requestNotificationPermission(),
    ).thenAnswer((_) async {});
    when(() => location.positions()).thenAnswer((_) => positions.stream);
    when(() => channel.statusStream).thenAnswer((_) => connection.stream);
    when(() => channel.status).thenAnswer((_) => connected);
    when(() => channel.joinStatus).thenReturn('offline');
    when(() => channel.driverId).thenReturn(_courier);
    when(() => channel.setStatus(any())).thenAnswer(
      (Invocation i) async => _status(i.positionalArguments.first as String),
    );
    when(() => channel.ping(any())).thenAnswer((_) async => _ok);
    when(() => channel.pingBatch(any(), any())).thenAnswer(
      (Invocation i) async =>
          _settled((i.positionalArguments[1] as List<TelemetryPing>).length),
    );
  });

  void build() {
    sut = new DutyRepositoryImpl(location, channel, offline);
  }

  tearDown(() async {
    await sut.dispose();
    await positions.close();
    await connection.close();
  });

  List<TelemetryPing> sentPings() =>
      verify(() => channel.ping(captureAny())).captured.cast<TelemetryPing>();

  test('a refused location permission keeps the courier off duty', () async {
    when(
      () => location.ensurePermission(background: any(named: 'background')),
    ).thenAnswer((_) async => LocationPermissionStatus.denied);
    build();

    final Result<DriverAvailability> res = await sut.goOnDuty();

    expect((res as Err<DriverAvailability>).failure, isA<PermissionFailure>());
    expect(sut.onDuty, isFalse);
    verifyNever(() => channel.setStatus(any()));
  });

  test(
    'going on duty says online, then sends the first fix at once, stamped with its own time',
    () {
      inFakeTime((FakeAsync async) {
        build();
        Result<DriverAvailability>? res;
        sut.goOnDuty().then((Result<DriverAvailability> r) => res = r).ignore();
        async.flushMicrotasks();

        expect(res, isA<Ok<DriverAvailability>>());
        verify(() => channel.setStatus('online')).called(1);
        verifyNever(() => channel.ping(any()));

        positions.add(_pos(-6.2, 106.8));
        async.flushMicrotasks();

        final TelemetryPing ping = sentPings().single;
        expect(ping.recordedAt, _fixTime);
        expect(ping.latitude, -6.2);
      });
    },
  );

  test('the first fix is sent even when the courier has not moved', () {
    inFakeTime((FakeAsync async) {
      build();
      positions.add(_pos(-6.2, 106.8));
      sut.goOnDuty().ignore();
      async.flushMicrotasks();
      positions.add(_pos(-6.2, 106.8));
      async.flushMicrotasks();

      expect(sentPings(), hasLength(1));

      async.elapse(const Duration(seconds: 8));
      verifyNever(() => channel.ping(any()));
    });
  });

  test('the availability is what the server decided, not what was asked', () {
    inFakeTime((FakeAsync async) {
      build();
      when(
        () => channel.setStatus('online'),
      ).thenAnswer((_) async => _status('busy'));
      final List<DriverAvailability> seen = <DriverAvailability>[];
      sut.availability.listen(seen.add);
      Result<DriverAvailability>? res;

      sut.goOnDuty().then((Result<DriverAvailability> r) => res = r).ignore();
      async.flushMicrotasks();

      expect((res! as Ok<DriverAvailability>).value, DriverAvailability.busy);
      expect(seen, <DriverAvailability>[DriverAvailability.busy]);
    });
  });

  test('a status the server refuses leaves the courier off duty', () {
    inFakeTime((FakeAsync async) {
      build();
      when(
        () => channel.setStatus('online'),
      ).thenAnswer((_) async => _refusal('invalid_status'));
      Result<DriverAvailability>? res;

      sut.goOnDuty().then((Result<DriverAvailability> r) => res = r).ignore();
      async.flushMicrotasks();
      positions.add(_pos(-6.2, 106.8));
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 8));

      expect((res! as Err<DriverAvailability>).failure, isA<ChannelFailure>());
      expect(sut.onDuty, isFalse);
      verifyNever(() => channel.ping(any()));
    });
  });

  test(
    'going on duty while the socket is down says online once it connects, then pings',
    () {
      inFakeTime((FakeAsync async) {
        build();
        connected = ConnectionStatus.reconnecting;
        when(
          () => channel.setStatus(any()),
        ).thenThrow(const ChannelException('not connected'));
        Result<DriverAvailability>? res;

        sut.goOnDuty().then((Result<DriverAvailability> r) => res = r).ignore();
        async.flushMicrotasks();
        positions.add(_pos(-6.2, 106.8));
        async.flushMicrotasks();

        expect(
          (res! as Err<DriverAvailability>).failure,
          isA<NetworkFailure>(),
        );
        expect(sut.onDuty, isTrue);
        verifyNever(() => channel.ping(any()));
        clearInteractions(channel);

        when(
          () => channel.setStatus(any()),
        ).thenAnswer((_) async => _status('online'));
        connected = ConnectionStatus.connected;
        connection.add(ConnectionStatus.connected);
        async.flushMicrotasks();

        verify(() => channel.setStatus('online')).called(1);
        expect(sentPings(), hasLength(1));
      });
    },
  );

  test(
    'every reconnect while on duty says online again and sends a fix, moved or not',
    () {
      inFakeTime((FakeAsync async) {
        build();
        sut.goOnDuty().ignore();
        async.flushMicrotasks();
        positions.add(_pos(-6.2, 106.8));
        async.flushMicrotasks();
        clearInteractions(channel);

        connected = ConnectionStatus.reconnecting;
        connection.add(ConnectionStatus.reconnecting);
        async.flushMicrotasks();
        connected = ConnectionStatus.connected;
        connection.add(ConnectionStatus.connected);
        async.flushMicrotasks();

        verify(() => channel.setStatus('online')).called(1);
        expect(sentPings(), hasLength(1));
      });
    },
  );

  test('a status reply that was lost is asked again on the next tick', () {
    inFakeTime((FakeAsync async) {
      build();
      when(
        () => channel.setStatus(any()),
      ).thenThrow(const ChannelException('push "status" timed out'));
      sut.goOnDuty().ignore();
      async.flushMicrotasks();
      positions.add(_pos(-6.2, 106.8));
      async.flushMicrotasks();
      verifyNever(() => channel.ping(any()));

      when(
        () => channel.setStatus(any()),
      ).thenAnswer((_) async => _status('online'));
      async.elapse(DutyRepositoryImpl.cadence);

      verify(() => channel.setStatus('online')).called(2);
      expect(sentPings(), hasLength(1));
    });
  });

  test('off duty, a join that finds the courier online is set offline', () {
    inFakeTime((FakeAsync async) {
      build();
      when(() => channel.joinStatus).thenReturn('online');

      connection.add(ConnectionStatus.connected);
      async.flushMicrotasks();

      verify(() => channel.setStatus('offline')).called(1);
    });
  });

  test('off duty, a join that finds the courier offline sends nothing', () {
    inFakeTime((FakeAsync async) {
      build();
      connection.add(ConnectionStatus.connected);
      async.flushMicrotasks();

      verifyNever(() => channel.setStatus(any()));
    });
  });

  test('pings each cadence while moving, never while standing still', () {
    inFakeTime((FakeAsync async) {
      build();
      sut.goOnDuty().ignore();
      async.flushMicrotasks();
      positions.add(_pos(-6.20, 106.80));
      async.flushMicrotasks();
      clearInteractions(channel);

      positions.add(_pos(-6.30, 106.90));
      async
        ..flushMicrotasks()
        ..elapse(DutyRepositoryImpl.cadence);
      verify(() => channel.ping(any())).called(1);

      positions.add(_pos(-6.300001, 106.900001));
      async
        ..flushMicrotasks()
        ..elapse(DutyRepositoryImpl.cadence);
      verifyNever(() => channel.ping(any()));
    });
  });

  test('a rate-limited ping pauses telemetry for the window', () {
    inFakeTime((FakeAsync async) {
      build();
      sut.goOnDuty().ignore();
      async.flushMicrotasks();
      when(
        () => channel.ping(any()),
      ).thenAnswer((_) async => _refusal('rate_limited'));
      positions.add(_pos(-6.20, 106.80));
      async.flushMicrotasks();
      clearInteractions(channel);
      when(() => channel.ping(any())).thenAnswer((_) async => _ok);

      positions.add(_pos(-6.30, 106.90));
      async
        ..flushMicrotasks()
        ..elapse(DutyRepositoryImpl.cadence)
        ..elapse(DutyRepositoryImpl.cadence);
      verifyNever(() => channel.ping(any()));

      async.elapse(DutyRepositoryImpl.cadence);
      verify(() => channel.ping(any())).called(1);
    });
  });

  test('a fix taken during a rate-limited pause is kept for the batch', () {
    inFakeTime((FakeAsync async) {
      build();
      sut.goOnDuty().ignore();
      async.flushMicrotasks();
      when(
        () => channel.ping(any()),
      ).thenAnswer((_) async => _refusal('rate_limited'));
      positions.add(_pos(-6.20, 106.80));
      async.flushMicrotasks();
      when(() => channel.ping(any())).thenAnswer((_) async => _ok);

      final DateTime paused = _fixTime.add(const Duration(seconds: 4));
      positions.add(_pos(-6.30, 106.90, at: paused));
      async
        ..flushMicrotasks()
        ..elapse(DutyRepositoryImpl.cadence);

      expect(offline.entries.values.single.recordedAt, paused);
    });
  });

  test('going on duty with no courier on the socket is refused', () async {
    when(() => channel.driverId).thenReturn(null);
    build();

    final Result<DriverAvailability> res = await sut.goOnDuty();

    expect((res as Err<DriverAvailability>).failure, isA<NetworkFailure>());
    expect(sut.onDuty, isFalse);
    verifyNever(() => location.positions());
  });

  test('a fix refused as invalid is reported and not sent again', () {
    inFakeTime((FakeAsync async) {
      build();
      final List<Failure> problems = <Failure>[];
      sut.problems.listen(problems.add);
      when(
        () => channel.ping(any()),
      ).thenAnswer((_) async => _refusal('invalid_telemetry'));

      sut.goOnDuty().ignore();
      async.flushMicrotasks();
      positions.add(_pos(-6.20, 106.80));
      async
        ..flushMicrotasks()
        ..elapse(DutyRepositoryImpl.cadence)
        ..elapse(DutyRepositoryImpl.cadence);

      verify(() => channel.ping(any())).called(1);
      expect((problems.single as ChannelFailure).reason, 'invalid_telemetry');
    });
  });

  test(
    'a ping that could not be delivered is kept for the batch, never resent live',
    () {
      inFakeTime((FakeAsync async) {
        build();
        sut.goOnDuty().ignore();
        async.flushMicrotasks();
        when(
          () => channel.ping(any()),
        ).thenThrow(const ChannelException('push "ping" timed out'));
        positions.add(_pos(-6.20, 106.80, at: _fixTime));
        async.flushMicrotasks();
        when(() => channel.ping(any())).thenAnswer((_) async => _ok);
        clearInteractions(channel);

        expect(offline.entries.values.single.recordedAt, _fixTime);

        final DateTime later = _fixTime.add(const Duration(seconds: 4));
        positions.add(_pos(-6.30, 106.90, at: later));
        async
          ..flushMicrotasks()
          ..elapse(DutyRepositoryImpl.cadence);

        final List<TelemetryPing> live = sentPings();
        expect(live, hasLength(1));
        expect(live.single.recordedAt, later);
        final List<TelemetryPing> batch =
            verify(() => channel.pingBatch(any(), captureAny())).captured.single
                as List<TelemetryPing>;
        expect(batch.single.recordedAt, _fixTime);
        expect(offline.entries, isEmpty);
      });
    },
  );

  test('going off duty says offline and stops tracking', () {
    inFakeTime((FakeAsync async) {
      build();
      sut.goOnDuty().ignore();
      async.flushMicrotasks();
      positions.add(_pos(-6.20, 106.80));
      async.flushMicrotasks();
      clearInteractions(channel);

      Result<DriverAvailability>? res;
      sut.goOffDuty().then((Result<DriverAvailability> r) => res = r).ignore();
      async.flushMicrotasks();

      expect(
        (res! as Ok<DriverAvailability>).value,
        DriverAvailability.offline,
      );
      expect(sut.onDuty, isFalse);
      expect(positions.hasListener, isFalse);
      verify(() => channel.setStatus('offline')).called(1);

      positions.add(_pos(-6.30, 106.90));
      async.elapse(const Duration(seconds: 12));
      verifyNever(() => channel.ping(any()));
    });
  });

  test('going off duty while disconnected needs no server answer', () async {
    connected = ConnectionStatus.reconnecting;
    build();

    final Result<DriverAvailability> res = await sut.goOffDuty();

    expect((res as Ok<DriverAvailability>).value, DriverAvailability.offline);
    verifyNever(() => channel.setStatus(any()));
  });

  group('the offline queue', () {
    final DateTime queuedFrom = _fixTime.subtract(const Duration(minutes: 30));

    TelemetryPing queuedAt(int seconds) => new TelemetryPing(
      latitude: -6.2,
      longitude: 106.8,
      recordedAt: queuedFrom.add(new Duration(seconds: seconds)),
    );

    void keep(Iterable<int> seconds) {
      for (final int second in seconds) {
        offline.entries[queuedAt(second).recordedAt.microsecondsSinceEpoch] =
            queuedAt(second);
      }
    }

    List<List<TelemetryPing>> batchesSent() => verify(
      () => channel.pingBatch(any(), captureAny()),
    ).captured.cast<List<TelemetryPing>>();

    List<int> secondsOf(List<TelemetryPing> batch) => <int>[
      for (final TelemetryPing ping in batch)
        ping.recordedAt.difference(queuedFrom).inSeconds,
    ];

    void goOnDutyWithAFix(FakeAsync async) {
      build();
      sut.goOnDuty().ignore();
      async.flushMicrotasks();
      positions.add(_pos(-6.2, 106.8));
      async.flushMicrotasks();
    }

    test('a fix taken while the socket is down is kept, once per place', () {
      inFakeTime((FakeAsync async) {
        connected = ConnectionStatus.reconnecting;
        when(
          () => channel.setStatus(any()),
        ).thenThrow(const ChannelException('not connected'));
        build();
        sut.goOnDuty().ignore();
        async.flushMicrotasks();

        positions.add(_pos(-6.20, 106.80));
        async.elapse(DutyRepositoryImpl.cadence);
        positions.add(
          _pos(-6.20, 106.80, at: _fixTime.add(const Duration(seconds: 4))),
        );
        async.elapse(DutyRepositoryImpl.cadence);
        positions.add(
          _pos(-6.30, 106.90, at: _fixTime.add(const Duration(seconds: 8))),
        );
        async.elapse(DutyRepositoryImpl.cadence);

        expect(offline.entries, hasLength(2));
        verifyNever(() => channel.ping(any()));
        verifyNever(() => channel.pingBatch(any(), any()));
      });
    });

    test(
      'goes after the join, status online and the fresh fix, oldest first, and never as a live ping',
      () {
        inFakeTime((FakeAsync async) {
          keep(<int>[20, 0, 10]);
          final List<String> order = <String>[];
          when(() => channel.setStatus(any())).thenAnswer((_) async {
            order.add('status');

            return _status('online');
          });
          when(() => channel.ping(any())).thenAnswer((_) async {
            order.add('ping');

            return _ok;
          });
          when(() => channel.pingBatch(any(), any())).thenAnswer((_) async {
            order.add('ping_batch');

            return _settled(3);
          });

          goOnDutyWithAFix(async);

          expect(order, <String>['status', 'ping', 'ping_batch']);
          expect(secondsOf(batchesSent().single), <int>[0, 10, 20]);
          expect(sentPings().single.recordedAt, _fixTime);
          expect(offline.entries, isEmpty);
        });
      },
    );

    test('a long queue goes in batches of at most 100, one at a time', () {
      inFakeTime((FakeAsync async) {
        keep(<int>[for (int i = 0; i < 250; i++) i]);
        final List<Completer<ChannelReply>> replies =
            <Completer<ChannelReply>>[];
        when(() => channel.pingBatch(any(), any())).thenAnswer((_) {
          final Completer<ChannelReply> reply = new Completer<ChannelReply>();
          replies.add(reply);

          return reply.future;
        });

        goOnDutyWithAFix(async);
        positions.add(
          _pos(-6.30, 106.90, at: _fixTime.add(const Duration(seconds: 4))),
        );
        async.elapse(DutyRepositoryImpl.cadence);

        expect(replies, hasLength(1));

        replies[0].complete(_settled(100));
        async.elapse(
          DutyRepositoryImpl.batchSpacing - const Duration(milliseconds: 1),
        );
        expect(replies, hasLength(1));
        async.elapse(const Duration(milliseconds: 1));
        expect(replies, hasLength(2));

        replies[1].complete(_settled(100));
        async.elapse(DutyRepositoryImpl.batchSpacing);
        replies[2].complete(_settled(50));
        async.elapse(DutyRepositoryImpl.batchSpacing * 4);

        final List<List<TelemetryPing>> batches = batchesSent();
        expect(batches.map((List<TelemetryPing> b) => b.length), <int>[
          100,
          100,
          50,
        ]);
        expect(secondsOf(batches[1]).first, 100);
        expect(secondsOf(batches[2]).last, 249);
        expect(offline.entries, isEmpty);
      });
    });

    test('an ok reply settles the whole batch, refused entries included', () {
      inFakeTime((FakeAsync async) {
        keep(<int>[0, 10, 20]);
        when(() => channel.pingBatch(any(), any())).thenAnswer(
          (_) async => const ChannelReply('ok', <String, dynamic>{
            'stored': <int>[0],
            'duplicates': <int>[1],
            'refused': <Map<String, dynamic>>[
              <String, dynamic>{'index': 2, 'reason': 'too_old'},
            ],
          }),
        );

        goOnDutyWithAFix(async);
        async.elapse(DutyRepositoryImpl.batchSpacing * 2);

        expect(offline.entries, isEmpty);
        expect(batchesSent(), hasLength(1));
      });
    });

    test(
      'an error reply keeps the batch and tries again after a backoff, not before',
      () {
        inFakeTime((FakeAsync async) {
          keep(<int>[0, 10]);
          int calls = 0;
          when(() => channel.pingBatch(any(), any())).thenAnswer((_) async {
            calls++;

            return calls == 1 ? _refusal('unavailable') : _settled(2);
          });

          goOnDutyWithAFix(async);
          expect(calls, 1);
          expect(offline.entries, hasLength(2));

          positions.add(
            _pos(-6.30, 106.90, at: _fixTime.add(const Duration(seconds: 4))),
          );
          async.elapse(
            DutyRepositoryImpl.batchRetryFirst -
                const Duration(milliseconds: 1),
          );
          expect(calls, 1);

          async.elapse(const Duration(milliseconds: 1));
          expect(calls, 2);
          expect(offline.entries, isEmpty);
        });
      },
    );

    test('a rate-limited batch waits for the batch window', () {
      inFakeTime((FakeAsync async) {
        keep(<int>[0]);
        int calls = 0;
        when(() => channel.pingBatch(any(), any())).thenAnswer((_) async {
          calls++;

          return calls == 1 ? _refusal('rate_limited') : _settled(1);
        });

        goOnDutyWithAFix(async);
        async.elapse(
          DutyRepositoryImpl.batchRateLimitPause - const Duration(seconds: 1),
        );
        expect(calls, 1);
        expect(offline.entries, hasLength(1));

        async.elapse(const Duration(seconds: 1));
        expect(calls, 2);
        expect(offline.entries, isEmpty);
      });
    });

    test('a position older than a day is dropped here, never sent', () {
      inFakeTime((FakeAsync async) {
        final TelemetryPing stale = new TelemetryPing(
          latitude: -6.2,
          longitude: 106.8,
          recordedAt: _now.subtract(const Duration(hours: 25)),
        );
        offline.entries[stale.recordedAt.microsecondsSinceEpoch] = stale;
        keep(<int>[0]);

        goOnDutyWithAFix(async);

        expect(secondsOf(batchesSent().single), <int>[0]);
        expect(offline.entries, isEmpty);
      });
    });

    test('a disconnect stops the flush, and the next join resumes it', () {
      inFakeTime((FakeAsync async) {
        keep(<int>[for (int i = 0; i < 150; i++) i]);

        goOnDutyWithAFix(async);
        connected = ConnectionStatus.reconnecting;
        connection.add(ConnectionStatus.reconnecting);
        async.elapse(DutyRepositoryImpl.batchSpacing * 4);

        expect(batchesSent(), hasLength(1));
        expect(offline.entries, hasLength(50));

        connected = ConnectionStatus.connected;
        connection.add(ConnectionStatus.connected);
        async.flushMicrotasks();

        expect(batchesSent(), hasLength(1));
        expect(offline.entries, isEmpty);
      });
    });

    test(
      'refused entries are settled with the batch, and a clock ahead is told to the courier',
      () {
        inFakeTime((FakeAsync async) {
          keep(<int>[0, 10, 20]);
          final List<Failure> problems = <Failure>[];
          when(() => channel.pingBatch(any(), any())).thenAnswer(
            (_) async => const ChannelReply('ok', <String, dynamic>{
              'stored': <int>[0],
              'duplicates': <int>[],
              'refused': <Map<String, dynamic>>[
                <String, dynamic>{
                  'index': 1,
                  'reason': 'ahead_of_server_clock',
                },
                <String, dynamic>{'index': 2, 'reason': 'too_old'},
              ],
            }),
          );
          build();
          sut.problems.listen(problems.add);

          connection.add(ConnectionStatus.connected);
          async.flushMicrotasks();

          expect(offline.entries, isEmpty);
          expect(
            (problems.single as ChannelFailure).reason,
            'ahead_of_server_clock',
          );
        });
      },
    );

    test('only the positions of the courier on the socket are sent', () {
      inFakeTime((FakeAsync async) {
        final TelemetryPing theirs = queuedAt(5);
        offline.of(
          const DriverId(2),
        )[theirs.recordedAt.microsecondsSinceEpoch] = theirs;
        keep(<int>[0]);
        build();

        connection.add(ConnectionStatus.connected);
        async.flushMicrotasks();

        final List<dynamic> sent = verify(
          () => channel.pingBatch(captureAny(), captureAny()),
        ).captured;

        expect(sent[0], _courier);
        expect(secondsOf(sent[1] as List<TelemetryPing>), <int>[0]);
        expect(offline.of(const DriverId(2)), hasLength(1));
      });
    });

    test('off duty, a join with a queue sends it', () {
      inFakeTime((FakeAsync async) {
        keep(<int>[0, 10]);
        build();

        connection.add(ConnectionStatus.connected);
        async.flushMicrotasks();

        expect(secondsOf(batchesSent().single), <int>[0, 10]);
        verifyNever(() => channel.setStatus(any()));
      });
    });
  });
}

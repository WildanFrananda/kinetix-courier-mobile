import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/services/channel/channel_client.dart';
import 'package:kinetix_courier/services/channel/channel_event.dart';
import 'package:kinetix_courier/services/channel/channel_exception.dart';
import 'package:kinetix_courier/services/channel/channel_reply.dart';
import 'package:kinetix_courier/services/channel/channel_socket.dart';

class FakeSocket implements ChannelSocket {
  final StreamController<dynamic> _in = StreamController<dynamic>.broadcast();
  final List<String> sent = <String>[];
  final Completer<void> _ready = new Completer<void>();

  void completeReady() => _ready.complete();
  void emit(String frame) => _in.add(frame);

  @override
  Stream<dynamic> get stream => _in.stream;

  @override
  void add(String data) => sent.add(data);

  @override
  Future<void> get ready => _ready.future;

  @override
  Future<void> close() async {
    await _in.close();
  }
}

Future<void> pump([int times = 6]) async {
  for (int i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  const DriverSession session = DriverSession(
    driverId: DriverId(1),
    token: 'tok',
    refreshToken: 'refresh-tok',
  );

  final RegExp uuidv7Pattern = new RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  late FakeSocket fake;
  late ChannelClient client;

  setUp(() {
    fake = new FakeSocket()..completeReady();
    client = new ChannelClient.withConnector(
      (Uri uri, Map<String, dynamic> headers) => fake,
    );
  });

  tearDown(() => client.dispose());

  Map<String, dynamic> lastFrame() =>
      (jsonDecode(fake.sent.last) as Map<dynamic, dynamic>)
          .cast<String, dynamic>();

  void emitSnapshot({
    String dutyStatus = 'offline',
    Map<String, dynamic>? activeOrder,
    FakeSocket? on,
  }) {
    final FakeSocket target = on ?? fake;

    target.emit(
      jsonEncode(<String, dynamic>{
        'event': 'matching.job.snapshot',
        'eventId': '019a0000-0000-7000-8000-000000000001',
        'schemaVersion': 1,
        'orderId': activeOrder?['orderNumber'],
        'sequence': activeOrder?['eventSequence'],
        'occurredAt': '2026-11-16T00:00:00Z',
        'data': <String, dynamic>{
          'dutyStatus': dutyStatus,
          'activeOrder': activeOrder,
        },
      }),
    );
  }

  void ack(
    Map<String, dynamic> request, [
    Map<String, dynamic> data = const <String, dynamic>{},
    FakeSocket? on,
  ]) {
    final FakeSocket target = on ?? fake;
    final String event = request['event'] == 'system.ping'
        ? 'system.pong'
        : 'command.ack';

    target.emit(
      jsonEncode(<String, dynamic>{
        'event': event,
        'requestId': request['requestId'],
        'schemaVersion': 1,
        'occurredAt': '2026-11-16T00:00:00Z',
        'data': data,
      }),
    );
  }

  void commandError({
    String? requestId,
    required String reason,
    String code = 'ERROR',
    bool retryable = false,
  }) {
    fake.emit(
      jsonEncode(<String, dynamic>{
        'event': 'command.error',
        'requestId': requestId,
        'schemaVersion': 1,
        'occurredAt': '2026-11-16T00:00:00Z',
        'error': <String, dynamic>{
          'code': code,
          'reason': reason,
          'message': reason,
          'retryable': retryable,
        },
      }),
    );
  }

  Future<void> openConnected({String dutyStatus = 'offline'}) async {
    unawaited(client.connect(session, wsBase: 'wss://edge.test'));
    await pump();
    emitSnapshot(dutyStatus: dutyStatus);
    await pump();
  }

  test('the socket is the unified edge/matching events route without query params', () {
    expect(
      ChannelClient.socketUri('wss://edge.test').toString(),
      'wss://edge.test/ws/v1/events',
    );
  });

  test('the bearer token is placed in the upgrade Authorization header', () {
    expect(ChannelClient.headersFor('a.b.c'), <String, String>{
      'Authorization': 'Bearer a.b.c',
    });
  });

  test('connects on matching.job.snapshot without sending a join frame and emits the snapshot', () async {
    final List<ChannelEvent> received = <ChannelEvent>[];
    client.events.listen(received.add);

    await openConnected(dutyStatus: 'online');

    expect(fake.sent, isEmpty);
    expect(client.status, ConnectionStatus.connected);
    expect(client.joinStatus, 'online');
    expect(received, hasLength(1));
    expect(received.single.event, 'matching.job.snapshot');
    expect(received.single.payload['dutyStatus'], 'online');
    expect(received.single.eventId, '019a0000-0000-7000-8000-000000000001');
  });

  test('forbidden error during connect emits refused, stays disconnected', () async {
    bool refused = false;
    client.refused.listen((_) => refused = true);

    unawaited(client.connect(session, wsBase: 'wss://edge.test'));
    await pump();
    commandError(reason: 'forbidden', code: 'FORBIDDEN');
    await pump();

    expect(refused, isTrue);
    expect(client.status, ConnectionStatus.disconnected);
  });

  test(
    'a connect refused as pending approval says so, and does not reconnect',
    () async {
      bool notApproved = false;
      bool refused = false;
      client.notApproved.listen((_) => notApproved = true);
      client.refused.listen((_) => refused = true);

      unawaited(client.connect(session, wsBase: 'wss://edge.test'));
      await pump();
      commandError(reason: 'pending_approval', code: 'PENDING_APPROVAL');
      await pump();

      expect(notApproved, isTrue);
      expect(refused, isFalse);
      expect(client.status, ConnectionStatus.disconnected);
    },
  );

  test('a connect refused for an unknown reason is retried', () async {
    bool refused = false;
    client.refused.listen((_) => refused = true);

    unawaited(client.connect(session, wsBase: 'wss://edge.test'));
    await pump();
    commandError(reason: 'busy_node', code: 'UNAVAILABLE', retryable: true);
    await pump();

    expect(refused, isFalse);
    expect(client.status, ConnectionStatus.reconnecting);
  });

  test('command.ack is correlated by requestId and uses camelCase command envelope', () async {
    await openConnected();

    final Future<ChannelReply> replyFuture = client.setStatus('online');
    await pump();
    final Map<String, dynamic> frame = lastFrame();
    expect(frame['event'], 'courier.duty.set');
    expect(frame['schemaVersion'], 1);
    expect(frame['requestId'], matches(uuidv7Pattern));
    expect(frame['sentAt'], isA<String>());
    expect(frame['data'], <String, dynamic>{'status': 'online'});
    ack(frame, <String, dynamic>{'status': 'online'});

    final ChannelReply answered = await replyFuture;
    expect(answered.isOk, isTrue);
    expect(answered.response['status'], 'online');
  });

  test('command.error correlated by requestId resolves as error ChannelReply with reason', () async {
    await openConnected();

    final Future<ChannelReply> replyFuture = client.pickup(42);
    await pump();
    final Map<String, dynamic> frame = lastFrame();
    expect(frame['event'], 'matching.job.pickup');
    expect(frame['data'], <String, dynamic>{'orderId': 42});
    commandError(
      requestId: frame['requestId'] as String,
      reason: 'invalid_transition',
      code: 'INVALID_TRANSITION',
    );

    final ChannelReply answered = await replyFuture;
    expect(answered.isOk, isFalse);
    expect(answered.reason, 'invalid_transition');
  });

  test('a push before the snapshot arrives is not sent', () async {
    unawaited(client.connect(session, wsBase: 'wss://edge.test'));
    await pump();

    await expectLater(
      client.setStatus('online'),
      throwsA(isA<ChannelException>()),
    );
    expect(fake.sent, isEmpty);
  });

  test('an unreadable frame is dropped, the socket stays up', () async {
    await openConnected();

    fake.emit('not json');
    await pump();

    expect(client.status, ConnectionStatus.connected);
  });

  test(
    'positions kept offline go as courier.location.batch with camelCase ping fields',
    () async {
      await openConnected();

      unawaited(
        client
            .pingBatch(const DriverId(1), <TelemetryPing>[
              new TelemetryPing(
                latitude: -6.2,
                longitude: 106.8,
                recordedAt: DateTime.utc(2026, 10, 21, 8),
                speedKmh: 30,
              ),
              new TelemetryPing(
                latitude: -6.3,
                longitude: 106.9,
                recordedAt: DateTime.utc(2026, 10, 21, 8, 0, 4),
              ),
            ])
            .then((_) {}, onError: (Object _) {}),
      );
      await pump();

      final Map<String, dynamic> frame = lastFrame();
      expect(frame['event'], 'courier.location.batch');
      expect(frame['data'], <String, dynamic>{
        'pings': <Map<String, dynamic>>[
          <String, dynamic>{
            'latitude': -6.2,
            'longitude': 106.8,
            'recordedAt': '2026-10-21T08:00:00.000Z',
            'speedKmh': 30.0,
          },
          <String, dynamic>{
            'latitude': -6.3,
            'longitude': 106.9,
            'recordedAt': '2026-10-21T08:00:04.000Z',
          },
        ],
      });
    },
  );

  test('podUpload and delivered use camelCase event names and payload fields', () async {
    await openConnected();

    unawaited(
      client
          .podUpload(9, 'abc123')
          .then((_) {}, onError: (Object _) {}),
    );
    await pump();
    final Map<String, dynamic> uploadFrame = lastFrame();
    expect(uploadFrame['event'], 'matching.job.podUpload');
    expect(uploadFrame['data'], <String, dynamic>{
      'orderId': 9,
      'photoSha256': 'abc123',
    });

    unawaited(
      client
          .delivered(9, podPhotoUrl: 'https://cdn.test/p.jpg', podSignature: 'sig')
          .then((_) {}, onError: (Object _) {}),
    );
    await pump();
    final Map<String, dynamic> deliveredFrame = lastFrame();
    expect(deliveredFrame['event'], 'matching.job.delivered');
    expect(deliveredFrame['data'], <String, dynamic>{
      'orderId': 9,
      'podPhotoUrl': 'https://cdn.test/p.jpg',
      'podSignature': 'sig',
    });
  });

  test('a batch of another courier is never sent on this socket', () async {
    await openConnected();

    await expectLater(
      client.pingBatch(const DriverId(2), <TelemetryPing>[
        new TelemetryPing(
          latitude: -6.2,
          longitude: 106.8,
          recordedAt: DateTime.utc(2026, 10, 21, 8),
        ),
      ]),
      throwsA(isA<ChannelException>()),
    );
    expect(fake.sent, isEmpty);
  });

  test(
    'a session whose driver the fleet has not named opens no socket and is not approved',
    () async {
      bool notApproved = false;
      int opened = 0;
      final ChannelClient sut = new ChannelClient.withConnector((
        Uri uri,
        Map<String, dynamic> _,
      ) {
        opened++;

        return fake;
      });
      sut.notApproved.listen((_) => notApproved = true);

      await sut.connect(
        const DriverSession(
          driverId: null,
          token: 'tok',
          refreshToken: 'refresh-tok',
        ),
        wsBase: 'wss://edge.test',
      );
      await pump();

      expect(notApproved, isTrue);
      expect(opened, 0);
      expect(sut.status, ConnectionStatus.disconnected);
      await sut.dispose();
    },
  );

  group('a dead connection', () {
    late List<FakeSocket> opened;
    late ChannelClient sut;

    Map<String, dynamic> lastOn(FakeSocket socket) =>
        (jsonDecode(socket.sent.last) as Map<dynamic, dynamic>)
            .cast<String, dynamic>();

    void joined(FakeAsync async) {
      opened = <FakeSocket>[];
      sut = new ChannelClient.withConnector((Uri uri, Map<String, dynamic> _) {
        final FakeSocket socket = new FakeSocket()..completeReady();

        opened.add(socket);

        return socket;
      });
      sut.connect(session, wsBase: 'wss://edge.test').ignore();
      async.flushMicrotasks();
      emitSnapshot(on: opened.single);
      async.flushMicrotasks();
      expect(sut.status, ConnectionStatus.connected);
    }

    test('a heartbeat that is never answered reconnects', () {
      fakeAsync((FakeAsync async) {
        joined(async);

        async.elapse(const Duration(seconds: 30));
        expect(lastOn(opened.single)['event'], 'system.ping');

        async.elapse(const Duration(seconds: 15));

        expect(sut.status, isNot(ConnectionStatus.connected));
        sut.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test('an answered heartbeat keeps the connection', () {
      fakeAsync((FakeAsync async) {
        joined(async);

        async.elapse(const Duration(seconds: 30));
        ack(lastOn(opened.single), <String, dynamic>{
          'serverTime': '2026-11-16T00:00:30Z',
        }, opened.single);
        async.elapse(const Duration(seconds: 15));

        expect(sut.status, ConnectionStatus.connected);
        expect(opened, hasLength(1));
        sut.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test(
      'a push that times out probes the connection, and silence reconnects',
      () {
        fakeAsync((FakeAsync async) {
          joined(async);

          sut.setStatus('online').ignore();
          async.elapse(const Duration(seconds: 6));
          expect(lastOn(opened.single)['event'], 'system.ping');

          async.elapse(const Duration(seconds: 11));

          expect(sut.status, isNot(ConnectionStatus.connected));
          sut.dispose().ignore();
          async.flushMicrotasks();
        });
      },
    );
  });
}

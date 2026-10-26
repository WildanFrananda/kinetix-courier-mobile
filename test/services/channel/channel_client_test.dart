import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_exception.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_reply.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_socket.dart';
import 'package:flutter_test/flutter_test.dart';

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

  late FakeSocket fake;
  late ChannelClient client;

  setUp(() {
    fake = new FakeSocket()..completeReady();
    client = new ChannelClient.withConnector(
      (Uri uri, Iterable<String> protocols) => fake,
    );
  });

  tearDown(() => client.dispose());

  List<dynamic> lastFrame() => jsonDecode(fake.sent.last) as List<dynamic>;

  void reply(
    List<dynamic> frame,
    String status, [
    Map<String, dynamic> response = const <String, dynamic>{},
  ]) {
    fake.emit(
      jsonEncode(<dynamic>[
        frame[0],
        frame[1],
        frame[2],
        'phx_reply',
        <String, dynamic>{'status': status, 'response': response},
      ]),
    );
  }

  Future<List<dynamic>> joinFrame() async {
    unawaited(client.connect(session, wsBase: 'wss://edge.test'));
    await pump();

    return jsonDecode(fake.sent.single) as List<dynamic>;
  }

  test('the socket is the gateway route, with the protocol version', () {
    expect(
      ChannelClient.socketUri('wss://edge.test').toString(),
      'wss://edge.test/ws/v1/matching/driver?vsn=2.0.0',
    );
  });

  test('the token is offered beside phoenix, unpadded standard base64', () {
    final List<String> protocols = ChannelClient.protocolsFor('a.b.c');

    expect(protocols, <String>['phoenix', 'base64url.bearer.phx.YS5iLmM']);
  });

  test('joins driver topic and connects on ok reply', () async {
    final List<dynamic> join = await joinFrame();
    expect(join[2], 'driver:1');
    expect(join[3], 'phx_join');

    reply(join, 'ok', <String, dynamic>{'status': 'offline'});
    await pump();

    expect(client.status, ConnectionStatus.connected);
    expect(client.joinStatus, 'offline');
  });

  test('forbidden join emits refused, stays disconnected', () async {
    bool refused = false;
    client.refused.listen((_) => refused = true);

    reply(await joinFrame(), 'error', <String, dynamic>{'reason': 'forbidden'});
    await pump();

    expect(refused, isTrue);
    expect(client.status, ConnectionStatus.disconnected);
  });

  test(
    'a join refused as pending approval says so, and does not reconnect',
    () async {
      bool notApproved = false;
      bool refused = false;
      client.notApproved.listen((_) => notApproved = true);
      client.refused.listen((_) => refused = true);

      reply(await joinFrame(), 'error', <String, dynamic>{
        'reason': 'pending_approval',
      });
      await pump();

      expect(notApproved, isTrue);
      expect(refused, isFalse);
      expect(client.status, ConnectionStatus.disconnected);
    },
  );

  test('a join refused for a reason it does not know is retried', () async {
    bool refused = false;
    client.refused.listen((_) => refused = true);

    reply(await joinFrame(), 'error', <String, dynamic>{'reason': 'busy_node'});
    await pump();

    expect(refused, isFalse);
    expect(client.status, ConnectionStatus.reconnecting);
  });

  test('reply is correlated by ref', () async {
    final List<dynamic> join = await joinFrame();
    reply(join, 'ok', <String, dynamic>{'status': 'offline'});
    await pump();

    final Future<ChannelReply> replyFuture = client.setStatus('online');
    await pump();
    final List<dynamic> frame = lastFrame();
    expect(frame[3], 'status');
    reply(frame, 'ok', <String, dynamic>{'status': 'online'});

    final ChannelReply answered = await replyFuture;
    expect(answered.isOk, isTrue);
    expect(answered.response['status'], 'online');
  });

  test('a push before the join is answered is not sent', () async {
    await joinFrame();

    await expectLater(
      client.setStatus('online'),
      throwsA(isA<ChannelException>()),
    );
    expect(fake.sent, hasLength(1));
  });

  test('an unreadable frame is dropped, the socket stays up', () async {
    final List<dynamic> join = await joinFrame();
    reply(join, 'ok', <String, dynamic>{'status': 'offline'});
    await pump();

    fake.emit('not json');
    await pump();

    expect(client.status, ConnectionStatus.connected);
  });

  test(
    'positions kept offline go as one ping_batch with the ping fields',
    () async {
      final List<dynamic> join = await joinFrame();
      reply(join, 'ok', <String, dynamic>{'status': 'offline'});
      await pump();

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

      final List<dynamic> frame = lastFrame();
      expect(frame[3], 'ping_batch');
      expect(frame[4], <String, dynamic>{
        'pings': <Map<String, dynamic>>[
          <String, dynamic>{
            'latitude': -6.2,
            'longitude': 106.8,
            'recorded_at': '2026-10-21T08:00:00.000Z',
            'speed_kmh': 30.0,
          },
          <String, dynamic>{
            'latitude': -6.3,
            'longitude': 106.9,
            'recorded_at': '2026-10-21T08:00:04.000Z',
          },
        ],
      });
    },
  );
  test('a batch of another courier is never sent on this socket', () async {
    final List<dynamic> join = await joinFrame();
    reply(join, 'ok', <String, dynamic>{'status': 'offline'});
    await pump();

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
    expect(fake.sent, hasLength(1));
  });

  test(
    'a session whose driver the fleet has not named opens no socket and is not approved',
    () async {
      bool notApproved = false;
      int opened = 0;
      final ChannelClient sut = new ChannelClient.withConnector((
        Uri uri,
        Iterable<String> _,
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

    void replyOn(
      FakeSocket socket,
      List<dynamic> frame,
      Map<String, dynamic> response,
    ) {
      socket.emit(
        jsonEncode(<dynamic>[
          frame[0],
          frame[1],
          frame[2],
          'phx_reply',
          <String, dynamic>{'status': 'ok', 'response': response},
        ]),
      );
    }

    List<dynamic> lastOn(FakeSocket socket) =>
        jsonDecode(socket.sent.last) as List<dynamic>;

    void joined(FakeAsync async) {
      opened = <FakeSocket>[];
      sut = new ChannelClient.withConnector((Uri uri, Iterable<String> _) {
        final FakeSocket socket = new FakeSocket()..completeReady();

        opened.add(socket);

        return socket;
      });
      sut.connect(session, wsBase: 'wss://edge.test').ignore();
      async.flushMicrotasks();
      replyOn(opened.single, lastOn(opened.single), <String, dynamic>{
        'status': 'offline',
      });
      async.flushMicrotasks();
      expect(sut.status, ConnectionStatus.connected);
    }

    test('a heartbeat that is never answered reconnects', () {
      fakeAsync((FakeAsync async) {
        joined(async);

        async.elapse(const Duration(seconds: 30));
        expect(lastOn(opened.single)[3], 'heartbeat');

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
        replyOn(opened.single, lastOn(opened.single), <String, dynamic>{});
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
          expect(lastOn(opened.single)[3], 'heartbeat');

          async.elapse(const Duration(seconds: 11));

          expect(sut.status, isNot(ConnectionStatus.connected));
          sut.dispose().ignore();
          async.flushMicrotasks();
        });
      },
    );
  });
}

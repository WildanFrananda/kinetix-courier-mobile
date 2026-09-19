import 'dart:async';
import 'dart:convert';

import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_event.dart';
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

  test('joins driver topic and connects on ok reply', () async {
    final FakeSocket fake = FakeSocket()..completeReady();
    final ChannelClient client = ChannelClient.withConnector((_) => fake);

    unawaited(client.connect(session, wsBase: 'ws://x'));
    await pump();

    final List<dynamic> join = jsonDecode(fake.sent.single) as List<dynamic>;
    expect(join[2], 'driver:1');
    expect(join[3], 'phx_join');

    fake.emit(
      jsonEncode(<dynamic>[
        join[0],
        join[1],
        'driver:1',
        'phx_reply',
        <String, dynamic>{'status': 'ok', 'response': <String, dynamic>{}},
      ]),
    );
    await pump();

    expect(client.status, ConnectionStatus.connected);
  });

  test('forbidden join emits unauthorized, stays disconnected', () async {
    final FakeSocket fake = FakeSocket()..completeReady();
    final ChannelClient client = ChannelClient.withConnector((_) => fake);
    bool unauth = false;
    client.unauthorized.listen((_) => unauth = true);

    unawaited(client.connect(session, wsBase: 'ws://x'));
    await pump();
    final List<dynamic> join = jsonDecode(fake.sent.single) as List<dynamic>;
    fake.emit(
      jsonEncode(<dynamic>[
        join[0],
        join[1],
        'driver:1',
        'phx_reply',
        <String, dynamic>{
          'status': 'error',
          'response': <String, dynamic>{'reason': 'forbidden'},
        },
      ]),
    );
    await pump();

    expect(unauth, isTrue);
    expect(client.status, ConnectionStatus.disconnected);
  });

  test('reply is correlated by ref', () async {
    final FakeSocket fake = FakeSocket()..completeReady();
    final ChannelClient client = ChannelClient.withConnector((_) => fake);
    unawaited(client.connect(session, wsBase: 'ws://x'));
    await pump();
    final List<dynamic> join = jsonDecode(fake.sent.single) as List<dynamic>;
    fake.emit(
      jsonEncode(<dynamic>[
        join[0],
        join[1],
        'driver:1',
        'phx_reply',
        <String, dynamic>{'status': 'ok', 'response': <String, dynamic>{}},
      ]),
    );
    await pump();

    final Future<ChannelReply> replyFuture = client.setStatus('online');
    await pump();
    final List<dynamic> frame = jsonDecode(fake.sent.last) as List<dynamic>;
    expect(frame[3], 'status');
    fake.emit(
      jsonEncode(<dynamic>[
        join[0],
        frame[1],
        'driver:1',
        'phx_reply',
        <String, dynamic>{'status': 'ok', 'response': <String, dynamic>{}},
      ]),
    );
    final ChannelReply reply = await replyFuture;
    expect(reply.isOk, isTrue);
  });
}

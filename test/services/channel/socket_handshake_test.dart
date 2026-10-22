import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String token =
      'eyJhbGciOiJSUzI1NiIsImtpZCI6ImsxIn0.'
      'eyJzdWIiOiJwLTEiLCJyb2xlIjoiY291cmllciJ9.'
      'c2lnbmF0dXJlLW9mLXRoZS10b2tlbg';
  const DriverSession session = DriverSession(
    driverId: DriverId(7),
    token: token,
    refreshToken: 'refresh',
  );
  final RegExp httpToken = new RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$");

  final List<WebSocket> accepted = <WebSocket>[];
  HttpServer? server;
  ChannelClient? client;

  tearDown(() async {
    await client?.dispose();

    for (final WebSocket socket in accepted) {
      await socket.close();
    }

    accepted.clear();
    await server?.close(force: true);
    server = null;
    client = null;
  });

  Future<HttpServer> serve(
    Future<void> Function(HttpRequest request) handle,
  ) async {
    final HttpServer bound = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );

    bound.listen((HttpRequest request) => unawaited(handle(request)));
    server = bound;

    return bound;
  }

  Future<void> answer(HttpRequest request, int status) async {
    request.response
      ..statusCode = status
      ..contentLength = 0;
    await request.response.close();
  }

  String wsBase(HttpServer bound) => 'ws://127.0.0.1:${bound.port}';

  for (final int status in <int>[
    HttpStatus.forbidden,
    HttpStatus.unauthorized,
  ]) {
    test(
      'a $status at the upgrade is a refusal, not a reason to retry',
      () async {
        int upgrades = 0;
        final HttpServer bound = await serve((HttpRequest request) {
          upgrades++;

          return answer(request, status);
        });
        final ChannelClient sut = client = new ChannelClient();
        final Future<void> refused = sut.refused.first;

        await sut.connect(session, wsBase: wsBase(bound));
        await refused.timeout(const Duration(seconds: 5));

        expect(sut.status, ConnectionStatus.disconnected);
        expect(upgrades, 1);
      },
    );
  }

  test('a 503 at the upgrade is an outage: retried, never a refusal', () async {
    final HttpServer bound = await serve(
      (HttpRequest request) => answer(request, HttpStatus.serviceUnavailable),
    );
    final ChannelClient sut = client = new ChannelClient();
    bool refused = false;
    sut.refused.listen((_) => refused = true);

    await sut.connect(session, wsBase: wsBase(bound));

    expect(sut.status, ConnectionStatus.reconnecting);
    expect(refused, isFalse);
  });

  test('an address nothing listens on is retried, never a refusal', () async {
    final HttpServer bound = await serve(
      (HttpRequest request) => answer(request, HttpStatus.ok),
    );
    final int port = bound.port;
    await bound.close(force: true);
    server = null;
    final ChannelClient sut = client = new ChannelClient();
    bool refused = false;
    sut.refused.listen((_) => refused = true);

    await sut.connect(session, wsBase: 'ws://127.0.0.1:$port');

    expect(sut.status, ConnectionStatus.reconnecting);
    expect(refused, isFalse);
  });

  test(
    'the socket is the gateway route with the token in the protocol header, never in the URL',
    () async {
      Uri? requested;
      List<String> offered = <String>[];
      final HttpServer bound = await serve((HttpRequest request) async {
        requested = request.uri;
        offered = (request.headers['sec-websocket-protocol'] ?? <String>[])
            .expand((String value) => value.split(','))
            .map((String protocol) => protocol.trim())
            .toList();

        final WebSocket socket = await WebSocketTransformer.upgrade(
          request,
          protocolSelector: (List<String> protocols) => 'phoenix',
        );

        accepted.add(socket);
        socket.listen((Object? frame) {
          final List<dynamic> message =
              jsonDecode(frame! as String) as List<dynamic>;

          if (message[3] == 'phx_join') {
            socket.add(
              jsonEncode(<dynamic>[
                message[0],
                message[1],
                message[2],
                'phx_reply',
                <String, dynamic>{
                  'status': 'ok',
                  'response': <String, dynamic>{'status': 'offline'},
                },
              ]),
            );
          }
        });
      });
      final ChannelClient sut = client = new ChannelClient();

      await sut.connect(session, wsBase: wsBase(bound));

      expect(sut.status, ConnectionStatus.connected);
      expect(sut.joinStatus, 'offline');
      expect(requested!.path, '/ws/v1/matching/driver');
      expect(requested!.queryParameters, <String, String>{'vsn': '2.0.0'});
      expect(offered.first, 'phoenix');
      expect(offered, everyElement(matches(httpToken)));

      final String encoded = offered
          .singleWhere(
            (String protocol) => protocol.startsWith('base64url.bearer.phx.'),
          )
          .substring('base64url.bearer.phx.'.length);

      expect(encoded, matches(new RegExp(r'^[A-Za-z0-9+/]+$')));
      expect(utf8.decode(base64.decode(base64.normalize(encoded))), token);
    },
  );
}

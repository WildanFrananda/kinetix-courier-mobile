import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/duty_repository_impl.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_socket.dart';
import 'package:fleet_pulse_mobile/services/location/location_service.dart';
import 'package:fleet_pulse_mobile/services/offline/offline_position_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocation extends Mock implements LocationService {}

class _MatchingSocket implements ChannelSocket {
  _MatchingSocket({required this.reachable});

  final bool reachable;
  final StreamController<dynamic> _in = new StreamController<dynamic>();
  final List<List<dynamic>> frames = <List<dynamic>>[];

  void drop() => unawaited(_in.close());

  List<String> batchedTimesOn(String topic) => <String>[
    for (final List<dynamic> frame in frames)
      if (frame[2] == topic && frame[3] == 'ping_batch')
        for (final Object? ping
            in (frame[4] as Map<String, dynamic>)['pings'] as List<dynamic>)
          (ping! as Map<String, dynamic>)['recorded_at'] as String,
  ];

  @override
  Stream<dynamic> get stream => _in.stream;

  @override
  Future<void> get ready => reachable
      ? Future<void>.value()
      : Future<void>.error(const SocketException('no route to the edge'));

  @override
  void add(String data) {
    final List<dynamic> frame = jsonDecode(data) as List<dynamic>;

    frames.add(frame);
    _in.add(
      jsonEncode(<dynamic>[
        frame[0],
        frame[1],
        frame[2],
        'phx_reply',
        <String, dynamic>{'status': 'ok', 'response': _answerTo(frame)},
      ]),
    );
  }

  Map<String, dynamic> _answerTo(List<dynamic> frame) {
    final Map<String, dynamic> payload = frame[4] as Map<String, dynamic>;

    return switch (frame[3]) {
      'phx_join' => <String, dynamic>{'status': 'offline'},
      'status' => <String, dynamic>{'status': payload['status']},
      'ping_batch' => <String, dynamic>{
        'stored': <int>[
          for (int i = 0; i < (payload['pings'] as List<dynamic>).length; i++)
            i,
        ],
        'duplicates': <int>[],
        'refused': <Map<String, dynamic>>[],
      },
      _ => <String, dynamic>{},
    };
  }

  @override
  Future<void> close() async {
    if (!_in.isClosed) {
      await _in.close();
    }
  }
}

Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 200));

void main() {
  const DriverSession courierA = DriverSession(
    driverId: DriverId(1),
    token: 'token-a',
    refreshToken: 'refresh-a',
  );
  const DriverSession courierB = DriverSession(
    driverId: DriverId(2),
    token: 'token-b',
    refreshToken: 'refresh-b',
  );

  late Directory directory;
  late _MockLocation location;
  late StreamController<Position> positions;
  late List<_MatchingSocket> sockets;
  late bool edgeReachable;
  late ChannelClient channel;
  late OfflinePositionStore store;
  late DutyRepositoryImpl duty;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('shared_phone');
    Hive.init(directory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  setUp(() {
    location = new _MockLocation();
    positions = new StreamController<Position>.broadcast();
    sockets = <_MatchingSocket>[];
    edgeReachable = true;

    when(
      () => location.ensurePermission(background: any(named: 'background')),
    ).thenAnswer((_) async => LocationPermissionStatus.granted);
    when(
      () => location.requestNotificationPermission(),
    ).thenAnswer((_) async {});
    when(() => location.positions()).thenAnswer((_) => positions.stream);

    channel = new ChannelClient.withConnector((Uri _, Iterable<String> _) {
      final _MatchingSocket socket = new _MatchingSocket(
        reachable: edgeReachable,
      );

      sockets.add(socket);

      return socket;
    });
    store = new OfflinePositionStore.withOpener(
      () => Hive.openLazyBox<Map<dynamic, dynamic>>('offline_positions'),
    );
    duty = new DutyRepositoryImpl(location, channel, store);
  });

  tearDown(() async {
    await duty.dispose();
    await channel.dispose();
    await positions.close();
    await Hive.deleteBoxFromDisk('offline_positions');
  });

  test(
    'positions courier A could not send never go out as courier B history on the same phone',
    () async {
      final DateTime fixTime = DateTime.now().toUtc().subtract(
        const Duration(minutes: 1),
      );

      await channel.connect(courierA, wsBase: 'wss://edge.test');
      expect(channel.status, ConnectionStatus.connected);

      edgeReachable = false;
      sockets.last.drop();
      await settle();
      expect(channel.status, isNot(ConnectionStatus.connected));

      await duty.goOnDuty();
      positions.add(
        new Position(
          latitude: -6.2,
          longitude: 106.8,
          timestamp: fixTime,
          accuracy: 1,
          altitude: 0,
          altitudeAccuracy: 1,
          heading: 90,
          headingAccuracy: 1,
          speed: 10,
          speedAccuracy: 1,
        ),
      );
      await Future<void>.delayed(
        DutyRepositoryImpl.cadence + const Duration(milliseconds: 500),
      );
      expect(await store.count(), 1);

      await duty.goOffDuty();
      await channel.disconnect();

      edgeReachable = true;
      await channel.connect(courierB, wsBase: 'wss://edge.test');
      await settle();

      expect(channel.status, ConnectionStatus.connected);
      expect(
        sockets.last.batchedTimesOn('driver:2'),
        isNot(contains(fixTime.toIso8601String())),
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
  test(
    'courier A positions still go out as A history when A signs back in',
    () async {
      final DateTime fixTime = DateTime.now().toUtc().subtract(
        const Duration(minutes: 1),
      );

      await channel.connect(courierA, wsBase: 'wss://edge.test');
      edgeReachable = false;
      sockets.last.drop();
      await settle();
      await duty.goOnDuty();
      positions.add(
        new Position(
          latitude: -6.2,
          longitude: 106.8,
          timestamp: fixTime,
          accuracy: 1,
          altitude: 0,
          altitudeAccuracy: 1,
          heading: 90,
          headingAccuracy: 1,
          speed: 10,
          speedAccuracy: 1,
        ),
      );
      await Future<void>.delayed(
        DutyRepositoryImpl.cadence + const Duration(milliseconds: 500),
      );
      await duty.goOffDuty();
      await channel.disconnect();

      edgeReachable = true;
      await channel.connect(courierB, wsBase: 'wss://edge.test');
      await settle();
      await channel.disconnect();
      await channel.connect(courierA, wsBase: 'wss://edge.test');
      await settle();

      expect(sockets.last.batchedTimesOn('driver:1'), <String>[
        fixTime.toIso8601String(),
      ]);
      expect(await store.count(), 0);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

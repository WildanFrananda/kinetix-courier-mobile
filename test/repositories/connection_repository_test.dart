import 'dart:async';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/connection_repository_impl.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChannel extends Mock implements ChannelClient {}

void main() {
  late _MockChannel channel;
  late ConnectionRepositoryImpl sut;

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
      const DriverSession(driverId: DriverId(0), token: '', refreshToken: 'refresh-token'),
    );
  });

  setUp(() {
    channel = new _MockChannel();
    sut = new ConnectionRepositoryImpl(channel);
  });

  test('sendPing ok maps to Ok', () async {
    when(
      () => channel.ping(any()),
    ).thenAnswer((_) async => const ChannelReply('ok', <String, dynamic>{}));
    expect(await sut.sendPing(ping), isA<Ok<Unit>>());
  });

  test('sendPing error reason maps to ChannelFailure', () async {
    when(() => channel.ping(any())).thenAnswer(
      (_) async => const ChannelReply('error', <String, dynamic>{
        'reason': 'invalid_telemetry',
      }),
    );
    final res = await sut.sendPing(ping);
    expect((res as Err<Unit>).failure, isA<ChannelFailure>());
  });

  test('sendPing ChannelException maps to NetworkFailure', () async {
    when(() => channel.ping(any())).thenThrow(const ChannelException('x'));
    final res = await sut.sendPing(ping);
    expect((res as Err<Unit>).failure, isA<NetworkFailure>());
  });

  test('setStatus ok maps to Ok', () async {
    when(
      () => channel.setStatus(any()),
    ).thenAnswer((_) async => const ChannelReply('ok', <String, dynamic>{}));
    expect(await sut.setStatus('online'), isA<Ok<Unit>>());
  });

  test('statusStream passes through the channel', () async {
    final StreamController<ConnectionStatus> statusCtrl =
        StreamController<ConnectionStatus>.broadcast();
    when(() => channel.statusStream).thenAnswer((_) => statusCtrl.stream);

    final Future<ConnectionStatus> first = sut.statusStream.first;
    statusCtrl.add(ConnectionStatus.connected);
    expect(await first, ConnectionStatus.connected);

    await statusCtrl.close();
  });

  test('sessionExpired passes through the channel', () async {
    final StreamController<void> authCtrl = StreamController<void>.broadcast();
    when(() => channel.unauthorized).thenAnswer((_) => authCtrl.stream);

    final Future<void> done = sut.sessionExpired.first;
    authCtrl.add(null);
    await expectLater(done, completes);

    await authCtrl.close();
  });

  test('onResume triggers reconnectNow', () {
    sut.onResume();
    verify(() => channel.reconnectNow()).called(1);
  });

  test('connect delegates to the channel with a wsBase', () async {
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

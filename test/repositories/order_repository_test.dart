import 'dart:async';
import 'dart:io';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository_impl.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_event.dart';
import 'package:fleet_pulse_mobile/services/storage/pod_photo_uploader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChannel extends Mock implements ChannelClient {}

class _MockUploader extends Mock implements PodPhotoUploader {}

void main() {
  late _MockChannel channel;
  late _MockUploader uploader;
  late StreamController<ChannelEvent> events;
  late OrderRepositoryImpl sut;

  Map<String, dynamic> orderJson(int id, String status) => <String, dynamic>{
    'id': id,
    'status': status,
    'weight_kg': 10,
    'pickup': <String, dynamic>{'latitude': 1.0, 'longitude': 2.0},
    'dropoff': <String, dynamic>{'latitude': 3.0, 'longitude': 4.0},
    'assigned_at': '2026-01-01T00:00:00Z',
  };

  setUp(() {
    channel = new _MockChannel();
    uploader = new _MockUploader();
    events = StreamController<ChannelEvent>.broadcast();
    when(() => channel.events).thenAnswer((_) => events.stream);
    sut = new OrderRepositoryImpl(channel, uploader);
  });

  tearDown(() => events.close());

  test('maps order_assigned to Order', () async {
    final Future<Order?> future = sut.watchActiveOrder().first;
    await Future<void>.delayed(Duration.zero);
    events.add(new ChannelEvent('order_assigned', orderJson(1, 'assigned')));
    final Order? order = await future;
    expect(order!.id.value, 1);
    expect(order.status, OrderStatus.assigned);
  });

  test('active_order null yields null', () async {
    final Future<Order?> future = sut.watchActiveOrder().first;
    await Future<void>.delayed(Duration.zero);
    events.add(
      const ChannelEvent('active_order', <String, dynamic>{'order': null}),
    );
    expect(await future, isNull);
  });

  test('order_updated cancelled yields null', () async {
    final Future<Order?> future = sut.watchActiveOrder().first;
    await Future<void>.delayed(Duration.zero);
    events.add(new ChannelEvent('order_updated', orderJson(2, 'cancelled')));
    expect(await future, isNull);
  });

  test('pickup ok returns Ok', () async {
    when(
      () => channel.pickup(any()),
    ).thenAnswer((_) async => const ChannelReply('ok', <String, dynamic>{}));
    final res = await sut.pickup(const OrderId(1));
    expect(res, isA<Ok<Unit>>());
    verify(() => channel.pickup(1)).called(1);
  });

  test('pickup terminal error returns Err without retry', () async {
    when(() => channel.pickup(any())).thenAnswer(
      (_) async => const ChannelReply('error', <String, dynamic>{
        'reason': 'invalid_transition',
      }),
    );
    final res = await sut.pickup(const OrderId(1));
    expect(res, isA<Err<Unit>>());
    verify(() => channel.pickup(1)).called(1);
  });

  test('delivered ok passes POD photo and signature to channel', () async {
    when(
      () => channel.delivered(
        any(),
        podPhotoUrl: any(named: 'podPhotoUrl'),
        podSignature: any(named: 'podSignature'),
      ),
    ).thenAnswer((_) async => const ChannelReply('ok', <String, dynamic>{}));

    final res = await sut.delivered(
      const OrderId(1),
      podPhotoUrl: 'photo.jpg',
      podSignature: 'sig.svg',
    );
    expect(res, isA<Ok<Unit>>());
    verify(
      () => channel.delivered(
        1,
        podPhotoUrl: 'photo.jpg',
        podSignature: 'sig.svg',
      ),
    ).called(1);
  });

  test(
    'attachPodPhoto uploads to the address matching issued and answers its photo url',
    () async {
      when(() => channel.podUpload(any())).thenAnswer(
        (_) async => const ChannelReply('ok', <String, dynamic>{
          'upload_url':
              'https://storage.test/kinetix-pod/pod/1/a.jpg?X-Amz-Signature=s',
          'photo_url': 'https://storage.test/kinetix-pod/pod/1/a.jpg',
        }),
      );
      when(() => uploader.upload(any(), any())).thenAnswer((_) async {});

      final Result<String> res = await sut.attachPodPhoto(
        const OrderId(1),
        '/tmp/photo.jpg',
      );

      expect(res, isA<Ok<String>>());
      expect(
        (res as Ok<String>).value,
        'https://storage.test/kinetix-pod/pod/1/a.jpg',
      );
      verify(
        () => uploader.upload(
          'https://storage.test/kinetix-pod/pod/1/a.jpg?X-Amz-Signature=s',
          '/tmp/photo.jpg',
        ),
      ).called(1);
    },
  );

  test('attachPodPhoto refused by matching uploads nothing', () async {
    when(() => channel.podUpload(any())).thenAnswer(
      (_) async => const ChannelReply('error', <String, dynamic>{
        'reason': 'invalid_transition',
      }),
    );

    final Result<String> res = await sut.attachPodPhoto(
      const OrderId(1),
      '/tmp/photo.jpg',
    );

    expect(res, isA<Err<String>>());
    verifyNever(() => uploader.upload(any(), any()));
  });

  test('attachPodPhoto whose upload fails is a photo failure', () async {
    when(() => channel.podUpload(any())).thenAnswer(
      (_) async => const ChannelReply('ok', <String, dynamic>{
        'upload_url': 'https://storage.test/u',
        'photo_url': 'https://storage.test/p',
      }),
    );
    when(
      () => uploader.upload(any(), any()),
    ).thenThrow(const FileSystemException('gone'));

    final Result<String> res = await sut.attachPodPhoto(
      const OrderId(1),
      '/tmp/photo.jpg',
    );

    expect((res as Err<String>).failure, isA<PodPhotoFailure>());
  });
}

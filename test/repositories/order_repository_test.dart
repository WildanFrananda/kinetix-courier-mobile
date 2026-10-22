import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
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

  setUpAll(() {
    registerFallbackValue(new Uint8List(0));
    registerFallbackValue(<String, String>{});
  });

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

  final Uint8List photo = new Uint8List.fromList(<int>[
    0xFF,
    0xD8,
    0xFF,
    ...utf8.encode('abc'),
  ]);
  final String photoSha256 = sha256.convert(photo).toString();

  test(
    "attachPodPhoto asks for an address bound to the photo's SHA-256 and puts the bytes with the headers matching signed",
    () async {
      when(() => uploader.read(any())).thenAnswer((_) async => photo);
      when(() => channel.podUpload(any(), any())).thenAnswer(
        (_) async => new ChannelReply('ok', <String, dynamic>{
          'upload_url':
              'https://storage.test/kinetix-pod/pod/1/$photoSha256.jpg?X-Amz-Signature=s',
          'upload_headers': <String, dynamic>{
            'if-none-match': '*',
            'x-amz-checksum-sha256':
                'ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=',
          },
          'photo_url':
              'https://storage.test/kinetix-pod/pod/1/$photoSha256.jpg',
        }),
      );
      when(() => uploader.upload(any(), any(), any())).thenAnswer((_) async {});

      final Result<String> res = await sut.attachPodPhoto(
        const OrderId(1),
        '/tmp/photo.jpg',
      );

      expect(res, isA<Ok<String>>());
      expect(
        (res as Ok<String>).value,
        'https://storage.test/kinetix-pod/pod/1/$photoSha256.jpg',
      );
      verify(() => uploader.read('/tmp/photo.jpg')).called(1);
      verify(() => channel.podUpload(1, photoSha256)).called(1);
      verify(
        () => uploader.upload(
          'https://storage.test/kinetix-pod/pod/1/$photoSha256.jpg?X-Amz-Signature=s',
          photo,
          <String, String>{
            'if-none-match': '*',
            'x-amz-checksum-sha256':
                'ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=',
          },
        ),
      ).called(1);
    },
  );

  test(
    'attachPodPhoto against a matching that signs no headers puts the bytes with none',
    () async {
      when(() => uploader.read(any())).thenAnswer((_) async => photo);
      when(() => channel.podUpload(any(), any())).thenAnswer(
        (_) async => const ChannelReply('ok', <String, dynamic>{
          'upload_url': 'https://storage.test/u',
          'photo_url': 'https://storage.test/p',
        }),
      );
      when(() => uploader.upload(any(), any(), any())).thenAnswer((_) async {});

      final Result<String> res = await sut.attachPodPhoto(
        const OrderId(1),
        '/tmp/photo.jpg',
      );

      expect(res, isA<Ok<String>>());
      verify(
        () => uploader.upload(
          'https://storage.test/u',
          photo,
          const <String, String>{},
        ),
      ).called(1);
    },
  );

  test('attachPodPhoto refused by matching uploads nothing', () async {
    when(() => uploader.read(any())).thenAnswer((_) async => photo);
    when(() => channel.podUpload(any(), any())).thenAnswer(
      (_) async => const ChannelReply('error', <String, dynamic>{
        'reason': 'invalid_transition',
      }),
    );

    final Result<String> res = await sut.attachPodPhoto(
      const OrderId(1),
      '/tmp/photo.jpg',
    );

    expect(res, isA<Err<String>>());
    verifyNever(() => uploader.upload(any(), any(), any()));
  });

  test(
    'attachPodPhoto whose photo cannot be read asks matching for nothing',
    () async {
      when(
        () => uploader.read(any()),
      ).thenThrow(const FileSystemException('gone'));

      final Result<String> res = await sut.attachPodPhoto(
        const OrderId(1),
        '/tmp/photo.jpg',
      );

      expect((res as Err<String>).failure, isA<PodPhotoFailure>());
      verifyNever(() => channel.podUpload(any(), any()));
    },
  );

  test('attachPodPhoto whose upload fails is a photo failure', () async {
    when(() => uploader.read(any())).thenAnswer((_) async => photo);
    when(() => channel.podUpload(any(), any())).thenAnswer(
      (_) async => const ChannelReply('ok', <String, dynamic>{
        'upload_url': 'https://storage.test/u',
        'photo_url': 'https://storage.test/p',
      }),
    );
    when(
      () => uploader.upload(any(), any(), any()),
    ).thenThrow(new DioException(requestOptions: new RequestOptions()));

    final Result<String> res = await sut.attachPodPhoto(
      const OrderId(1),
      '/tmp/photo.jpg',
    );

    expect((res as Err<String>).failure, isA<PodPhotoFailure>());
  });

  test(
    'a photo that is not a JPEG is refused before matching is asked',
    () async {
      when(
        () => uploader.read(any()),
      ).thenAnswer((_) async => new Uint8List.fromList(utf8.encode('PNG..')));

      final Result<String> res = await sut.attachPodPhoto(
        const OrderId(1),
        '/tmp/photo.png',
      );

      expect((res as Err<String>).failure, isA<PodPhotoFailure>());
      verifyNever(() => channel.podUpload(any(), any()));
    },
  );

  test('a job taken off the courier clears it and names it', () async {
    final Future<Order?> active = sut.watchActiveOrder().first;
    final Future<OrderId> unassigned = sut.watchUnassigned().first;
    await Future<void>.delayed(Duration.zero);

    events.add(
      const ChannelEvent('order_unassigned', <String, dynamic>{'id': 3}),
    );

    expect(await active, isNull);
    expect(await unassigned, const OrderId(3));
  });

  test('a pending job is never read as an order', () async {
    final List<Order?> seen = <Order?>[];
    final StreamSubscription<Order?> sub = sut.watchActiveOrder().listen(
      seen.add,
    );
    await Future<void>.delayed(Duration.zero);
    final Map<String, dynamic> pending = orderJson(4, 'pending')
      ..['assigned_at'] = null;

    events
      ..add(new ChannelEvent('order_assigned', pending))
      ..add(new ChannelEvent('order_updated', pending))
      ..add(
        new ChannelEvent('active_order', <String, dynamic>{'order': pending}),
      )
      ..add(new ChannelEvent('order_assigned', orderJson(5, 'assigned')));
    await Future<void>.delayed(Duration.zero);
    unawaited(sub.cancel());

    expect(seen, hasLength(3));
    expect(seen[0], isNull);
    expect(seen[1], isNull);
    expect(seen[2]!.id, const OrderId(5));
  });

  test('a job this app cannot read does not end the stream', () async {
    final List<Order?> seen = <Order?>[];
    final StreamSubscription<Order?> sub = sut.watchActiveOrder().listen(
      seen.add,
    );
    await Future<void>.delayed(Duration.zero);

    events
      ..add(
        const ChannelEvent('order_assigned', <String, dynamic>{
          'id': 'seven',
          'assigned_at': '2026-01-01T00:00:00Z',
        }),
      )
      ..add(new ChannelEvent('order_assigned', orderJson(5, 'assigned')));
    await Future<void>.delayed(Duration.zero);
    unawaited(sub.cancel());

    expect(seen.single!.id, const OrderId(5));
  });

  test('a pickup whose reply was lost is retried, and its ok is success', () {
    fakeAsync((FakeAsync async) {
      int calls = 0;
      when(() => channel.pickup(any())).thenAnswer((_) async {
        calls++;

        if (calls == 1) {
          throw const ChannelException('push "pickup" timed out');
        }

        return const ChannelReply('ok', <String, dynamic>{});
      });
      Result<Unit>? res;

      sut.pickup(const OrderId(1)).then((Result<Unit> r) => res = r).ignore();
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 1));

      expect(res, isA<Ok<Unit>>());
      expect(calls, 2);
    });
  });

  test('a delivery whose reply was lost is retried, and its ok is success', () {
    fakeAsync((FakeAsync async) {
      int calls = 0;
      when(
        () => channel.delivered(
          any(),
          podPhotoUrl: any(named: 'podPhotoUrl'),
          podSignature: any(named: 'podSignature'),
        ),
      ).thenAnswer((_) async {
        calls++;

        if (calls == 1) {
          throw const ChannelException('push "delivered" timed out');
        }

        return const ChannelReply('ok', <String, dynamic>{});
      });
      Result<Unit>? res;

      sut
          .delivered(
            const OrderId(1),
            podPhotoUrl: 'https://storage.test/p.jpg',
            podSignature: 'data:image/png;base64,AAAA',
          )
          .then((Result<Unit> r) => res = r)
          .ignore();
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 1));

      expect(res, isA<Ok<Unit>>());
      expect(calls, 2);
    });
  });

  test('a delivery whose proof could not be checked yet is retried', () {
    fakeAsync((FakeAsync async) {
      int calls = 0;
      when(
        () => channel.delivered(
          any(),
          podPhotoUrl: any(named: 'podPhotoUrl'),
          podSignature: any(named: 'podSignature'),
        ),
      ).thenAnswer((_) async {
        calls++;

        return calls == 1
            ? const ChannelReply('error', <String, dynamic>{
                'reason': 'proof_unverifiable',
              })
            : const ChannelReply('ok', <String, dynamic>{});
      });
      Result<Unit>? res;

      sut
          .delivered(
            const OrderId(1),
            podPhotoUrl: 'https://storage.test/p.jpg',
            podSignature: 'data:image/png;base64,AAAA',
          )
          .then((Result<Unit> r) => res = r)
          .ignore();
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 1));

      expect(res, isA<Ok<Unit>>());
    });
  });

  test('a delivery refused for a missing signature is not retried', () async {
    when(
      () => channel.delivered(
        any(),
        podPhotoUrl: any(named: 'podPhotoUrl'),
        podSignature: any(named: 'podSignature'),
      ),
    ).thenAnswer(
      (_) async => const ChannelReply('error', <String, dynamic>{
        'reason': 'signature_required',
      }),
    );

    final Result<Unit> res = await sut.delivered(
      const OrderId(1),
      podPhotoUrl: 'https://storage.test/p.jpg',
      podSignature: '',
    );

    final Failure failure = (res as Err<Unit>).failure;
    expect(failure.message, contains('signature'));
    verify(
      () => channel.delivered(
        any(),
        podPhotoUrl: any(named: 'podPhotoUrl'),
        podSignature: any(named: 'podSignature'),
      ),
    ).called(1);
  });
}

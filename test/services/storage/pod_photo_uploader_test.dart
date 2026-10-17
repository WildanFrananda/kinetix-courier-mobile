import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/services/storage/pod_photo_uploader.dart';
import 'package:flutter_test/flutter_test.dart';

class _Bucket implements HttpClientAdapter {
  _Bucket(this._status);

  final int _status;
  final List<int> body = <int>[];
  RequestOptions? received;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received = options;

    if (requestStream != null) {
      await for (final Uint8List chunk in requestStream) {
        body.addAll(chunk);
      }
    }

    return ResponseBody.fromString('', _status);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final Uint8List photo = new Uint8List.fromList(utf8.encode('abc'));
  const Map<String, String> signed = <String, String>{
    'if-none-match': '*',
    'x-amz-checksum-sha256': 'ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=',
  };

  PodPhotoUploader uploaderAnswering(_Bucket bucket) {
    final Dio dio = new Dio()..httpClientAdapter = bucket;

    return new PodPhotoUploader(dio);
  }

  test(
    'puts the photo with every header matching signed, its type and its length',
    () async {
      final _Bucket bucket = new _Bucket(200);

      await uploaderAnswering(bucket).upload(
        'https://storage.test/pod/1/a.jpg?X-Amz-Signature=s',
        photo,
        signed,
      );

      expect(bucket.received!.method, 'PUT');
      expect(bucket.received!.headers['if-none-match'], '*');
      expect(
        bucket.received!.headers['x-amz-checksum-sha256'],
        'ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=',
      );
      expect(bucket.received!.headers[Headers.contentTypeHeader], 'image/jpeg');
      expect(bucket.received!.headers[Headers.contentLengthHeader], 3);
      expect(bucket.body, photo);
    },
  );

  test(
    'a photo already stored under its own hash counts as uploaded',
    () async {
      final _Bucket bucket = new _Bucket(HttpStatus.preconditionFailed);

      await expectLater(
        uploaderAnswering(
          bucket,
        ).upload('https://storage.test/u', photo, signed),
        completes,
      );
    },
  );

  test('a refused upload is a failure', () async {
    final _Bucket bucket = new _Bucket(HttpStatus.forbidden);

    await expectLater(
      uploaderAnswering(bucket).upload('https://storage.test/u', photo, signed),
      throwsA(isA<DioException>()),
    );
  });

  test('reads the photo the camera wrote', () async {
    final Directory dir = await Directory.systemTemp.createTemp('pod-photo');
    addTearDown(() => dir.delete(recursive: true));
    final File file = new File('${dir.path}/photo.jpg');
    await file.writeAsBytes(photo);

    expect(await uploaderAnswering(new _Bucket(200)).read(file.path), photo);
  });
}

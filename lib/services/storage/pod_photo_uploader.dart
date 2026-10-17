import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PodPhotoUploader {
  PodPhotoUploader(@Named('storage') this._dio);

  static const int _alreadyStored = HttpStatus.preconditionFailed;

  final Dio _dio;

  Future<Uint8List> read(String localPath) => new File(localPath).readAsBytes();

  Future<void> upload(
    String uploadUrl,
    Uint8List bytes,
    Map<String, String> signedHeaders,
  ) async {
    await _dio.put<void>(
      uploadUrl,
      data: new Stream<List<int>>.value(bytes),
      options: new Options(
        headers: <String, Object>{
          ...signedHeaders,
          Headers.contentTypeHeader: 'image/jpeg',
          Headers.contentLengthHeader: bytes.length,
        },
        validateStatus: _stored,
      ),
    );
  }

  static bool _stored(int? status) =>
      status != null &&
      ((status >= 200 && status < 300) || status == _alreadyStored);
}

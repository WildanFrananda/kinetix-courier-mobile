import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PodPhotoUploader {
  PodPhotoUploader(@Named('storage') this._dio);

  final Dio _dio;

  Future<void> upload(String uploadUrl, String localPath) async {
    final Uint8List bytes = await new File(localPath).readAsBytes();

    await _dio.put<void>(
      uploadUrl,
      data: new Stream<List<int>>.value(bytes),
      options: new Options(
        headers: <String, Object>{
          Headers.contentTypeHeader: 'image/jpeg',
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );
  }
}

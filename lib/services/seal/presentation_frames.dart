import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

abstract final class PresentationFrames {
  static const int frameCharacters = 600;

  static String encoded(String transactionHex) {
    return base64Url.encode(_bytes(transactionHex)).replaceAll('=', '');
  }

  static List<String> of(String transactionHex) {
    final Uint8List bytes = _bytes(transactionHex);
    final String encoded = base64Url.encode(bytes).replaceAll('=', '');
    final String tag = sha256.convert(bytes).toString().substring(0, 8);
    final int total = (encoded.length / frameCharacters).ceil();

    return List<String>.generate(total, (int index) {
      final int start = index * frameCharacters;
      final int end = start + frameCharacters < encoded.length
          ? start + frameCharacters
          : encoded.length;

      return 'KSP1:$tag:${index + 1}/$total:${encoded.substring(start, end)}';
    });
  }

  static Uri link(Uri answerUrl, String transactionHex) {
    return answerUrl.replace(fragment: encoded(transactionHex));
  }

  static Uint8List _bytes(String hex) {
    final Uint8List bytes = new Uint8List(hex.length ~/ 2);

    for (int index = 0; index < bytes.length; index += 1) {
      bytes[index] = int.parse(
        hex.substring(index * 2, index * 2 + 2),
        radix: 16,
      );
    }

    return bytes;
  }
}

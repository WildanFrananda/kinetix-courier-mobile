import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_courier/services/seal/presentation_frames.dart';

void main() {
  final String transaction = List<String>.generate(
    3604,
    (int index) => (index % 256).toRadixString(16).padLeft(2, '0'),
  ).join();

  test('splits a presentation into tagged frames that rebuild it exactly', () {
    final List<String> frames = PresentationFrames.of(transaction);
    final String tag = frames.first.split(':')[1];
    final String joined = frames
        .map((String frame) => frame.split(':')[3])
        .join();
    final List<int> bytes = base64Url.decode(base64Url.normalize(joined));

    expect(frames, hasLength(9));
    expect(
      frames.every((String frame) => frame.startsWith('KSP1:$tag:')),
      isTrue,
    );
    expect(frames.last.split(':')[2], '9/9');
    expect(bytes, hasLength(3604));
    expect(bytes.take(3), <int>[0, 1, 2]);
  });

  test(
    'puts the challenge and the presentation in the link fragment, which no browser sends to a server',
    () {
      final Uri link = PresentationFrames.link(
        Uri.parse('https://verify.example/seal/answer'),
        'c0' * 32,
        '0a0b0c',
      );

      expect(
        link.toString(),
        'https://verify.example/seal/answer#${'c0' * 32}.CgsM',
      );
      expect(link.query, isEmpty);
    },
  );
}

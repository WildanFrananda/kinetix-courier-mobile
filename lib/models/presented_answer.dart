import 'package:freezed_annotation/freezed_annotation.dart';

part 'presented_answer.freezed.dart';

@freezed
abstract class PresentedAnswer with _$PresentedAnswer {
  const factory PresentedAnswer({
    required List<String> frames,
    required Uri link,
  }) = _PresentedAnswer;
}

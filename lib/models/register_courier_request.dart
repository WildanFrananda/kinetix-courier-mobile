import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_courier_request.freezed.dart';
part 'register_courier_request.g.dart';

@freezed
abstract class RegisterCourierRequest with _$RegisterCourierRequest {
  const factory RegisterCourierRequest({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String vehiclePlate,
    required int capacityKg,
  }) = _RegisterCourierRequest;

  factory RegisterCourierRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterCourierRequestFromJson(json);
}

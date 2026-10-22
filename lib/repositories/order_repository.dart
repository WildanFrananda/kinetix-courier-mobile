import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';

abstract interface class OrderRepository {
  Stream<Order?> watchActiveOrder();
  Stream<OrderId> watchUnassigned();
  Future<Result<Unit>> pickup(OrderId orderId);
  Future<Result<String>> attachPodPhoto(OrderId orderId, String localPath);
  Future<Result<Unit>> delivered(
    OrderId orderId, {
    required String podPhotoUrl,
    required String podSignature,
  });
}

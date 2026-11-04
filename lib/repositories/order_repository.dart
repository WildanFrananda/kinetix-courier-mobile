import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/state/job_update.dart';

abstract interface class OrderRepository {
  Stream<JobUpdate> watchJobs();
  Future<Result<Unit>> pickup(OrderId orderId);
  Future<Result<String>> attachPodPhoto(OrderId orderId, String localPath);
  Future<DeliveryProofDraft> proofDraft(OrderId orderId);
  Future<void> keepSignature(OrderId orderId, String podSignature);
  Future<void> discardProofDraft(OrderId orderId);
  Future<Result<Unit>> delivered(
    OrderId orderId, {
    required String podPhotoUrl,
    required String podSignature,
  });
}

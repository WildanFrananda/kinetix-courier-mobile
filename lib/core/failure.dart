sealed class Failure {
  const Failure();

  String get message;
}

class NetworkFailure extends Failure {
  const NetworkFailure();

  @override
  String get message => 'network unavailable';
}

class AuthFailure extends Failure {
  const AuthFailure([this.message = 'session expired']);

  @override
  final String message;
}

class ChannelFailure extends Failure {
  const ChannelFailure(this.reason);

  static const Map<String, String> _explanations = <String, String>{
    'forbidden': 'That job belongs to another courier.',
    'invalid_order_id': 'The job number was not accepted.',
    'invalid_photo_hash': 'The photo could not be prepared; take it again.',
    'invalid_proof': 'The photo could not be verified; take it again.',
    'invalid_status': 'That availability is not accepted.',
    'invalid_telemetry':
        "Your position was refused. Check that the phone's date and time are "
        'set automatically.',
    'invalid_transition': 'This job cannot move to that step now.',
    'no_active_job': 'You can only be busy while carrying a job.',
    'not_found': 'That job no longer exists.',
    'pending_approval': 'Your account is waiting for approval.',
    'proof_unverifiable':
        'The photo could not be checked just now. Try again in a moment.',
    'rate_limited': 'Too many updates were sent; slowing down.',
    'signature_required': "The receiver's signature is required.",
    'unlinked': 'This account is not linked to a courier in the fleet.',
  };

  final String reason;

  @override
  String get message => _explanations[reason] ?? reason;
}

class TimeoutFailure extends Failure {
  const TimeoutFailure();

  @override
  String get message => 'request timed out';
}

class PermissionFailure extends Failure {
  const PermissionFailure([this.message = 'location permission denied']);

  @override
  final String message;
}

class PodPhotoFailure extends Failure {
  const PodPhotoFailure([this.message = 'the photo could not be uploaded']);

  @override
  final String message;
}

class PendingApprovalFailure extends Failure {
  const PendingApprovalFailure();

  @override
  String get message => 'account pending approval';
}

class RegistrationIncompleteFailure extends Failure {
  const RegistrationIncompleteFailure();

  @override
  String get message => 'vehicle registration was never completed';
}

class RefusedFailure extends Failure {
  const RefusedFailure(this.message);

  @override
  final String message;
}

class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure(this.message);

  @override
  final String message;
}

Failure failureFromReason(String? reason) =>
    new ChannelFailure(reason ?? 'unknown');
